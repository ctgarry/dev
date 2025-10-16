# 02-fr-nfr — Functional & Non-Functional Requirements

## Functional Requirements
- **FR-1. Catalog Bootstrapping:** On first run, system **must** load a bundled pet catalog containing IDs, names, families/types, sources, rarities, and tag associations.
- **FR-2. Inventory Detection:** On UI open, system **must** compute Owned/Unowned sets using platform APIs and cache until session-reload or explicit refresh.
- **FR-3. Tag Cloud Rendering:** The tag cloud **must** display a curated, de-duplicated vocabulary with frequency-based weighting and deterministic layout given the same seed.
- **FR-4. Filtering Logic:** When the user selects multiple tags, results **must** apply AND logic by default; a toggle **must** permit OR logic.
- **FR-5. Scope Toggle:** A tri-state control **must** switch between Owned, Unowned, and All, updating tag weights and counts.
- **FR-6. Sorting:** Results **must** support sort by Name, Rarity, Newest, Most-Used (local), and Source.
- **FR-7. Bookmark Save/Load:** System **must** persist bookmarks with fields: name, createdAt, updatedAt, tagKeys[], logicMode, scope, sort, layoutSeed, notes?.
- **FR-8. Account Share:** Bookmarks **must** be stored in account-wide saved variables accessible to all characters.
- **FR-9. Export/Import:** System **must** export/import bookmarks as a compact, checksum-validated, versioned string; malformed strings **must** be rejected with a clear error.
- **FR-10. Search Interplay:** A text search box **must** filter by name and alias, intersecting with tag filters.
- **FR-11. UI Feedback:** Active filters **must** be pill-badges with remove-on-click; a “Clear All” control **must** reset state.
- **FR-12. Telemetry (local only):** System **must** track local most-used tags (counts) to inform default weighting; no external transmission.
- **FR-13. Accessibility:** The cloud **must** be navigable via keyboard and announce counts to screen readers.
- **FR-14. Help:** Hover tooltips **must** show tag definitions and aliases from i18n.

## Non-Functional Requirements
- **NFR-1. Performance:** Cloud render ≤ 100 ms for 1,000 pets; filter apply ≤ 150 ms after each interaction on mid-tier hardware.
- **NFR-2. Footprint:** Bundled catalog ≤ 400 KB compressed; saved variables increase ≤ 100 KB for 200 bookmarks.
- **NFR-3. Determinism:** Given identical inputs, layout and results **must** be deterministic.
- **NFR-4. Robustness:** Invalid import strings **must** not crash UI; errors **must** be user-readable.
- **NFR-5. Internationalization:** All UI strings **must** route through i18n keys with enUS seed and locale fallbacks.
- **NFR-6. Offline:** All features **must** work offline post-install.
- **NFR-7. Privacy:** No external calls; shares remain account-local unless user manually copies export strings.
