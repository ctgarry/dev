# WinterChecklist – Bug & Observation Log

_Status: Build 022 (Classic Era reload test)_

## Outstanding Issues

### Layout & Styling
- [x] **High** - Footer data actions (Clear/Export/Import) should live in Options, not on the main window.
- [x] **Medium** - ScrollFrame needs a visible scrollbar alongside mouse wheel support.
- [x] **Medium** - Parchment should fill edge-to-edge; remove remaining black gutters/transparent seams.
- [x] **Medium** - Nested container borders are showing mid-panel; flatten or hide redundant frames.
- [x] **Low** - Current edit quill reads as a horn/bugle; source a clearer pencil/quill icon.
- [ ] **Medium** - Footer action buttons clash (bold red) against parchment; restyle to match Blizzard theme.
- [x] **High** - Main window should not resize.
- [x] **Medium** - Main window border should match Blizzard dialog styling.
  - Marble background + dialog border with warm tint now style the shell.
- [x] **Medium** - Task row buttons were oversized and labels too verbose.
  - Compact icon/text buttons now handle edit/move/delete.
- [x] **Medium** - Frequency filter should use radio buttons under the search bar.
  - Inline radios + checkbox row replace the dropdown for faster filtering.
- [x] **Medium** - Marble backdrop/warm tint barely visible; central pane renders nearly black with transparent margins.
  - Added parchment inset with drop shadow so the list panel reads as parchment instead of solid black.
- [x] **Medium** - Default frame should mirror Blizzard dialog proportions (narrower/taller) with an Options toggle for "double-wide" display; keep frame non-resizable.
  - Frame now opens at Blizzard dialog scale with a new "Double-wide layout" option in the panel.
- [x] **Low** - Replace Edit text button with a Classic-safe pencil icon (current attempts draw a square fallback).
  - Swapped to the guild MOTD quill icon, applied via square button template for consistent theming.
- [x] **Low** - Delete button should use a lowercase `x` to match Blizzard microbuttons.
  - Updated localization to render the footer delete as a lowercase x.
- [x] **Medium** - Frequency radio row spacing overlaps labels and the "Incomplete only" checkbox.
  - Re-anchored the radio row so labels breathe and the checkbox sits clear of the last option.

### Interaction & UX
- [ ] **Medium** - Help popup should close on ESC.
  - Hook keyboard handler or reuse Blizzard close behavior.
- [ ] **Medium** - All addon popups should close via ESC.
  - Ensure U.ShowTextPopup / U.Confirm respect escape bindings.
- [ ] **Medium** - Opening Blizzard windows should dismiss addon popups.
  - Listen for frame show events and hide active popups.
- [ ] **High** - Add button ignores task frequency (daily/weekly never apply).
  - Captured tasks need to persist chosen frequency so filters reflect daily/weekly items.
- [ ] **High** - Footer import/export/clear actions belong in Options, not on the main window.
  - Move data management to the settings panel; keep in-frame controls focused on task manipulation.
- [ ] **Feature** - Add a footer "Reset Tasks" button that asks Daily / Weekly / All, then unchecks matching tasks.
- [ ] **Medium** - Import popup layout feels disconnected (prompt outside the multiline field).
  - Restyle so instructions live inside or visually align with the textbox.
- [ ] **Feature** - Import/Export should enforce choosing Plain Text vs JSON before enabling commit.
  - Add radio buttons; plaintext mode requires multiline input and matching serializer.
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
- Export popup now uses a multi-line edit box for easier copy/paste.
- Import flow trims pasted data, prompts for merge vs replace, and reports success/failure.
- Resize grabber removed; frame clamps to styled default dimensions.
- Marble background + dialog border with warm tint now drive the shell.
- Rebuilt action cluster with compact icons/tooltips for edit/move/delete.
- Inline radios + checkbox row replace the dropdown for faster filtering.
- Task data actions now live in Options (clear/export/import) instead of the main footer.
- ScrollFrame shows a visible scrollbar alongside mouse wheel scrolling.
- Parchment background fills edge-to-edge without black gutters or extra borders.

