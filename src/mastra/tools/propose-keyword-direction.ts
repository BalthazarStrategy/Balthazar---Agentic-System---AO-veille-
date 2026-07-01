import { createTool } from '@mastra/core/tools';
import { z } from 'zod';

export const proposeKeywordDirection = createTool({
  id: 'proposeKeywordDirection',
  description: `Affiche la carte interactive de choix de direction pour un mot-clé précis (pénaliser ou booster).
À appeler en Cas B, après getKeywordCategory, pour demander à l'utilisateur ce qu'il veut faire du terme.
Retourne les données nécessaires à l'interface pour afficher la carte — ne retourne PAS un choix.
Après cet appel, tu dois t'arrêter IMMÉDIATEMENT. L'interface affiche les boutons, le choix arrive via [keyword_direction:VALUE].`,
  inputSchema: z.object({
    term: z.string().describe('Le mot-clé précis mentionné par l\'utilisateur'),
    source_id: z.string().describe('source_id de l\'AO courant'),
    current_role_summary: z.string().describe('Résumé du rôle actuel du terme dans le lexique (depuis getKeywordCategory)'),
    positive_keywords: z.array(z.string()).describe('Mots-clés qui scorent positivement pour cet AO (depuis matched_keywords_detail)'),
  }),
  outputSchema: z.object({
    term: z.string(),
    source_id: z.string(),
    current_role_summary: z.string(),
    positive_keywords: z.array(z.string()),
  }),
  execute: async ({ term, source_id, current_role_summary, positive_keywords }) => ({
    term,
    source_id,
    current_role_summary,
    positive_keywords,
  }),
});
