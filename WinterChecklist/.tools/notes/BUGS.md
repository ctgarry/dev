# WinterChecklist – Bug & Observation Log

_Status: Build 022 (Classic Era reload test)_

## Outstanding Issues

### Layout & Styling
- [x] **High** - Main window does not resize.
  - Frame now exposes resize grabber (bottom-right) and clamps to min/max dimensions.
- [ ] **Medium** - Main window border should match Blizzard dialog styling.
  - Swap to standard backdrop/art or adjust C.BACKDROP.
- [x] **High** - Help (?) button overlaps the close (X) button.
  - Help button offset; no longer collides with close box.
- [ ] **Medium** - Task row buttons are oversized and labels too verbose.
  - Tighten widths and shorten text (e.g., icons or shorter verbs).
- [x] **High** - Filter box is blocked by Export/Import/Add buttons.
  - Toolbar rebuilt; footer now houses Add/Import/Export buttons.
- [x] **Medium** - Excess gap between title and first control.
  - Reduced top offset so header sits closer to the title bar.
- [x] **Low** - Add a Filter: label above the search box.
  - Localized label added above search field.
- [x] **High** - Export/Import/Add buttons should live at the bottom of the frame.
  - Footer row added with spaced action buttons.
- [x] **High** - Task list needs its own overflow/scroll region.
  - ScrollFrame now contains rows; long lists stay within frame.
- [ ] **Medium** - Frequency filter should use radio buttons under the search bar.
  - Replace dropdown with inline All/Daily/Weekly radio group for faster toggles.

### Interaction & UX
- [x] **Medium** - Checking a task should dim its text.
  - Completed rows tint grey to visually separate done items.
- [ ] **Medium** - Help popup should close on ESC.
  - Hook keyboard handler or reuse Blizzard close behavior.
- [ ] **Medium** - All addon popups should close via ESC.
  - Ensure U.ShowTextPopup / U.Confirm respect escape bindings.
- [ ] **Medium** - Opening Blizzard windows should dismiss addon popups.
  - Listen for frame show events and hide active popups.
- [x] **Low** - Clear button should be labeled X beside the filter box.
  - Short “X” clear button sits next to the search field.
- [x] **High** - First use of Clear throws Lua error (NS.Util.Confirm nil).
  - Shared confirm dialog helper implemented to back clear/delete prompts.
- [x] **High** - Export/Import buttons are currently unclickable.
  - Layout uncluttered; footer buttons respond as expected.
- [ ] **High** - Clear button should reset the search box instead of wiping tasks.
  - Move mass-clear into a separate action; this button should only empty the text filter.
- [ ] **Medium** - /wcl export popup renders as single-line text.
  - Replace with multiline, copy-friendly edit box.
- [ ] **High** - /wcl import prompt accepts text but list stays unchanged.
  - Forward input to Tasks:ImportWithPrompt and refresh UI.
- [ ] **Feature** - Add bottom-left zone button that opens the world map.
  - Use current zone label and call ToggleWorldMap() (Classic-safe).

### Data, Profiles & Localization
- [x] **Medium** - Task button text relies on missing localization keys.
  - Added short labels for footer/actions and move buttons to enUS.
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
- Options panel sanity checks passed: show minimap, enable debug, show help button, play sound feedback, open main window.
