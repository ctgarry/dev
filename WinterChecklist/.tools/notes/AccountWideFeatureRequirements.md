# 🧭 Account-Wide Tasks — Functional Requirements

## 1️⃣ Core Purpose
Let players choose — **per character** — whether their tasks are stored in a **shared account-wide list** or in that character’s personal list.

---

## 2️⃣ Data Model

| Element | Purpose |
|----------|----------|
| `WinterChecklistDB.chars[Name-Realm]` | Each character’s personal record (`tasks`, `settings`, `useAccount`) |
| `WinterChecklistDB.sharedList.tasks`  | The single shared account-wide task list |
| `WinterChecklistDB.sharedList.optIn`  | Map of characters that have account-wide mode enabled |
| `WinterChecklistDB.sharedList.seeded` | Marks characters that have already completed the seeding prompt |

---

## 3️⃣ Behavior Summary

- **Opt-in, not global:** Each character can enable/disable account-wide mode independently.  
- **Shared state:** All opted-in characters see and modify the same shared task list.  
- **Switch safety:**  
  - Turning *on* account-wide never erases personal data.  
  - Turning *off* simply returns the character to its personal list; shared data remains untouched.  
- **Legacy safety:** The old `WinterChecklistDB.accountWide` flag may exist but is now read-only compatibility only.

---

## 4️⃣ First-Enable Seeding Prompt

When a character first enables account-wide and has personal tasks:

Prompt user:

> “Seed account-wide tasks from this character?”

Buttons:
- **Copy** → replace the shared list with this character’s tasks.  
- **Merge** → combine both lists, deduplicating by task text.  
- **Skip** → leave shared list unchanged.  
- **Cancel / Esc** → abort toggle; leave mode off.

---

## 5️⃣ UI Expectations

- **Checkbox:** “Account-wide Tasks” toggles per-character opt-in.  
- **Title badge:** Frame title shows `(Account-wide)` or `(Character)` to clarify active mode.  
- **Tooltip:** Hovering the badge explains which list is in use.  
- **Help (?) button:** On the options panel, displays localized popup:

  ```
  When enabled, tasks are read/written to a single shared list.
  • Opt-in per character
  • Personal lists remain intact
  • First enable lets you Copy or Merge
  • Disabling restores personal list
  • No data is ever deleted automatically
  ```

- **Localization:** All text lives in `local/enUS.lua` (and other locales as added).

---

## 6️⃣ Notifications & Feedback

- `/print` feedback when Copy/Merge actions occur.  
- Silent (no spam) when simply toggling on/off.  
- Optional toast or chat messages can use:
  - `L.SHARED_SEED_COPY_DONE`, `L.SHARED_SEED_MERGE_DONE`, `L.SHARED_DISABLED`, etc.

---

## 7️⃣ Persistence & Migration

- SavedVariables update automatically on enable/disable.  
- Old `"Account-Wide"` key and `accountWide` flag are migrated on load if present.  
- No backwards-incompatible field deletions.

---

## 8️⃣ Acceptance Criteria

Codex should confirm:

- ✅ Each character can toggle account-wide independently.  
- ✅ Enabling triggers the correct seeding prompt and actions.  
- ✅ Disabling leaves the personal list intact.  
- ✅ Shared list persists across alts and reloads.  
- ✅ Title badge, tooltips, and help popup behave per spec.  
- ✅ No Lua errors or lost data after toggling and relogging.  
- ✅ All new strings are localized.

---

**Use this with Codex:**

> “Codex, verify whether the current code satisfies all these functional requirements. Then, generate or update in-game documentation and help text accordingly.”
