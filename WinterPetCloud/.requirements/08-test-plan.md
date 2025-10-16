# 08-test-plan — Smoke / Feature / Edge

## Smoke
- Open addon frame; ensure catalog present; FPS stable; no errors.
- Toggle scopes; verify counts change and layout reflows under 100 ms.

## Feature
- Multi-tag AND/OR interaction across 3+ tags with search term.
- Save, reload UI, verify bookmark persistence and account share.
- Export bookmark, delete local, import string, verify equivalence.

## Edge
- Import: corrupted string, wrong version, mismatched checksum, unknown tags.
- Empty collection (0 owned) — cloud weights based on All scope.
- Very large collection (1000+ owned) — performance budget holds.
- Tag with zero results in current scope is visually de-emphasized but still discoverable via “more”.
- Non-Latin locales — search matches aliases; i18n fallback works.
