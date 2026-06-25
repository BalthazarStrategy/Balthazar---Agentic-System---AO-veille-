## Obsidian Vault Integration
My knowledge base lives at ~/Documents/brain.
At the start of each session, read:
- ~/Documents/brain/CLAUDE.md
- ~/Documents/brain/01-daily/ (last 3 entries)
- ~/Documents/brain/02-projects/balthazar/context.md

At the end of each session, append a summary to ~/Documents/brain/01-daily/YYYY-MM-DD.md.

---

## État infra post-migration (2026-06-24)

Infrastructure migrée du workspace "Forwarding Copilot" vers l'organisation **Balthazar** :

- **Resend** : nouvelle clé API Balthazar. Domaine `balthazar.org` vérifié (2026-06-25). `EMAIL_FROM=veille@balthazar.org` — actif en local et sur Mastra Platform.
- **Inngest** : migré du workspace "Phonic Copilot" / "Forwarding Copilot" vers workspace "Balthazar". Mêmes fonctions (`ao-veille-daily`), même URL de sync (`/api/inngest`). Mettre à jour `INNGEST_EVENT_KEY` et `INNGEST_SIGNING_KEY` dans le dashboard Mastra Platform si nécessaire.
- **Mastra Platform** : redéployé sur org Balthazar. URL inchangée : `https://balthazar-tender-monitoring-8083.server.mastra.cloud`.
- **Supabase** : projet transféré vers org Balthazar. Clés et URL inchangées — aucune action requise.
- **Vercel** : frontend migré vers org Balthazar (en attente d'approbation GitHub au 2026-06-24).

---

## ⚠️ AVANT TOUT DEPLOY MASTRA — LIRE OBLIGATOIREMENT

**Avant chaque `npx mastra server deploy` ou `npx mastra migrate`, ouvrir et relire :**

→ [`docs/DEPLOYMENT_TROUBLESHOOTING.md`](./docs/DEPLOYMENT_TROUBLESHOOTING.md)

Contient la pre-deploy checklist, les 8 pièges connus avec leurs root causes (ENETUNREACH IPv6, SELF_SIGNED_CERT, MODULE_NOT_FOUND bundler, env vars dashboard-only après 1er deploy, CLI qui ment sur le succès, deploys zombies, etc.) et leurs fixes vérifiés. Mis à jour 2026-05-04 après une saga de 6 jours de persistence Memory cassée silencieusement.

**En cas d'incident en prod (502, persistence cassée, container qui crashe) — commencer par ce doc, pas par debugger from scratch.**

---

# Balthazar — Système Agentique de Veille Appels d'Offres

## What this project is

Backend IA pour la veille automatique des appels d'offres publics français (BOAMP + MarchesOnline) pour Balthazar Consulting (Pablo Rigaud). Analyse sémantique GPT-4o + RAG, scoring HIGH/MEDIUM/LOW, email récapitulatif quotidien.

## Stack

| Layer | Tech |
|-------|------|
| AI agents/workflows | Mastra Platform (`@mastra/core`) |
| Job queue | Inngest v3 |
| Database | Supabase (PostgreSQL + pgvector) |
| LLM | OpenAI GPT-4o |
| Email | Resend |

## Architecture

```
Déclenchement (cron ou manuel)
  → aoVeilleWorkflow (10 steps):
      1. fetchAndPrequalifyStep    — BOAMP API + MarchesOnline RSS
      2. handleCancellationsStep   — filtre annulations
      3. detectRectificationStep   — détecte rectificatifs
      4. filterAlreadyAnalyzedStep — évite re-analyse
      5. keywordMatchingStep       — pré-scoring mots-clés (gratuit)
      6. prepareForForeachStep     — split LLM / skip-LLM
      7. .foreach(processOneAOWorkflow, { concurrency: 1 })
           → Branch 0: contexte seul (0 LLM)
           → Branch 1: annulé (0 LLM)
           → Branch 2: rectificatif mineur (0 LLM)
           → Branch 2.5: skip-LLM pré-résolu (0 LLM)
           → Branch 3/4: analyse complète (1 appel LLM GPT-4o + RAG)
      8. normalizeBranchResultsStep
      9. aggregateResultsStep
      10. saveResultsStep + sendEmailStep → Supabase + Resend
```

## Agents

- **boampSemanticAnalyzer** — analyse sémantique + RAG (policies + case studies Balthazar + historique clients)
- **aoFeedbackTuningAgent** — feedback loop pour améliorer le RAG
- **aoFeedbackSupervisor** — supervision du feedback

## Frontend

Dashboard séparé : `~/balthazar-veille-app` (Next.js). 3 panneaux : liste AOs / détail / chat feedback. Appelle Mastra Platform via HTTP.

## Key files

```
src/mastra/
  agents/boamp-semantic-analyzer.ts        # qualification AO (GPT-4o + RAG)
  agents/ao-feedback-supervisor/index.ts   # lean router feedback (Memory + tools)
  agents/ao-feedback-supervisor/instructions.ts
  agents/ao-correction-agent.ts            # protocole correction 3 questions
  agents/ao-feedback-tuning-agent.ts       # diagnostic structuré (FeedbackProposal)
  tools/index.ts                           # barrel — 16 tools + RAG tools
  tools/_shared/supabase.ts               # client Supabase partagé
  tools/balthazar-rag-tools.ts            # RAG tools (embed, vectorStore)
  tools/boamp-fetcher.ts
  tools/marchesonline-rss-fetcher.ts
  workflows/ao-veille.ts
  workflows/feedback-workflow.ts
```

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **Balthazar---Agentic-System---AO-veille-** (1792 symbols, 2245 relationships, 38 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/Balthazar---Agentic-System---AO-veille-/context` | Codebase overview, check index freshness |
| `gitnexus://repo/Balthazar---Agentic-System---AO-veille-/clusters` | All functional areas |
| `gitnexus://repo/Balthazar---Agentic-System---AO-veille-/processes` | All execution flows |
| `gitnexus://repo/Balthazar---Agentic-System---AO-veille-/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
