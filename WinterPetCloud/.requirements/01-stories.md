# 01-stories — User Stories (MoSCoW + AC)

## Must
- **US-1 (Browse by mood):** As a collector, I want a mood-based tag cloud so I can quickly narrow pets to match an activity.
  - **AC:** Given the addon is open, when I click one mood tag (e.g., *cozy*), the result list must update within 150 ms and display only pets matching that tag.
- **US-2 (Multi-tag winnow):** As a user, I want to click multiple tags to progressively narrow results.
  - **AC:** When two or more tags are active, results must satisfy logical AND by default (configurable to OR).
- **US-3 (Own/All toggle):** As a user, I want to toggle between Owned, Unowned, and All.
  - **AC:** The toggle must re-calculate tag weights and counts to reflect the chosen scope.
- **US-4 (Bookmark cloud):** As a curator, I want to save a selected tag set as a bookmark.
  - **AC:** When I click “Save Bookmark,” the system must persist the tag set, scope, sort, and layout seed under a user-provided name.
- **US-5 (Share across account):** As a player with multiple characters, I want bookmarks to sync across my account.
  - **AC:** Bookmarks saved on one character must appear on other characters on the same account after reload/login.
- **US-6 (Export/Import):** As a user, I want to export a bookmark to a compact string and import it later.
  - **AC:** Export must produce a deterministic, checksum-validated string ≤ 512 chars; Import must validate and preview before applying.
- **US-7 (Complete catalog):** As a newcomer, I want the addon to “know all pets” immediately upon install.
  - **AC:** A bundled catalog file must include every known pet id, name, source, and tag mappings as of the addon version.
- **US-8 (Responsive tag cloud):** As a user, I want the cloud to visually weight tags by relevance.
  - **AC:** The UI must display top-N tags sized/ordered by frequency within the current result scope and viewport constraints.

## Should
- **US-9 (Quick-pick microframe):** As a raider, I want a minimal popout with the last-used bookmark and 1-click summon.
- **US-10 (Alias/hover help):** As a user, I want tag tooltip hints showing definitions and aliases.

## Could
- **US-11 (Share via QR):** As an event host, I want a QR representing the export string for easy sharing.
- **US-12 (Presets by activity):** As a user, I want prebuilt bookmark presets (e.g., Roleplay, Raid, Seasonal).

## Won’t (this iteration)
- **US-13:** Cloud-generated recommendations using ML.
