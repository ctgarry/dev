# 00-charter — Pet Tag Cloud Addon

## Problem
Players own large collections of pets but lack a fast, consistent way to filter by *mood* or other nuanced attributes. Existing UIs rely on rigid categories or search strings and do not leverage best-practice tag clouds for progressive narrowing.

## Vision
A lightweight addon that: (1) ships with a complete, offline catalog of all known pets at install time, (2) auto-detects the user’s owned pets, and (3) presents a responsive tag cloud that winnows candidates by mood/intent (e.g., “cozy”, “festive”, “aquatic”, “battle-ready”). Chosen tag sets are bookmarkable, shareable across the account, and exportable/importable.

## Goals
- Provide an at-a-glance tag cloud that *adapts* to the user’s inventory while retaining visibility into unowned pets.
- Use widely-accepted tag cloud best practices to narrow large datasets with low cognitive load.
- Enable saving, exporting/importing, and cross-account sharing of useful tag clouds (query states).

## Non-Goals
- Creating new pet acquisition content or altering drop sources.
- Real-time network crawling for catalog data (initial catalog is bundled; updates arrive via normal addon release flow).
- Replacing native pet journal; this is an augmenting layer.

## Personas
- **Collector Carla** — owns 500+ pets; wants quick “mood-fit” picks before raids or roleplay.
- **Newcomer Nico** — small collection; wants guidance and discoverability.
- **Curator Quinn** — organizes themed events; needs shareable, stable filters.

## Scope
- Tag cloud UI embedded in addon frame and optional micro-frame for quick-pick.
- Bookmarks (local), Account Shares (sync via saved variables across characters on same account), and Export/Import (string blob/QR).
- Search + tag cloud interplay (search narrows term-wise; cloud handles categorical/mood facets).

## Constraints
- Must function fully offline after install.
- Saved variables size should remain within platform norms.
- All strings routed through i18n keys.

## Success Metrics
- TTFP (time to first pet) under 5 seconds from opening the frame for collections >300.
- ≥90% of common moods discoverable within two tag clicks.
- Bookmark recall <100 ms for collections up to 1,000 pets.

## Risks & Mitigations
- **Stale catalog:** Ship versioned catalog; show “catalog age” notice; allow delta updates in later iterations.
- **Tag bloat:** Curate a controlled vocabulary and expose aliasing; show top-N weighted tags by context.
- **Share privacy:** Shares contain *only* filter state + tag keys, no PII.
