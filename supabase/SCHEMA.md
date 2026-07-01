# Supabase Schema — Balthazar AO Veille

Project ID: `evzeojxonolqfzybroqb`

## Business Tables

### `clients`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `text` | PK |
| `name` | `text` | |
| `email` | `text` | |
| `preferences` | `jsonb` | Nullable |
| `criteria` | `jsonb` | Nullable |
| `keywords` | `_text` | Nullable |
| `profile` | `jsonb` | Nullable |
| `financial` | `jsonb` | Nullable |
| `technical` | `jsonb` | Nullable |
| `created_at` | `timestamp` | Nullable |
| `updated_at` | `timestamp` | Nullable |

RLS: ✅ enabled — service_role (writes) + authenticated (reads)

---

### `appels_offres`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `int4` | PK |
| `source` | `text` | |
| `source_id` | `text` | Unique |
| `title` | `text` | |
| `description` | `text` | Nullable |
| `keywords` | `_text` | Nullable |
| `acheteur` | `text` | Nullable |
| `acheteur_email` | `text` | Nullable |
| `acheteur_tel` | `text` | Nullable |
| `budget_min` | `numeric` | Nullable |
| `budget_max` | `numeric` | Nullable |
| `deadline` | `timestamp` | Nullable |
| `publication_date` | `timestamp` | Nullable |
| `type_marche` | `text` | Nullable |
| `region` | `text` | Nullable |
| `url_ao` | `text` | Nullable |
| `keyword_score` | `numeric` | Nullable |
| `matched_keywords` | `_text` | Nullable |
| `semantic_score` | `numeric` | Nullable |
| `semantic_reason` | `text` | Nullable |
| `feasibility` | `jsonb` | Nullable |
| `final_score` | `numeric` | Nullable |
| `priority` | `text` | Nullable |
| `procedure_type` | `text` | Nullable |
| `has_correctif` | `bool` | Nullable |
| `is_renewal` | `bool` | Nullable |
| `warnings` | `_text` | Nullable |
| `criteres_attribution` | `jsonb` | Nullable |
| `client_id` | `text` | Nullable (FK → clients.id) |
| `raw_json` | `jsonb` | Nullable |
| `status` | `text` | Nullable |
| `analyzed_at` | `timestamp` | Nullable |
| `is_rectified` | `bool` | Nullable |
| `rectification_date` | `timestamptz` | Nullable |
| `rectification_count` | `int4` | Nullable |
| `analysis_history` | `jsonb` | Nullable |
| `rectification_changes` | `jsonb` | Nullable |
| `boamp_id` | `text` | Nullable |
| `normalized_id` | `text` | Nullable |
| `annonce_lie` | `text` | Nullable |
| `etat` | `text` | Nullable |
| `uuid_procedure` | `uuid` | Nullable |
| `siret` | `text` | Nullable |
| `dedup_key` | `text` | Nullable |
| `siret_deadline_key` | `text` | Nullable |
| `keyword_breakdown` | `jsonb` | Nullable |
| `matched_keywords_detail` | `jsonb` | Nullable |
| `llm_skipped` | `bool` | Nullable |
| `llm_skip_reason` | `text` | Nullable |
| `rag_sources_detail` | `jsonb` | Nullable |
| `decision_gate` | `text` | Nullable |
| `confidence_decision` | `text` | Nullable |
| `rejet_raison` | `text` | Nullable |
| `human_readable_reason` | `text` | Nullable |
| `manual_priority` | `text` | Nullable |

RLS: ✅ enabled — service_role (writes) + authenticated (reads)

---

### `ao_feedback`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `uuid` | PK |
| `source_id` | `text` | |
| `title` | `text` | Nullable |
| `url_ao` | `text` | Nullable |
| `client_id` | `text` | |
| `feedback` | `text` | |
| `reason` | `text` | Nullable |
| `keyword_score` | `int4` | Nullable |
| `semantic_score` | `numeric` | Nullable |
| `rag_sources` | `_text` | Nullable |
| `agent_diagnosis` | `text` | Nullable |
| `agent_proposal` | `text` | Nullable |
| `confirmed_by_user` | `bool` | Nullable |
| `applied` | `bool` | Nullable |
| `correction_type` | `text` | Nullable |
| `created_at` | `timestamptz` | Nullable |
| `processed_at` | `timestamptz` | Nullable |
| `status` | `text` | Nullable — enum: draft, agent_proposed, awaiting_confirm, applied, rejected |
| `correction_value` | `text` | Nullable |
| `chunk_content` | `text` | Nullable |
| `source` | `text` | Nullable |
| `created_by` | `text` | Nullable |
| `chunk_vector_id` | `text` | Nullable |

RLS: ✅ enabled — service_role only (ALL)

---

### `keyword_overrides`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `uuid` | PK |
| `client_id` | `text` | |
| `type` | `text` | enum: red_flag, required_keyword |
| `value` | `text` | |
| `reason` | `text` | Nullable |
| `feedback_id` | `uuid` | Nullable (FK → ao_feedback.id) |
| `active` | `bool` | Nullable |
| `created_at` | `timestamptz` | Nullable |

RLS: ✅ enabled — service_role only (ALL)

---

### `ao_veille_runs`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `uuid` | PK |
| `client_id` | `text` | (FK → clients.id) |
| `since` | `date` | |
| `until` | `date` | Nullable |
| `source` | `text` | |
| `external_run_id` | `text` | Nullable |
| `status` | `text` | |
| `error` | `text` | Nullable |
| `created_at` | `timestamptz` | Nullable |
| `updated_at` | `timestamptz` | Nullable |

RLS: ✅ enabled — service_role (writes) + authenticated (reads)

---

### `veille_email_logs`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `uuid` | PK |
| `client_id` | `text` | (FK → clients.id) |
| `since` | `date` | |
| `until` | `date` | Nullable |
| `sent_at` | `timestamptz` | Nullable |
| `status` | `text` | |
| `message_id_resend` | `text` | Nullable |
| `payload_hash` | `text` | Nullable |
| `run_id` | `uuid` | Nullable (FK → ao_veille_runs.id) |
| `created_at` | `timestamptz` | Nullable |
| `email_type` | `text` | Nullable |

RLS: ✅ enabled — service_role (writes) + authenticated (reads)

---

---

### `rectificatifs_avec_original`
Vue ou table d'analyse liant chaque rectificatif à son AO d'origine, avec comparaison des scores avant/après.

| Column | Type | Constraints |
|--------|------|-------------|
| `rectificatif_id` | `int4` | (FK → appels_offres.id) |
| `rectificatif_source_id` | `text` | |
| `rectificatif_title` | `text` | |
| `rectification_date` | `timestamptz` | |
| `rectification_changes` | `jsonb` | Nullable — array of `{field, old, new, change_pct?, days_added?}` |
| `original_id` | `int4` | Nullable (FK → appels_offres.id) |
| `original_source_id` | `text` | Nullable |
| `original_title` | `text` | Nullable |
| `original_semantic_score` | `numeric` | Nullable |
| `original_priority` | `text` | Nullable |
| `new_semantic_score` | `numeric` | Nullable |
| `new_priority` | `text` | Nullable |
| `score_improvement` | `numeric` | Nullable |

RLS: n/a — VIEW (hérite du RLS de `appels_offres`)

---

## RAG Tables

### `policies`
Balthazar policy documents indexed for RAG.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `int4` | PK |
| `vector_id` | `text` | Unique |
| `embedding` | `vector` | Nullable |
| `metadata` | `jsonb` | Nullable |
| `active` | `bool` | |

RLS: ✅ enabled (migration 20260701) — service_role only (ALL)

---

### `case_studies`
Balthazar case studies indexed for RAG.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `int4` | PK |
| `vector_id` | `text` | Unique |
| `embedding` | `vector` | Nullable |
| `metadata` | `jsonb` | Nullable |

RLS: ✅ enabled (migration 20260701) — service_role only (ALL)

---

## Auth Tables

### `profiles`
| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `uuid` | PK (FK → auth.users.id) |
| `full_name` | `text` | |
| `username` | `text` | Unique |
| `role` | `text` | |
| `created_at` | `timestamptz` | Nullable |

RLS: ✅ enabled (migration 20260701) — own row (authenticated) + service_role

---

## Mastra Internal Tables

All managed exclusively by Mastra Platform via service_role connection.  
RLS: ✅ enabled (migration 20260701) — service_role only (ALL) on all tables below.

### Core runtime
- `mastra_workflow_snapshot` — workflow state persistence (HITL suspend/resume)
- `mastra_traces` — OpenTelemetry trace spans
- `mastra_ai_spans` — AI-specific spans with entity tracking
- `mastra_scorers` — eval scorer run results
- `mastra_resources` — agent working memory + resource metadata
- `mastra_messages` — conversation messages per thread
- `mastra_threads` — conversation threads per resource
- `mastra_evals` — eval run results
- `mastra_background_tasks` — async tool call tracking
- `mastra_observational_memory` — rolling observation/reflection memory
- `mastra_experiments` — experiment run tracking
- `mastra_experiment_results` — per-item experiment results

### Registry / versioning
- `mastra_agents` — agent registry
- `mastra_agent_versions` — agent version history
- `mastra_mcp_clients` — MCP client registry
- `mastra_mcp_client_versions`
- `mastra_mcp_servers` — MCP server registry
- `mastra_mcp_server_versions`
- `mastra_datasets` — eval dataset registry
- `mastra_dataset_versions`
- `mastra_dataset_items`
- `mastra_scorer_definitions`
- `mastra_scorer_definition_versions`
- `mastra_workspaces`
- `mastra_workspace_versions`
- `mastra_prompt_blocks`
- `mastra_prompt_block_versions`
- `mastra_skills`
- `mastra_skill_versions`
- `mastra_skill_blobs`
- `mastra_experiments`
- `mastra_experiment_results`

---

## Backup Tables (2026-05-04)

One-time snapshots taken before the Mastra v0→v1 memory migration. No active use.  
RLS: ✅ enabled (migration 20260701) — service_role only (ALL).

- `mastra_messages_bk_20260504`
- `mastra_threads_bk_20260504`
- `mastra_traces_bk_20260504`
- `mastra_workflow_snapshot_bk_20260504`
- `mastra_resources_bk_20260504`
