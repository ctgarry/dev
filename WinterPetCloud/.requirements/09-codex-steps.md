# 09-codex-steps — Strict Light-Diff Tasks

> Follow Codex Workflow (STOP/WAI after each). ≤30 changed lines/file per step.

1. **ADD catalog.lua** — Define `PetCloud_CatalogVersion` and minimal catalog table with 3 sample entries to prove boot path (real data later).
2. **MOD savedvars.lua** — Initialize account-level saved variables: versions, bookmarks[], usage stats, last seed.
3. **ADD filters.lua** — Implement scope computation and a pure function `applyFilters(state): ResultSet` including AND/OR and text search.
4. **ADD cloud.lua** — Compute tag weights from frequency × (1+log(usage)) with deterministic layout by `layoutSeed`.
5. **ADD ui.lua** — Render cloud, pills, result list (virtualized), and controls; wire keyboard focus order; basic tooltips.
6. **ADD bookmarks.lua** — Save/load, account share, export/import v1 with CRC32 checksum; preview modal.
7. **ADD i18n.lua** — Seed enUS keys from 06; provide locale fallback.
8. **QA Pass** — Validate acceptance items from 07; fix defects respecting light-diff limits.
