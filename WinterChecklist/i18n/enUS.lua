--[[
  @file    i18n/enUS.lua
  @brief   American English strings. Missing keys fall back to key name.
]]
local _, NS = ...
local L = {}
NS.L = setmetatable(L, {
  __index = function(_, k)
    return k
  end,
})

-- General
L.ADDON_NAME = "WinterChecklist"
L.OK = "OK"
L.CANCEL = "Cancel"
L.CLOSE = "Close"
L.HELP = "Help"
L.DEBUG_ENABLED = "Debug enabled."
L.DEBUG_DISABLED = "Debug disabled."
L.FILTER_LABEL = "Filter:"
L.CLEAR_SHORT = "X"
L.DELETE_SHORT = "X"
L.OPEN_MAIN = "Open Main Window"
L.RESET = "Reset"
L.RESET_ALL = "Reset All"
L.CONFIRM = "Confirm"
L.YES = "Yes"
L.NO = "No"
L.EMPTY_STATE = "No tasks yet — click Add, or type: /wcl add <task>"
L.EMPTY_STATE_FILTERED = "No tasks match the current filters."

-- Options
L.OPT_PANEL_TITLE = L.ADDON_NAME
L.OPT_MINIMAP = "Show minimap icon"
L.OPT_ACCOUNT_WIDE = "Account-wide tasks"
L.OPT_ACCOUNT_WIDE_TT = "Use one checklist for all characters on this account (not per character)."
L.OPT_DEBUG = "Enable debug logging"
L.OPT_LOCK_FRAME = "Lock main window (disable drag)"
L.OPT_SHOW_HELP = "Show help button on main window"
L.OPT_FEEDBACK_SECTION = "Feedback"
L.MOVE_UP = "Up"
L.MOVE_DOWN = "Down"

-- Options (Sound)
L.OPT_SOUND_ON_ADD = "Play sound when adding a task"
L.OPT_SOUND_NONE = "None"
L.OPT_SOUND_SELECT = "Task-added sound"

-- Options (Profiles)
L.OPT_PROFILE = "Profile"
L.OPT_PROFILE_SECTION = L.OPT_PROFILE
L.OPT_PROFILE_COPY = "Copy tasks from another character"
L.OPT_FROM_CHARACTER = "From Character"
L.OPT_COPY_BUTTON = "Copy Tasks"
L.OPT_PROFILE_NEW = "New Profile"
L.OPT_PROFILE_RENAME = "Rename Profile"
L.OPT_PROFILE_DELETE = "Delete Profile"
L.OPT_PROFILE_COPIED = "Tasks copied from %s."
L.OPT_PROFILE_MERGED = "Tasks merged from %s."
L.OPT_PROFILE_DELETED = "Profile %s deleted."
L.OPT_CONFIRM_DELETE = "Are you sure you want to delete profile '%s'?"
L.OPT_CONFIRM_CLEAR = "Are you sure you want to clear all tasks?"
L.OPT_CONFIRM_CLEAR_ALL = "Are you sure you want to clear all tasks for all profiles?"
L.OPT_CONFIRM_DELETE_TASK = "Are you sure you want to delete the task '%s'?"

-- About panel
L.OPT_ABOUT_TITLE = "About"
L.OPT_ABOUT_INFO = "WinterChecklist helps you track tasks across characters with a lightweight, Classic-friendly UI."
L.OPT_ABOUT_USAGE = "Usage: Open the main window from the minimap icon or with /wcl."
L.OPT_ABOUT_SLASH = "Slash commands:\n  /wcl          — Open/close main window\n  /wcl options  — Open options"
L.OPT_ABOUT_CREDITS = "Credits: Christopher T Garry, contributors, and the WoW UI community."

-- Tasks
L.TASKS_HEADER = "Tasks"
L.TASKS_PLACEHOLDER = "Add a new task..."
L.TASKS_ADDED = "Task added: %s"
L.TASKS_REMOVED = "Task removed: %s"
L.TASKS_COPIED_FMT = "Copied tasks from %s."
L.TASKS_IMPORTED_FMT = "Imported %d tasks (%d new, %d updated, %d unchanged)."
L.TASKS_IMPORTED_INVALID = "Import failed: invalid data."
L.TASK_NOTES = "Task Notes"

-- Help
L.HELP_TITLE = "WinterChecklist Help"
L.HELP_SUMMARY_TITLE = "WinterChecklist — Quick Summary"
L.HELP_BUTTON = L.HELP
L.HELP_SUMMARY_BODY = "Track short checklist items per character. Resize the window, filter tasks up top, and use the footer buttons to add, import, or export tasks."
L.HELP_WELCOME =
  "Welcome to WinterChecklist! This addon helps you keep track of short checklist items per character, such as holiday event tasks, profession cooldowns, or other repeatable tasks."
L.HELP_USING = "Using WinterChecklist"
L.HELP_ADDING =
  "To add a new task, type it into the 'Add a new task...' box and press Enter or click the + button. The task will be added to your list."
L.HELP_EDITING =
  "To edit a task, click the pencil icon next to the task. Make your changes and click the checkmark to save or the X to cancel."
L.HELP_DELETING =
  "To delete a task, click the trash can icon next to the task. You will be asked to confirm the deletion."
L.HELP_MARKING = "To mark a task as complete or incomplete, click the checkbox next to the task."
L.HELP_FILTERING =
  "Use the filter buttons at the top to show all tasks, only daily tasks, only weekly tasks, only incomplete tasks, or only complete tasks. Click 'Reset' to clear all filters."
L.HELP_PROFILES =
  "Use the Profile section in Options to manage your profiles. You can create, rename, delete, copy, and merge profiles. Profiles allow you to maintain separate task lists for different characters or purposes."
L.HELP_IMPORT_EXPORT =
  "Use the Import/Export section in Options to back up or share your tasks. You can export your tasks to a text format and import them back. When importing, you can choose to merge with existing tasks or replace them entirely."
L.HELP_FEEDBACK = "Feedback and Support"
L.HELP_FEEDBACK_BODY =
  "If you have any questions, suggestions, or encounter any issues, please visit the addon's page on CurseForge or GitHub to leave feedback or report bugs. Your input is valuable and helps improve the addon!"
L.HELP_CLOSE = L.CLOSE
L.HELP_THANKS = "Thank you for using WinterChecklist! Happy task tracking!"

-- Task management (Filters)
L.FILTER_FREQ_ALL = "All"
L.FILTER_FREQ_DAILY = "Daily"
L.FILTER_FREQ_WEEKLY = "Weekly"
L.FILTER_INCOMPLETE = "Incomplete only"
L.FILTER_COMPLETE = "Filter Complete"
L.FILTER_RESET = "Filter Reset"
L.FILTER_SECTION = "Filters"

-- Task management (Buttons/Check Boxes)
L.CLEAR = "Clear"
L.CLEAR_SEARCH = "Clear Search"
L.CLEAR_TASKS = "Clear Tasks"
L.CLEAR_TASKS_TT = "Remove all tasks in the active profile."
L.CLEAR_ALL = "Clear all tasks?"
L.ADD_TASK = "Add Task"
L.EDIT_TASK = "Edit Task"
L.EDIT_SHORT = "Edit"
L.DELETE_TASK = "Delete Task"
L.MARK_COMPLETE = "Mark Complete"
L.MARK_INCOMPLETE = "Mark Incomplete"
L.MOVE_UP_SHORT = "Up"
L.MOVE_DOWN_SHORT = "Down"

-- Task management (Options)
L.TASK_FREQUENCY = "Task Frequency"
L.FREQ_DAILY = "Daily"
L.FREQ_WEEKLY = "Weekly"
L.FREQ_MONTHLY = "Monthly"
L.FREQ_YEARLY = "Yearly"
L.FREQ_ONE_TIME = "One Time"

-- EXPORT
L.EXPORT = "Export"
L.EXPORT_HEADER = "WinterChecklist Task Export"
L.EXPORT_TITLE = "Tasks Export"
L.EXPORT_READY = "Export string ready. Copy from the popup."
L.EXPORT_INSTRUCTIONS =
  "Copy the text below to export your tasks. To import tasks, paste the text into the import box and click Import."
L.EXPORT_DATA = "%s" -- The actual export data string
L.EXPORT_COPY_PROMPT =
  "Copy the text below to export your tasks. Use /wcl import to import tasks into another character."
L.EXPORT_COPY_BUTTON = "Copy to Clipboard"

-- EXPORT (results/messages)
L.EXPORT_DONE = "Export completed."
L.EXPORT_FAILED = "Export failed."
L.EXPORT_NO_TASKS = "No tasks to export."
L.EXPORT_COPIED = "Export data copied to clipboard."

-- IMPORT (appearance)
L.IMPORT = "Import"
L.IMPORT_HEADER = "WinterChecklist Task Import"
L.IMPORT_TITLE = "Import Tasks"
L.IMPORT_BUTTON = L.IMPORT
L.IMPORT_MERGE_BUTTON = "Merge"
L.IMPORT_MERGE = "Merge"
L.IMPORT_REPLACE = "Replace"
L.IMPORT_CANCEL_BUTTON = L.CANCEL
L.IMPORT_INSTRUCTIONS =
  "Paste the exported text from another character here. Choose Import to merge with your current list, or Replace to overwrite it."
L.IMPORT_REPLACE_BUTTON = L.IMPORT_REPLACE
L.IMPORT_MERGE_OR_REPLACE = "Import: merge with existing tasks or replace them?"
L.IMPORT_CONFIRM_REPLACE = "This will replace all existing tasks. Are you sure?"
L.IMPORT_CONFIRM_MERGE = "This will merge with existing tasks. Are you sure?"
L.IMPORT_REPLACED_FMT = "Imported %d tasks (%d new, %d updated, %d unchanged). Removed %d existing tasks."
L.IMPORT_PASTE_HERE = "Paste the exported task data here:"

-- IMPORT (results/messages)
L.IMPORT_DONE = "Import completed."
L.IMPORT_OK_FMT = "Imported %d tasks."
L.IMPORT_SUCCESS = L.TASKS_IMPORTED_FMT
L.IMPORT_CANCELLED = "Import cancelled."
L.IMPORT_INVALID_DATA = "Invalid import data."
L.IMPORT_NO_DATA = "No data to import."
L.IMPORT_NO_TASKS = "No tasks found to import."
L.IMPORT_NOTHING_TO_IMPORT = "Nothing to import."
L.IMPORT_NOTHING_TO_REPLACE = "Nothing to replace."
L.IMPORT_NOTHING_TO_MERGE = "Nothing to merge."
L.IMPORT_FAILED = "Import failed. Double-check the pasted text."
L.IMPORT_INVALID = L.TASKS_IMPORTED_INVALID
L.IMPORT_TOO_MANY_TASKS = "Import failed: too many tasks."
L.IMPORT_TOO_LARGE = "Import failed: data too large."
L.IMPORT_UNSUPPORTED_VERSION = "Import failed: unsupported version."
L.IMPORT_VERSION_MISMATCH = "Import failed: version mismatch."
L.IMPORT_CORRUPT_DATA = "Import failed: corrupt data."
L.IMPORT_UNEXPECTED_ERROR = "Import failed: unexpected error."

-- IMPORT SUCCESS (results/messages)
L.IMPORT_SUCCESS_NO_CHANGES = "Import completed: no changes made."
L.IMPORT_SUCCESS_SOME_CHANGES = "Import completed: some changes made."
L.IMPORT_SUCCESS_ALL_CHANGES = "Import completed: all tasks updated."
L.IMPORT_SUCCESS_NEW_TASKS = "Import completed: new tasks added."
L.IMPORT_SUCCESS_UPDATED_TASKS = "Import completed: existing tasks updated."
L.IMPORT_SUCCESS_UNCHANGED_TASKS = "Import completed: unchanged tasks."

-- IMPORT SUCCESS (total tasks) (results/messages)
L.IMPORT_SUCCESS_TOTAL_TASKS = "Import completed: total tasks now %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_NO_CHANGE = "Import completed: total tasks remain %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_CHANGED = "Import completed: total tasks changed to %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_ADDED = "Import completed: total tasks increased to %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_REMOVED = "Import completed: total tasks decreased to %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_UNCHANGED = "Import completed: total tasks unchanged at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_UPDATED = "Import completed: total tasks updated to %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_NEW = "Import completed: total tasks new at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_EXISTING = "Import completed: total tasks existing at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_MERGED = "Import completed: total tasks merged to %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_REPLACED = "Import completed: total tasks replaced to %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_SKIPPED = "Import completed: total tasks skipped at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_FAILED = "Import completed: total tasks failed at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_SUCCEEDED = "Import completed: total tasks succeeded at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_PROCESSED = "Import completed: total tasks processed at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_IGNORED = "Import completed: total tasks ignored at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_DUPLICATE = "Import completed: total tasks duplicate at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_INVALID = "Import completed: total tasks invalid at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_VALID = "Import completed: total tasks valid at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_IMPORTED = "Import completed: total tasks imported at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_NOT_IMPORTED = "Import completed: total tasks not imported at  %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_ALREADY_EXIST = "Import completed: total tasks already exist at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_NEWLY_IMPORTED = "Import completed: total tasks newly imported at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_UPDATED_IMPORTED = "Import completed: total tasks updated during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_UNCHANGED_IMPORTED = "Import completed: total tasks unchanged during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_SKIPPED_IMPORTED = "Import completed: total tasks skipped during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_FAILED_IMPORTED = "Import completed: total tasks failed during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_SUCCEEDED_IMPORTED = "Import completed: total tasks succeeded during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_PROCESSED_IMPORTED = "Import completed: total tasks processed during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_IGNORED_IMPORTED = "Import completed: total tasks ignored during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_DUPLICATE_IMPORTED = "Import completed: total tasks duplicate during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_INVALID_IMPORTED = "Import completed: total tasks invalid during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_VALID_IMPORTED = "Import completed: total tasks valid during import at %d."
L.IMPORT_SUCCESS_TOTAL_TASKS_ALREADY_EXIST_IMPORTED = "Import completed: total tasks already exist during import at %d."

-- Slash / help
L.SLASH_HEADER = "Slash commands:"
L.SLASH_TOGGLE = "/wcl toggle      - Show/hide the main window"
L.SLASH_DEBUG = "/wcl debug       - Toggle debug logging"
L.SLASH_MINIMAP = "/wcl minimap     - Toggle the minimap icon"
L.SLASH_OPTIONS = "/wcl options     - Open the options dialog"
L.SLASH_HELP = "/wcl help        - Show this help message"
L.SLASH_IMPORT = "/wcl import      - Open the import dialog"
L.SLASH_EXPORT = "/wcl export      - Open the export dialog"
L.SLASH_PROFILE = "/wcl profile     - Profile management commands"
L.SLASH_RESET = "/wcl reset       - Clear all tasks (confirm)"
L.SLASH_RESET_ALL = "/wcl reset all   - Clear all tasks for all profiles (confirm)"
L.SLASH_LIST = "/wcl list        - List all tasks in chat"
L.SLASH_HELP2 = L.SLASH_HELP
L.SLASH_NOT_FOUND = "Unknown command. Type /wcl help for a list of commands."
L.SLASH_NOT_FOUND_USAGE = L.SLASH_NOT_FOUND
L.SLASH_PROFILE_NOT_FOUND = "Profile '%s' not found."
L.SLASH_PROFILE_LIST = "Available profiles: %s"
L.SLASH_PROFILE_CURRENT = "Current profile: %s"
L.SLASH_CLEAR_CONFIRM =
  "Are you sure you want to clear all tasks? This cannot be undone. Type /wcl reset all to clear tasks for all profiles."
L.SLASH_CLEAR_ALL_CONFIRM =
  "Are you sure you want to clear all tasks for all profiles? This cannot be undone. Type /wcl reset all to confirm."

L.SLASH_LIST_HEADER = "Tasks for profile '%s':"
L.SLASH_LIST_EMPTY = "No tasks found."
L.SLASH_LIST_ITEM = "- [%s] %s %s" -- [x] Task Name (Freq)
L.SLASH_LIST_ITEM_NOTES = "- [%s] %s %s - Notes: %s" -- [x] Task Name (Freq) - Notes: ...
L.SLASH_LIST_COMPLETE = "Complete"
L.SLASH_LIST_INCOMPLETE = "Incomplete"
L.SLASH_LIST_DAILY = L.FREQ_DAILY
L.SLASH_LIST_WEEKLY = L.FREQ_WEEKLY
L.SLASH_LIST_MONTHLY = L.FREQ_MONTHLY
L.SLASH_LIST_YEARLY = "Yearly"
L.SLASH_LIST_ONE_TIME = L.FREQ_ONE_TIME
L.SLASH_LIST_NO_NOTES = "No notes"

L.SLASH_IMPORT_MERGE_BUTTON = L.IMPORT_MERGE_BUTTON
L.SLASH_IMPORT_REPLACE_BUTTON = L.IMPORT_REPLACE_BUTTON
L.SLASH_IMPORT_BUTTON = L.IMPORT
L.SLASH_IMPORT_USAGE = "Import commands:\n"
  .. "/wcl import                     - Open the import dialog\n"
  .. "/wcl import merge <data>        - Import tasks from <data>, merging with existing tasks\n"
  .. "/wcl import replace <data>      - Import tasks from <data>, replacing existing tasks"
L.SLASH_IMPORT_INVALID = L.TASKS_IMPORTED_INVALID
L.SLASH_IMPORT_MERGED = L.TASKS_IMPORTED_FMT
L.SLASH_IMPORT_PROMPT = L.IMPORT_PASTE_HERE
L.SLASH_IMPORT_REPLACED = L.IMPORT_REPLACED_FMT
L.SLASH_IMPORT_SUCCESS = L.TASKS_IMPORTED_FMT
L.SLASH_IMPORT_NO_DATA = L.IMPORT_NO_DATA
L.SLASH_IMPORT_MERGE_OR_REPLACE = L.IMPORT_MERGE_OR_REPLACE

L.SLASH_EXPORT_HEADER = "Exported tasks for profile '%s':"
L.SLASH_EXPORT_FOOTER = "Use /wcl import to import these tasks into another character."
L.SLASH_EXPORT_EMPTY = L.EXPORT_NO_TASKS
L.SLASH_EXPORT_DATA = L.EXPORT_DATA
L.SLASH_EXPORT_PROMPT = L.EXPORT_COPY_PROMPT

L.SLASH_PROFILE_USAGE = "Profile commands:\n"
  .. "/wcl profile list               - List all profiles\n"
  .. "/wcl profile current            - Show current profile\n"
  .. "/wcl profile switch <name>      - Switch to profile <name>\n"
  .. "/wcl profile new <name>         - Create a new profile <name>\n"
  .. "/wcl profile rename <old> <new> - Rename profile <old> to <new>\n"
  .. "/wcl profile delete <name>      - Delete profile <name> (confirm)\n"
  .. "/wcl profile copy <char>        - Copy tasks from character <char>\n"
  .. "/wcl profile merge <char>       - Merge tasks from character <char>"
L.SLASH_PROFILE_DELETE_CONFIRM = "Are you sure you want to delete profile '%s'? This cannot be undone."
L.SLASH_PROFILE_DELETED = "Profile '%s' deleted."
L.SLASH_PROFILE_CREATED = "Profile '%s' created and switched to."
L.SLASH_PROFILE_RENAMED = "Profile '%s' renamed to '%s'."
L.SLASH_PROFILE_SWITCHED = "Switched to profile '%s'."
L.SLASH_PROFILE_COPIED = "Tasks copied from character '%s'."
L.SLASH_PROFILE_MERGED = "Tasks merged from character '%s'."
L.SLASH_PROFILE_ALREADY_EXISTS = "Profile '%s' already exists."
L.SLASH_PROFILE_NO_CHAR = "Character '%s' not found or has no tasks."
L.SLASH_PROFILE_SAME = "You are already using profile '%s'."
L.SLASH_PROFILE_LIST_EMPTY = "No profiles found."
L.SLASH_PROFILE_LIST_HEADER = "Available profiles:"
L.SLASH_PROFILE_LIST_ITEM = "- %s%s" -- - ProfileName (current)
L.SLASH_PROFILE_CURRENT_ITEM = "%s (current)" -- ProfileName (current)
L.SLASH_PROFILE_NOTES = "Use the Profile section in Options to manage profiles."

L.SLASH_EXPORT_USAGE = "Use /wcl export to export your tasks to a text format."
L.SLASH_EXPORT_INSTRUCTIONS = "Copy the exported text and use /wcl import to import tasks into another character."

L.SLASH_RESET_USAGE = "Reset commands:\n"
  .. "/wcl reset                     - Clear all tasks (confirm)\n"
  .. "/wcl reset all                 - Clear all tasks for all profiles (confirm)"
L.SLASH_RESET_CONFIRM = L.SLASH_CLEAR_CONFIRM
L.SLASH_RESET_ALL_CONFIRM = L.SLASH_CLEAR_ALL_CONFIRM
L.SLASH_RESET_DONE = "All tasks cleared."
L.SLASH_RESET_ALL_DONE = "All tasks for all profiles cleared."

L.SLASH_HELP_USAGE = "Type /wcl help to see this message."
L.SLASH_TOGGLE_USAGE = "Use /wcl toggle to show or hide the main window."
L.SLASH_DEBUG_USAGE = "Use /wcl debug to toggle debug logging."
L.SLASH_MINIMAP_USAGE = "Use /wcl minimap to toggle the minimap icon."
L.SLASH_OPTIONS_USAGE = "Use /wcl options to open the options dialog."
L.SLASH_LIST_USAGE = "Use /wcl list to list all tasks in chat."
L.SLASH_NO_TASKS = L.SLASH_LIST_EMPTY

L.SLASH_TASKS_USAGE = "Task commands:\n"
  .. "/wcl add <task> [freq] [notes]    - Add a new task with optional frequency and notes\n"
  .. "/wcl remove <task>                - Remove a task\n"
  .. "/wcl complete <task>              - Mark a task as complete\n"
  .. "/wcl incomplete <task>            - Mark a task as incomplete\n"
  .. "/wcl edit <old> <new> [freq] [notes] - Edit a task's name, frequency, and notes"
L.SLASH_TASKS_HEADER = L.SLASH_LIST_HEADER
L.SLASH_TASKS_ITEM = L.SLASH_LIST_ITEM
L.SLASH_TASKS_ITEM_NOTES = L.SLASH_LIST_ITEM_NOTES
L.SLASH_TASKS_COMPLETE = L.SLASH_LIST_COMPLETE
L.SLASH_TASKS_INCOMPLETE = L.SLASH_LIST_INCOMPLETE
L.SLASH_TASKS_DAILY = L.FREQ_DAILY
L.SLASH_TASKS_WEEKLY = L.FREQ_WEEKLY
L.SLASH_TASKS_MONTHLY = L.FREQ_MONTHLY
L.SLASH_TASKS_YEARLY = L.SLASH_LIST_YEARLY
L.SLASH_TASKS_ONE_TIME = L.FREQ_ONE_TIME
L.SLASH_TASKS_NO_NOTES = L.SLASH_LIST_NO_NOTES
L.SLASH_TASKS_ADDED = L.TASKS_ADDED
L.SLASH_TASKS_REMOVED = L.TASKS_REMOVED
L.SLASH_TASKS_MARKED_COMPLETE = "Task marked complete: %s"
L.SLASH_TASKS_MARKED_INCOMPLETE = "Task marked incomplete: %s"
L.SLASH_TASKS_EDITED = "Task edited: %s"
L.SLASH_TASKS_NOT_FOUND = "Task '%s' not found."
L.SLASH_TASKS_ADDED_FMT = L.TASKS_ADDED
L.SLASH_TASKS_REMOVED_FMT = L.TASKS_REMOVED
L.SLASH_TASKS_MARKED_COMPLETE_FMT = L.SLASH_TASKS_MARKED_COMPLETE
L.SLASH_TASKS_MARKED_INCOMPLETE_FMT = L.SLASH_TASKS_MARKED_INCOMPLETE
L.SLASH_TASKS_EDITED_FMT = L.SLASH_TASKS_EDITED
L.SLASH_TASKS_NOT_FOUND_FMT = L.SLASH_TASKS_NOT_FOUND
L.SLASH_TASKS_INVALID_FREQ = "Invalid frequency. Valid options are: daily, weekly, monthly, yearly, one-time."
L.SLASH_TASKS_NO_NAME = "Task name cannot be empty."
L.SLASH_TASKS_USAGE_DETAILS = L.SLASH_TASKS_USAGE
L.SLASH_TASKS_NO_TASKS = L.SLASH_LIST_EMPTY

L.SLASH_TASKS_LIST_HEADER = L.SLASH_LIST_HEADER
L.SLASH_TASKS_LIST_EMPTY = L.SLASH_LIST_EMPTY
L.SLASH_TASKS_LIST_ITEM = L.SLASH_LIST_ITEM
L.SLASH_TASKS_LIST_ITEM_NOTES = L.SLASH_LIST_ITEM_NOTES
L.SLASH_TASKS_LIST_COMPLETE = L.SLASH_LIST_COMPLETE
L.SLASH_TASKS_LIST_INCOMPLETE = L.SLASH_LIST_INCOMPLETE
L.SLASH_TASKS_LIST_DAILY = L.FREQ_DAILY
L.SLASH_TASKS_LIST_WEEKLY = L.FREQ_WEEKLY
L.SLASH_TASKS_LIST_MONTHLY = L.FREQ_MONTHLY
L.SLASH_TASKS_LIST_YEARLY = L.SLASH_LIST_YEARLY
L.SLASH_TASKS_LIST_ONE_TIME = L.FREQ_ONE_TIME
L.SLASH_TASKS_LIST_NO_NOTES = L.SLASH_LIST_NO_NOTES

L.SLASH_TASKS_FILTER_USAGE = "Filter commands:\n"
  .. "/wcl filter all            - Show all tasks\n"
  .. "/wcl filter daily          - Show only daily tasks\n"
  .. "/wcl filter weekly         - Show only weekly tasks\n"
  .. "/wcl filter incomplete     - Show only incomplete tasks\n"
  .. "/wcl filter complete       - Show only complete tasks\n"
  .. "/wcl filter reset          - Clear all filters"
L.SLASH_TASKS_FILTER_USAGE_DETAILS = L.SLASH_TASKS_FILTER_USAGE
L.SLASH_TASKS_FILTER_ALL = "Filter set to show all tasks."
L.SLASH_TASKS_FILTER_DAILY = "Filter set to show only daily tasks."
L.SLASH_TASKS_FILTER_WEEKLY = "Filter set to show only weekly tasks."
L.SLASH_TASKS_FILTER_INCOMPLETE = "Filter set to show only incomplete tasks."
L.SLASH_TASKS_FILTER_COMPLETE = "Filter set to show only complete tasks."
L.SLASH_TASKS_FILTER_RESET = "All filters cleared."
L.SLASH_TASKS_FILTER_INVALID = "Invalid filter. Valid options are: all, daily, weekly, incomplete, complete, reset."
L.SLASH_TASKS_FILTER_NO_TASKS = L.SLASH_LIST_EMPTY

L.SLASH_TASKS_FILTERED_LIST_HEADER = "Filtered tasks for profile '%s':"
L.SLASH_TASKS_FILTERED_LIST_EMPTY = L.SLASH_LIST_EMPTY
L.SLASH_TASKS_FILTERED_LIST_ITEM = L.SLASH_LIST_ITEM
L.SLASH_TASKS_FILTERED_LIST_ITEM_NOTES = L.SLASH_LIST_ITEM_NOTES
L.SLASH_TASKS_FILTERED_LIST_COMPLETE = L.SLASH_LIST_COMPLETE
L.SLASH_TASKS_FILTERED_LIST_INCOMPLETE = L.SLASH_LIST_INCOMPLETE
L.SLASH_TASKS_FILTERED_LIST_DAILY = L.FREQ_DAILY
L.SLASH_TASKS_FILTERED_LIST_WEEKLY = L.FREQ_WEEKLY
L.SLASH_TASKS_FILTERED_LIST_MONTHLY = L.FREQ_MONTHLY
L.SLASH_TASKS_FILTERED_LIST_YEARLY = L.SLASH_LIST_YEARLY
L.SLASH_TASKS_FILTERED_LIST_ONE_TIME = L.FREQ_ONE_TIME
L.SLASH_TASKS_FILTERED_LIST_NO_NOTES = L.SLASH_LIST_NO_NOTES

L.SLASH_TASKS_FILTERED_LIST_COUNT = "%d tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_EMPTY = L.SLASH_LIST_EMPTY
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY = "%d daily tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY = "%d weekly tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_INCOMPLETE = "%d incomplete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_COMPLETE = "%d complete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_INCOMPLETE = "%d daily incomplete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_INCOMPLETE = "%d weekly incomplete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_COMPLETE = "%d daily complete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_COMPLETE = "%d weekly complete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY = "%d monthly tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY = "%d yearly tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME = "%d one-time tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_INCOMPLETE = "%d monthly incomplete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_INCOMPLETE = "%d yearly incomplete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_INCOMPLETE = "%d one-time incomplete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_COMPLETE = "%d monthly complete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_COMPLETE = "%d yearly complete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_COMPLETE = "%d one-time complete tasks found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_NOTES = "%d tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_NO_NOTES = "%d tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_NOTES_INCOMPLETE = "%d incomplete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_NOTES_COMPLETE = "%d complete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_NO_NOTES_INCOMPLETE = "%d incomplete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_NO_NOTES_COMPLETE = "%d complete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_NOTES = "%d daily tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_NO_NOTES = "%d daily tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_NOTES = "%d weekly tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_NO_NOTES = "%d weekly tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_NOTES = "%d monthly tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_NO_NOTES = "%d monthly tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_NOTES = "%d yearly tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_NO_NOTES = "%d yearly tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_NOTES = "%d one-time tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_NO_NOTES = "%d one-time tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_INCOMPLETE_NOTES = "%d daily incomplete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_INCOMPLETE_NO_NOTES = "%d daily incomplete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_COMPLETE_NOTES = "%d daily complete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_DAILY_COMPLETE_NO_NOTES = "%d daily complete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_INCOMPLETE_NOTES = "%d weekly incomplete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_INCOMPLETE_NO_NOTES = "%d weekly incomplete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_COMPLETE_NOTES = "%d weekly complete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_WEEKLY_COMPLETE_NO_NOTES = "%d weekly complete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_INCOMPLETE_NOTES = "%d monthly incomplete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_INCOMPLETE_NO_NOTES = "%d monthly incomplete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_COMPLETE_NOTES = "%d monthly complete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_MONTHLY_COMPLETE_NO_NOTES = "%d monthly complete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_INCOMPLETE_NOTES = "%d yearly incomplete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_INCOMPLETE_NO_NOTES = "%d yearly incomplete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_COMPLETE_NOTES = "%d yearly complete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_YEARLY_COMPLETE_NO_NOTES = "%d yearly complete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_INCOMPLETE_NOTES = "%d one-time incomplete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_INCOMPLETE_NO_NOTES = "%d one-time incomplete tasks without notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_COMPLETE_NOTES = "%d one -time complete tasks with notes found."
L.SLASH_TASKS_FILTERED_LIST_COUNT_ONE_TIME_COMPLETE_NO_NOTES = "%d one-time complete tasks without notes found."
