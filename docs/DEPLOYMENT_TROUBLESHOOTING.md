# Deployment Troubleshooting — Mastra Platform

> **Lis ce document AVANT chaque `npx mastra server deploy`** ou en cas d'incident en prod. Il liste les pièges connus, leurs symptômes, et leurs fixes vérifiés. Mis à jour 2026-05-04 après une saga de debug de plusieurs heures sur la persistence Memory.

## Pre-deploy checklist

À cocher mentalement avant chaque deploy :

- [ ] `npx tsc --noEmit` passe localement
- [ ] `.env` local cohérent avec les env vars du dashboard Mastra Platform (cf piège #4)
- [ ] Pas d'`import` direct de `src/utils/<file>` depuis un tool ou workflow — utiliser le barrel `from '../../utils'` (cf piège #3)
- [ ] Aucun deploy/migrate process Mastra ne tourne déjà (`ps aux | grep mastra`)
- [ ] Endpoint actuel testé : `curl -I https://balthazar-tender-monitoring-8083.server.mastra.cloud/api/agents` doit retourner 200 (avant deploy, pour avoir un baseline)

Après deploy :

- [ ] Status "Ready" dans dashboard Mastra Platform (PAS juste "Active deployment" — le CLI dit "Deploy succeeded" même quand le container crashe)
- [ ] `curl /api/agents` retourne 200
- [ ] Test fonctionnel : envoyer un message dans le chat frontend, hard refresh, vérifier que la conversation persiste

---

## Pièges connus — root causes & fixes

### Piège #1 — Connexion Postgres : `ENETUNREACH` IPv6

**Symptôme dans les runtime logs Mastra Platform :**
```
MastraError: connect ENETUNREACH 2a05:d018:135e:...:5432
errno: -101  code: 'ENETUNREACH'
details: { tableName: 'mastra_threads' }
```

**Cause :** Mastra Platform (Google Cloud Run) **n'a pas d'IPv6 outbound**. L'URL Supabase « Direct connection » (`db.<ref>.supabase.co`) ne résout qu'en IPv6 depuis la dépréciation IPv4 par Supabase début 2024.

**Fix :** Utiliser le **Session pooler** (port 5432, IPv4-proxied), pas la direct connection. Récupérable dans Supabase dashboard → Connect → Session pooler :
```
postgresql://postgres.<ref>:<pwd>@aws-1-eu-west-1.pooler.supabase.com:5432/postgres
```
**NE PAS** confondre avec le Transaction pooler (port 6543) qui est incompatible avec PostgresStore.

---

### Piège #2 — Connexion Postgres : `SELF_SIGNED_CERT_IN_CHAIN`

**Symptôme dans les runtime logs :**
```
MastraError: self-signed certificate in certificate chain
code: 'SELF_SIGNED_CERT_IN_CHAIN'
Warning: SECURITY WARNING: The SSL modes 'prefer', 'require', and 'verify-ca' are treated as aliases for 'verify-full'.
- If you want libpq compatibility now, use 'uselibpqcompat=true&sslmode=require'
```

**Cause :** Le package `pg-connection-string` v2+ (utilisé par `@mastra/pg`) traite `sslmode=require` comme `verify-full`, ce qui exige une chaîne de certificats valide. Le pooler Supabase utilise un certificat dont la chaîne n'est pas dans le trust store par défaut.

**Fix :** Ajouter `uselibpqcompat=true` à la query string :
```
?uselibpqcompat=true&sslmode=require
```
URL complète :
```
postgresql://postgres.<ref>:<pwd>@aws-1-eu-west-1.pooler.supabase.com:5432/postgres?uselibpqcompat=true&sslmode=require
```

---

### Piège #3 — Bundler Mastra : `MODULE_NOT_FOUND` sur fichier de `src/utils/`

**Symptôme dans les runtime logs :**
```
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/app/.mastra/output/<file>.mjs'
imported from /app/.mastra/output/tools/<uuid>.mjs
```

**Cause :** Le bundler Mastra (Cloud Build) fait du code-splitting et crée des chunks séparés pour les fichiers `src/utils/<X>.ts` quand ils sont importés directement par un tool ou workflow. Mais l'artifact zip ne contient pas toujours ces chunks → crash au démarrage. Le build local (qui inline tout dans `mastra.mjs`) ne reproduit pas ce bug.

**Fix :** Toujours importer via le barrel `src/utils/index.ts`, pas via `src/utils/<file>.ts` directement.

```ts
// ❌ MAUVAIS — provoque le code-splitting
import { insertAndIndexChunk } from '../../utils/rag-indexer';

// ✅ BON
import { insertAndIndexChunk } from '../../utils';
```

Et s'assurer que `src/utils/index.ts` re-exporte le module :
```ts
export * from './rag-indexer';
```

---

### Piège #4 — Env vars : le `.env` local n'est lu **qu'au premier deploy**

**Doc Mastra :**
> Environment variables from `.env`, `.env.local`, and `.env.production` are included automatically **on first deploy**. After that, manage env vars through the web dashboard.

**Conséquence :** Modifier `.env` localement et redéployer **ne change pas** les env vars du container. Le dashboard fait foi.

**Fix :**
- **Toujours** modifier les env vars via le dashboard Mastra Platform (Project → Env Variables → Edit → Save and restart).
- Garder le `.env` local synchronisé pour `mastra dev` local et la cohérence, mais c'est seulement informatif après le 1er deploy.

---

### Piège #5 — Migration v0→v1 : `npx mastra migrate` oubliable mais souvent inoffensif

Lors d'un upgrade major Mastra (ex: v0 → v1), une migration DB est requise selon la doc. En pratique, la commande peut dire « Migration already complete » même quand des changements de schéma ont eu lieu. Lance-la quand même par sécurité après tout upgrade.

```bash
cd ~/Balthazar---Agentic-System---AO-veille-
npx mastra migrate   # interactif : confirme avec "Yes" si backup OK
```

**Avant la migration :** snapshot les tables Mastra non-vides via `CREATE TABLE mastra_X_bk_YYYYMMDD AS TABLE mastra_X` (cf section Backup ci-dessous).

---

### Piège #6 — Le CLI ment : « Deploy succeeded » ≠ « container UP »

Le CLI `mastra server deploy` retourne « Deploy succeeded! https://... » dès que **l'upload + Cloud Build** réussit. Mais le container peut crasher au démarrage et tourner en boucle (502 Cloudflare).

**Comment vérifier réellement :**
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://balthazar-tender-monitoring-8083.server.mastra.cloud/api/agents
```
Si 200 → service UP. Si 502 → container crashe, va dans dashboard Mastra Platform > Deployments > clique sur le dernier deploy > onglet runtime logs.

Le dashboard Mastra Platform peut afficher « Active deployment » alors que le container 502. **Toujours vérifier l'URL avec curl**, pas se fier au statut UI.

---

### Piège #7 — `yes |` casse le spinner du CLI deploy

Hier `cd ... && yes | npx mastra server deploy` a fait boucler indéfiniment l'étape « Zipping build artifact » (le spinner tournait pendant 12+ minutes). Le pipe `yes` perturbe le rendu interactif du CLI.

**Fix :**
- Pour `mastra server deploy` (pas de prompt) : utiliser `< /dev/null` à la place :
  ```bash
  npx mastra server deploy < /dev/null
  ```
- Pour `mastra migrate` (a un prompt « backup ? »): passer par la commande interactive normale ou utiliser `printf 'y\n' |` (un seul Y, pas un flux infini).

---

### Piège #10 — `memory: { thread, resource }` (v1) ≠ `threadId` + `resourceId` (v0)

**Symptôme :** Le service Mastra tourne, l'agent répond aux messages, MAIS aucune ligne n'apparaît dans `mastra_messages` / `mastra_threads`. Persistence cassée silencieusement, sans erreur dans les logs.

**Cause :** L'API HTTP du serveur Mastra v1 a changé la signature pour activer la persistence. Les anciens champs `threadId` et `resourceId` au top-level du body POST sont **silencieusement ignorés**. Il faut un objet `memory: { thread, resource }`.

**v0 (déprécié, ignoré silencieusement) :**
```ts
{
  messages: [...],
  threadId: "ao-XXX-userY",
  resourceId: "userY",
  savePerStep: true,            // ← n'existe plus en v1
}
```

**v1 (correct) :**
```ts
{
  messages: [...],
  memory: {
    thread: "ao-XXX-userY",
    resource: "userY",
  },
}
```

**Comment le diagnostiquer rapidement :**
```bash
curl -sS -X POST "https://balthazar-tender-monitoring-8083.server.mastra.cloud/api/agents/aoFeedbackSupervisor/stream" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"diag"}],"memory":{"thread":"diag-thread-1","resource":"diag-user"}}' \
  --max-time 15
```
Puis vérifier en SQL si `mastra_messages` a une nouvelle ligne avec `thread_id = "diag-thread-1"`.

**Fichier impacté côté frontend :** `app/api/chat/route.ts` (la route Next.js qui forward vers Mastra).

---

### Piège #9 — `EMAXCONNSESSION` : pool Supavisor saturé à 15

**Symptôme dans les runtime logs (apparaît sous charge réelle, pas au démarrage) :**
```
MastraError: (EMAXCONNSESSION) max clients reached in session mode - max clients are limited to pool_size: 15
id: 'MASTRA_STORAGE_PG_GET_WORKFLOW_RUN_BY_ID_FAILED'
```

**Cause :** Le Session pooler Supabase (Supavisor) **hard-limite 15 connexions concurrentes par projet**. On a 2 instances `PostgresStore` (instance + agent memory) + 1 `PgVector` pour le RAG. Si chaque pool default à ~10 connexions, on dépasse instantanément.

**Fix :** Configurer `max` (taille de pool) explicite sur chaque `PostgresStore` :
```ts
new PostgresStore({
  id: 'mastra-pg-store',
  connectionString: process.env.SUPABASE_DIRECT_URL!,
  max: 4,                      // ← essentiel
  idleTimeoutMillis: 10_000,   // libère plus vite
})
```
Budget total recommandé : 4 (instance) + 4 (agent memory) + 3 (PgVector) = 11 sur 15 → 4 de marge.

Si on ajoute un nouveau `PostgresStore` ou `PgVector`, **ajuster les `max` à la baisse** pour rester sous 15.

---

### Piège #8 — Deploys concurrents qui zombifient

Si tu lances un nouveau deploy alors qu'un précédent tourne toujours (souvent invisible, en `R` state), les deux entrent en conflit et zippent indéfiniment.

**Avant tout nouveau deploy** :
```bash
ps aux | grep -E "mastra.*deploy" | grep -v grep
# si non-vide :
pkill -9 -f "mastra server deploy"
pkill -9 -f "npm exec mastra"
```

---

## Backup avant migration

Avant tout `npx mastra migrate`, snapshot les tables Mastra non-vides. Via Supabase MCP ou SQL editor :

```sql
CREATE TABLE mastra_messages_bk_YYYYMMDD AS TABLE mastra_messages;
CREATE TABLE mastra_threads_bk_YYYYMMDD AS TABLE mastra_threads;
CREATE TABLE mastra_traces_bk_YYYYMMDD AS TABLE mastra_traces;
CREATE TABLE mastra_workflow_snapshot_bk_YYYYMMDD AS TABLE mastra_workflow_snapshot;
CREATE TABLE mastra_resources_bk_YYYYMMDD AS TABLE mastra_resources;
```

Rollback en cas de pépin : `DROP TABLE mastra_X; ALTER TABLE mastra_X_bk_YYYYMMDD RENAME TO mastra_X;` (recréer indexes/contraintes manuellement si besoin).

---

## Tables Mastra : nommage v1

Pour info quand on regarde la DB :

| v0 / legacy | v1 |
|---|---|
| `mastra_traces` | `mastra_ai_spans` (les traces v1 vont là) |
| `mastra_messages` | `mastra_messages` (inchangé) |
| `mastra_threads` | `mastra_threads` (inchangé) |
| `mastra_workflow_snapshot` | `mastra_workflow_snapshot` (inchangé) |

---

## Endpoint canonique

**URL prod :** `https://balthazar-tender-monitoring-8083.server.mastra.cloud`

(Le sous-domaine `*.server.mastra.cloud` reste l'URL Mastra Platform malgré le rename Mastra Cloud → Mastra Platform — ne pas confondre avec l'ancien Mastra Cloud qui est déprécié.)

**Project ID :** `f674d205-8032-40d1-99d4-e853057a3fa5`
**Org ID :** `org_01KQ26W5NAPB83G99CTFZBTRTM`
**Supabase project :** `evzeojxonolqfzybroqb` (region eu-west-1)

---

## Historique des incidents majeurs

- **2026-04-28 → 2026-05-04** — Persistence Memory cassée pendant 6 jours après migration v0→v1.
  - Cause #1 : ENETUNREACH (piège #1) — Mastra Platform IPv4-only vs Supabase Direct IPv6-only depuis dépréciation.
  - Cause #2 : SELF_SIGNED_CERT (piège #2) — `pg-connection-string` v2 strict.
  - Cause #3 : MODULE_NOT_FOUND rag-indexer (piège #3) — bundler split foireux.
  - Cause #4 : EMAXCONNSESSION (piège #9) — pool Supavisor saturé à 15.
  - **Cause finale (la vraie) : piège #10** — frontend envoyait `threadId`/`resourceId` au top-level (signature v0) au lieu de `memory: { thread, resource }` (signature v1). Le service tournait, répondait, mais les writes étaient silencieusement ignorés.
  - Fix final : Session pooler + `uselibpqcompat=true&sslmode=require` + barrel imports + pool max:4 + `memory: { thread, resource }` dans le body chat.
  - Détecté parce que le frontend chat n'écrivait plus `mastra_messages` (figé au 28 avril 13:02 précis).
