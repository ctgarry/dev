# WinterChecklist – Bug & Observation Log

_Status: Build 022 (Classic Era reload test)_

## Outstanding Issues

### Layout & Styling
- [ ] **High** - UPDATED: Main window should not resize.
- [ ] **Medium** - Main window border should match Blizzard dialog styling.
  - Swap to standard backdrop/art or adjust C.BACKDROP.
- [ ] **Medium** - Task row buttons are oversized and labels too verbose.
  - Tighten widths and shorten text (e.g., icons or shorter verbs).
  - need alternate UI for up/down that takes less space.
- [ ] **Medium** - Frequency filter should use radio buttons under the search bar.
  - Replace dropdown with inline All/Daily/Weekly radio group for faster toggles.

### Interaction & UX
- [ ] **Medium** - Help popup should close on ESC.
  - Hook keyboard handler or reuse Blizzard close behavior.
- [ ] **Medium** - All addon popups should close via ESC.
  - Ensure U.ShowTextPopup / U.Confirm respect escape bindings.
- [ ] **Medium** - Opening Blizzard windows should dismiss addon popups.
  - Listen for frame show events and hide active popups.
- [x] **Medium** - /wcl export popup renders as single-line text.
  - Export popup now uses a multi-line edit box for easier copy/paste.
- [x] **High** - /wcl import prompt accepts text but list stays unchanged.
  - Import flow trims pasted data, prompts for merge vs replace, and reports success/failure.
- [ ] **Feature** - Add bottom-left zone button that opens the world map.
  - Use current zone label and call ToggleWorldMap() (Classic-safe).

### Data, Profiles & Localization
- [ ] **High** – Copying tasks lists the current character and wipes tasks.
  - Exclude active profile from copy targets; guard against self-copy.
- [ ] **Medium** – "Account-wide" appears as a character entry and clears the list.
  - Clarify account-wide handling vs. character profiles.
- [ ] **Medium** – Toggling Account-wide should refresh available profiles.
  - Regenerate dropdown contents after checkbox changes.
- [ ] **Medium** – Copying tasks should confirm before overwriting.
  - Present summary dialog before applying copy.

## Confirmed Successes
- No Lua errors on load or reload.
- Window position and task data persist correctly.
- Minimap button (visibility toggle, shift-debug) works end-to-end.
- Options panel sanity checks passed: show minimap, enable debug, 
    show help button, play sound feedback, open main window.
- Help button offset; no longer collides with close box.
- Toolbar rebuilt; footer now houses Add/Import/Export buttons.
- Reduced top offset so header sits closer to the title bar.
- Localized label added above search field.
- Footer row added with spaced action buttons.
- ScrollFrame now contains rows; long lists stay within frame.
- Completed rows tint grey to visually separate done items.
- Short “X” clear button sits next to the search field.
- Shared confirm dialog helper implemented to back clear/delete prompts.
- Layout uncluttered; footer buttons respond as expected.
- Added short labels for footer/actions and move buttons to enUS.
- Header clear now only empties the search box; footer button handles task wipe with confirm.
