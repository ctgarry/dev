# 03-data-model — Entities & Contracts

## Entities
- **Pet**
  - `petId` (string/int) — unique.
  - `nameKey` (i18n key), `displayName` (for current locale).
  - `family` (e.g., Beast, Mechanical), `rarity`, `source` (drop/vendor/quest).
  - `aliases[]` (lowercase).
  - `tags[]` (tagKey).
- **Tag**
  - `tagKey` (slug), `group` (mood/theme/type/seasonal/biome), `weightDefault` (0..1), `aliases[]`, `definitionKey`.
- **Bookmark**
  - `id` (uuid), `name`, `tagKeys[]`, `logicMode` (AND|OR), `scope` (OWNED|UNOWNED|ALL), `sort` (enum), `layoutSeed` (int), `notes?`.
  - `createdAt`, `updatedAt`, `uses` (counter).
- **Share**
  - `bookmarkId`, `accountScope` (true), `lastSyncedAt`.
- **ExportBlob (v1)**
  - `v`=1, `name`, `tagKeys[]`, `logic`, `scope`, `sort`, `seed`, `checksum`.

## Derived Structures
- **CloudNode**
  - `tagKey`, `countInScope`, `weight` (function of frequency × recency × default), `selected` (bool).
- **ResultSet**
  - `petIds[]`, `total`, `appliedFilters` (tags + search + scope).

## Storage
- **SavedVariables**
  - `PetCloud_CatalogVersion`
  - `PetCloud_Bookmarks[]`
  - `PetCloud_UsageStats{ tagKey: count }`
  - `PetCloud_LastLayoutSeed`

## Migration
- v0 → v1: initialize all structures; set catalog version and seed defaults.

## Back-compat
- Unknown fields **must** be ignored; version guard on import **must** downgrade gracefully when possible.
