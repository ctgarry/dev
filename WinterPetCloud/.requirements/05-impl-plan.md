# 05-impl-plan — High-Level Implementation

## Touchpoints
- `catalog.lua` — bundled static pet catalog + tag map.
- `cloud.lua` — tag weighting, layout, selection state.
- `filters.lua` — search + AND/OR + scope logic.
- `ui.lua` — frames, list virtualization, pills, toasts.
- `bookmarks.lua` — save/load, account sync, export/import.
- `i18n.lua` — keys and locale tables.
- `savedvars.lua` — schema and upgrades.

## Steps (≤6, small & safe)
1. **Scaffold Data & SavedVars:** Add catalog file, base saved variables, version stamp. (≤30 lines/file)
2. **Inventory & Scope:** Implement ownership detection and tri-state scope; return ResultSet. (≤30 lines/file)
3. **Tag Cloud Core:** Render weighted cloud from ResultSet; support selection and pills. (≤30 lines/file)
4. **Filtering Logic & Search:** AND/OR toggle + text search intersection; virtualized results. (≤30 lines/file)
5. **Bookmarks & Sharing:** Persist bookmarks; account-wide visibility; manage bar UI. (≤30 lines/file)
6. **Export/Import v1:** Deterministic string with checksum; parse, validate, preview, apply. (≤30 lines/file)
