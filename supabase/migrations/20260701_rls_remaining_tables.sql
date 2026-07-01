-- RLS for all tables not covered by previous migrations
-- Covers: RAG tables, profiles, all mastra_* tables, backup tables
-- Note: rectificatifs_avec_original est une VIEW — hérite du RLS de appels_offres, pas d'action requise
-- Pattern: service_role for ALL (Mastra Platform connects via service_role)
-- Exception: profiles allows own-row access for authenticated users

-- ============================================
-- RAG TABLES
-- ============================================

ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "policies_service_role_only"
  ON public.policies FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.case_studies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "case_studies_service_role_only"
  ON public.case_studies FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

-- ============================================
-- AUTH TABLES
-- ============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id OR ((select auth.jwt()) ->> 'role') = 'service_role');
CREATE POLICY "profiles_insert"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id OR ((select auth.jwt()) ->> 'role') = 'service_role');
CREATE POLICY "profiles_update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id OR ((select auth.jwt()) ->> 'role') = 'service_role')
  WITH CHECK (auth.uid() = id OR ((select auth.jwt()) ->> 'role') = 'service_role');
CREATE POLICY "profiles_delete"
  ON public.profiles FOR DELETE
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

-- ============================================
-- MASTRA INTERNAL — CORE RUNTIME
-- ============================================

ALTER TABLE public.mastra_workflow_snapshot ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_workflow_snapshot_service_role_only"
  ON public.mastra_workflow_snapshot FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_traces ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_traces_service_role_only"
  ON public.mastra_traces FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_ai_spans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_ai_spans_service_role_only"
  ON public.mastra_ai_spans FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_scorers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_scorers_service_role_only"
  ON public.mastra_scorers FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_resources_service_role_only"
  ON public.mastra_resources FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_messages_service_role_only"
  ON public.mastra_messages FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_threads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_threads_service_role_only"
  ON public.mastra_threads FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_evals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_evals_service_role_only"
  ON public.mastra_evals FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_background_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_background_tasks_service_role_only"
  ON public.mastra_background_tasks FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_observational_memory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_observational_memory_service_role_only"
  ON public.mastra_observational_memory FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

-- ============================================
-- MASTRA INTERNAL — REGISTRY / VERSIONING
-- ============================================

ALTER TABLE public.mastra_agents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_agents_service_role_only"
  ON public.mastra_agents FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_agent_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_agent_versions_service_role_only"
  ON public.mastra_agent_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_mcp_clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_mcp_clients_service_role_only"
  ON public.mastra_mcp_clients FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_mcp_client_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_mcp_client_versions_service_role_only"
  ON public.mastra_mcp_client_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_mcp_servers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_mcp_servers_service_role_only"
  ON public.mastra_mcp_servers FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_mcp_server_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_mcp_server_versions_service_role_only"
  ON public.mastra_mcp_server_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_datasets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_datasets_service_role_only"
  ON public.mastra_datasets FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_dataset_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_dataset_versions_service_role_only"
  ON public.mastra_dataset_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_dataset_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_dataset_items_service_role_only"
  ON public.mastra_dataset_items FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_scorer_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_scorer_definitions_service_role_only"
  ON public.mastra_scorer_definitions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_scorer_definition_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_scorer_definition_versions_service_role_only"
  ON public.mastra_scorer_definition_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_workspaces ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_workspaces_service_role_only"
  ON public.mastra_workspaces FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_workspace_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_workspace_versions_service_role_only"
  ON public.mastra_workspace_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_prompt_blocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_prompt_blocks_service_role_only"
  ON public.mastra_prompt_blocks FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_prompt_block_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_prompt_block_versions_service_role_only"
  ON public.mastra_prompt_block_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_skills_service_role_only"
  ON public.mastra_skills FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_skill_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_skill_versions_service_role_only"
  ON public.mastra_skill_versions FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_skill_blobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_skill_blobs_service_role_only"
  ON public.mastra_skill_blobs FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_experiments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_experiments_service_role_only"
  ON public.mastra_experiments FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_experiment_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_experiment_results_service_role_only"
  ON public.mastra_experiment_results FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

-- ============================================
-- BACKUP TABLES (2026-05-04)
-- ============================================

ALTER TABLE public.mastra_messages_bk_20260504 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_messages_bk_service_role_only"
  ON public.mastra_messages_bk_20260504 FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_threads_bk_20260504 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_threads_bk_service_role_only"
  ON public.mastra_threads_bk_20260504 FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_traces_bk_20260504 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_traces_bk_service_role_only"
  ON public.mastra_traces_bk_20260504 FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_workflow_snapshot_bk_20260504 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_workflow_snapshot_bk_service_role_only"
  ON public.mastra_workflow_snapshot_bk_20260504 FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

ALTER TABLE public.mastra_resources_bk_20260504 ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mastra_resources_bk_service_role_only"
  ON public.mastra_resources_bk_20260504 FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');
