# WinterChecklist – Bug & Observation Log

_Status: Build 022 (Classic Era reload test)_

## Outstanding Issues

### Layout & Styling
- [ ] **Medium** - Footer action buttons clash (bold red) against parchment; restyle to match Blizzard theme.
- [ ] **Medium** - Inner parchment still shows dark stone texture; fill should span edge-to-edge.
- [ ] **Medium** - Filter bar styling feels unfinished; clear button should match parchment theme.
- [ ] **Medium** - "Incomplete only" checkbox is misaligned; keep inline with frequency radios.
- [ ] **Medium** - Task row icons need distinct art; current yellow buttons read identical.
- [ ] **Medium** - Shift row action cluster right to free width for task text.
- [ ] **Medium** - Primary Add button needs palette aligned with parchment theme.
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
- Flattened inner borders so only the parchment panel remains.
- Edit button uses a Classic-safe quill icon.
- Delete buttons now show lowercase x styling.
- Frequency radios spaced cleanly; checkbox no longer overlaps.
- Default frame matches Blizzard dialog with double-wide toggle.



