# 07-acceptance — Verification Mapped to FRs

- ✅ **FR-1:** On first run, catalog loads and `catalogVersion` is set; opening UI lists ≥1,000 pets in All scope.
- ✅ **FR-2:** Toggling to Owned shows only pets owned by the current character; switching characters changes counts.
- ✅ **FR-3:** With All scope active and no filters, cloud shows top-N tags sized by frequency; using the same seed regenerates identical layout.
- ✅ **FR-4:** Selecting tags A then B reduces ResultSet to A∩B; switching to OR expands to A∪B.
- ✅ **FR-5:** Scope toggle updates tag counts within 150 ms.
- ✅ **FR-6:** Sorting changes order without altering membership.
- ✅ **FR-7:** Saving a bookmark persists all required fields; after reload, it appears in the bar.
- ✅ **FR-8:** Bookmark created on one character appears on another after login.
- ✅ **FR-9:** Export produces a string ≤512 chars; import rejects strings with bad checksum and shows error key.
- ✅ **FR-10:** Searching “wolf” intersects with tags; clearing search restores counts.
- ✅ **FR-11:** Pill badges remove-on-click; “Clear All” resets to empty selection with defaults.
- ✅ **FR-12:** Usage stats increment on tag clicks; no network I/O occurs.
- ✅ **FR-13:** Keyboard navigation hits all cloud nodes; screen reader announces “Tag: cozy (12)”. 
- ✅ **FR-14:** Tooltips show definition and aliases populated from i18n keys.
