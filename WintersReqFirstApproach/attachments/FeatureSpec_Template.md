
# Feature: <name>
Problem: …
Goals: …
Non‑Goals: …
Personas: …

## Functional Requirements
- **FR‑1.** When <condition>, the system **must** <behavior>.
- **FR‑2.** …

## Non‑Functional Requirements
- **NFR‑1.** …

## Data Model / Contracts
```lua
WinterChecklistDB = {
  -- new/changed fields only
}
```

## UX
- Screens/Flows: …
- Entry points: minimap, slash, keybind, options.
- Microcopy intent only; real text via i18n keys.

## Implementation Plan
- Touchpoints: file/path — reason
- Steps: (≤30 lines/file per step)

## i18n Keys (enUS intent)
```lua
L.FEATURE_TITLE = "..."
L.FEATURE_HELP  = "..."
```

## Acceptance & Tests
- ✅ FR‑1 verified by …
- Smoke/feature/edge matrix.
