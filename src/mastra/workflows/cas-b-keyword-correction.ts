/**
 * Cas B Keyword Correction Workflow — Deterministic HITL pipeline
 *
 * Replaces the LLM-based Cas B detection (which was unreliable) with a
 * deterministic 3-step workflow:
 *
 * 1. fetchAOAndKeyword  — load AO data + keyword lexicon lookup
 * 2. waitForDirection   — suspend → frontend shows KeywordDirectionCard → resume with user's choice
 * 3. applyKeywordCorrection — run executeCorrection with forced correction_type
 *
 * This workflow is started by /api/chat/route.ts when a Cas B intent is detected
 * by regex (not LLM). The runId is embedded in the [§KEYWORD_DIRECTION§] SSE marker
 * so the frontend can resume the workflow when the user clicks Pénaliser/Booster.
 */

import { createWorkflow, createStep } from '@mastra/core/workflows';
import { z } from 'zod';
import { createClient } from '@supabase/supabase-js';
import { getKeywordCategory } from '../tools/get-keyword-category';
import { executeCorrection } from '../tools/execute-correction';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!,
);

// ──────────────────────────────────────────────────
// Schemas
// ──────────────────────────────────────────────────

export const casBInputSchema = z.object({
  term: z.string().describe('Le mot-clé extrait du message utilisateur (extraction déterministe par regex)'),
  source_id: z.string().describe('source_id de l\'AO courant'),
  user_id: z.string().describe('ID du consultant (pablo/alexandre)'),
  user_reason: z.string().describe('Message original de l\'utilisateur'),
});

const fetchAOOutputSchema = casBInputSchema.extend({
  ao_context_json: z.string().describe('JSON stringifié des données AO pour executeCorrection'),
  positive_keywords: z.array(z.string()).describe('Mots-clés qui scorent positivement pour cet AO'),
  current_role_summary: z.string().describe('Résumé du rôle actuel du terme dans le lexique'),
  is_red_flag: z.boolean().describe('Vrai si le terme est déjà un red flag dans le lexique'),
});

const waitForDirectionOutputSchema = fetchAOOutputSchema.extend({
  direction: z.enum(['keyword_red_flag', 'keyword_boost']),
});

const correctionOutputSchema = z.object({
  feedback_id: z.string(),
  proposal_summary: z.string(),
  simulation_summary: z.string(),
  correction_type: z.enum(['keyword_red_flag', 'rag_chunk', 'keyword_boost']),
  correction_value: z.string(),
  affected_high_medium: z.array(z.object({
    source_id: z.string(),
    title: z.string(),
    priority: z.string(),
  })),
});

// ──────────────────────────────────────────────────
// Step 1: fetchAOAndKeyword
// ──────────────────────────────────────────────────

const fetchAOAndKeywordStep = createStep({
  id: 'fetchAOAndKeyword',
  inputSchema: casBInputSchema,
  outputSchema: fetchAOOutputSchema,
  execute: async ({ inputData }) => {
    const { term, source_id, user_id, user_reason } = inputData;

    // Fetch AO details from Supabase
    const { data: ao, error } = await supabase
      .from('appels_offres')
      .select(`
        title, acheteur, priority, human_readable_reason,
        keyword_breakdown, matched_keywords_detail,
        llm_skipped, llm_skip_reason, decision_gate, rejet_raison
      `)
      .eq('source_id', source_id)
      .single();

    if (error || !ao) {
      throw new Error(`AO ${source_id} introuvable: ${error?.message}`);
    }

    // Extract positive keywords from matched_keywords_detail
    const matchedDetail = ao.matched_keywords_detail as Array<{ keyword: string; score?: number; category?: string }> | null;
    const positive_keywords: string[] = matchedDetail
      ? matchedDetail.map((k) => k.keyword).filter(Boolean)
      : [];

    // Build ao_context JSON for executeCorrection
    const ao_context_json = JSON.stringify({
      title: ao.title,
      acheteur: ao.acheteur,
      priority: ao.priority,
      human_readable_reason: ao.human_readable_reason,
      keyword_breakdown: ao.keyword_breakdown,
      matched_keywords_detail: ao.matched_keywords_detail,
      llm_skipped: ao.llm_skipped,
      llm_skip_reason: ao.llm_skip_reason,
      decision_gate: ao.decision_gate,
      rejet_raison: ao.rejet_raison,
    });

    // Lookup keyword in Balthazar lexicon (same logic as getKeywordCategory tool)
    const kwResult = await (getKeywordCategory.execute as Function)({ keyword: term });
    const { summary: current_role_summary, matches } = kwResult as {
      found: boolean;
      keyword: string;
      matches: Array<{ category_key: string; is_red_flag: boolean; weight: number }>;
      summary: string;
    };
    const is_red_flag = matches.some((m) => m.is_red_flag);

    return {
      term,
      source_id,
      user_id,
      user_reason,
      ao_context_json,
      positive_keywords,
      current_role_summary,
      is_red_flag,
    };
  },
});

// ──────────────────────────────────────────────────
// Step 2: waitForDirection (HITL suspend)
// ──────────────────────────────────────────────────

const waitForDirectionStep = createStep({
  id: 'waitForDirection',
  inputSchema: fetchAOOutputSchema,
  outputSchema: waitForDirectionOutputSchema,
  resumeSchema: z.object({
    direction: z.enum(['keyword_red_flag', 'keyword_boost']),
  }),
  suspendSchema: z.object({
    term: z.string(),
    source_id: z.string(),
    current_role_summary: z.string(),
    positive_keywords: z.array(z.string()),
    is_red_flag: z.boolean(),
  }),
  execute: async ({ inputData, resumeData, suspend }) => {
    const { term, source_id, user_id, user_reason, ao_context_json, positive_keywords, current_role_summary, is_red_flag } = inputData;

    // On resume: user clicked Pénaliser or Booster
    if (resumeData) {
      return {
        term,
        source_id,
        user_id,
        user_reason,
        ao_context_json,
        positive_keywords,
        current_role_summary,
        is_red_flag,
        direction: resumeData.direction,
      };
    }

    // First pass: suspend with data needed to render KeywordDirectionCard
    await suspend({
      term,
      source_id,
      current_role_summary,
      positive_keywords,
      is_red_flag,
    });

    // Unreachable after suspend — required for type inference
    return {
      term,
      source_id,
      user_id,
      user_reason,
      ao_context_json,
      positive_keywords,
      current_role_summary,
      is_red_flag,
      direction: 'keyword_red_flag' as const,
    };
  },
});

// ──────────────────────────────────────────────────
// Step 3: applyKeywordCorrection
// ──────────────────────────────────────────────────

const applyKeywordCorrectionStep = createStep({
  id: 'applyKeywordCorrection',
  inputSchema: waitForDirectionOutputSchema,
  outputSchema: correctionOutputSchema,
  execute: async ({ inputData }) => {
    const {
      term,
      source_id,
      user_id,
      user_reason,
      ao_context_json,
      direction,
    } = inputData;

    // Synthesize Q1/Q2/Q3 deterministically for Cas B (no 3-question dialog needed)
    const isExclusion = direction === 'keyword_red_flag';
    const q1_scope = isExclusion
      ? `Exclure le terme "${term}" — le marquer comme red flag dans le lexique Balthazar`
      : `Booster le terme "${term}" — renforcer son poids dans le lexique Balthazar`;
    const q2_valid_case = isExclusion
      ? `Les AOs contenant "${term}" dans un contexte hors périmètre Balthazar doivent être moins bien scorés`
      : `Les AOs contenant "${term}" dans un contexte pertinent Balthazar doivent être mieux scorés`;
    const q3_confirmed_rule = isExclusion
      ? `Le terme "${term}" est un signal d'exclusion — l'ajouter en red flag dans keyword_overrides`
      : `Le terme "${term}" est un signal d'inclusion — l'ajouter en boost dans keyword_overrides`;

    const result = await (executeCorrection.execute as Function)({
      source_id,
      client_id: 'balthazar',
      ao_context: ao_context_json,
      user_reason,
      q1_scope,
      q2_valid_case,
      q3_confirmed_rule,
      direction: isExclusion ? 'exclude' : 'include',
      created_by: user_id,
      correction_type: direction, // forced — bypasses tuning agent decision
    });

    return result as {
      feedback_id: string;
      proposal_summary: string;
      simulation_summary: string;
      correction_type: 'keyword_red_flag' | 'rag_chunk' | 'keyword_boost';
      correction_value: string;
      affected_high_medium: Array<{ source_id: string; title: string; priority: string }>;
    };
  },
});

// ──────────────────────────────────────────────────
// Workflow assembly
// ──────────────────────────────────────────────────

export const casBKeywordCorrectionWorkflow = createWorkflow({
  id: 'casBKeywordCorrectionWorkflow',
  inputSchema: casBInputSchema,
  outputSchema: correctionOutputSchema,
})
  .then(fetchAOAndKeywordStep)
  .then(waitForDirectionStep)
  .then(applyKeywordCorrectionStep)
  .commit();
