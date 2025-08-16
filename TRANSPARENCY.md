# Data & Build Transparency

This document explains exactly where the data comes from, how it is transformed, and what code or tooling participates in the shipped binary.

## Source Repositories / Inputs
| Purpose | Location | Notes |
|---------|----------|-------|
| Raw Classic item data | `classic-wow-item-db/db/unmodified.sql` (vendored snapshot) | Upstream: thatsmybis/classic-wow-item-db |

## Build Scripts & Tooling
| Component | Path | Role |
|-----------|------|------|
| Item DB build | `items_build.sh` | Orchestrates full SQLite DB construction and FTS indexing |
| Icon generation | `scripts/generate_app_icon.py` | Deterministic raster generation of all required app icon sizes (no external art) |
| Version bump | `bump_version.sh` | Increments build / marketing versions inside Xcode project |

### items_build.sh Overview
High-level pipeline:
1. Read `unmodified.sql` raw item tuples.
2. Embedded Python parses tuple text into structured inserts (maps tuple indices to named columns).
3. Create normalized `items` table + indexes.
4. Populate FTS5 virtual table `items_fts` (tokenizes names/descriptions for search).
5. Insert a `data_version` row containing schema + patch metadata.
6. Copy final `items.sqlite` into `Resources/` for bundling.

### Determinism & Reproducibility
Given identical input file + script revisions and environment variables (`SCHEMA_VERSION`, `PATCH_VERSION`) the resulting SQLite file is deterministic except for potential variation if the underlying SQLite FTS tokenizer implementation changes between SQLite versions.

You can rebuild locally:
```
./items_build.sh
cmp build/items.sqlite Resources/items.sqlite || echo "(Resources copy differs)"
```

### Integrity Checks
Examples:
```
sqlite3 build/items.sqlite 'select count(*) as item_rows from items;'
sqlite3 build/items.sqlite "select entry,name from items_fts where items_fts match 'sulfuras*' limit 5;"
sqlite3 build/items.sqlite 'select * from data_version;'
```

## Third-Party Libraries (Runtime)
| Library | Purpose | License |
|---------|---------|---------|
| GRDB.swift | SQLite / FTS wrapper for Swift | MIT |

## Third-Party Tools (Build-Time Only)
| Tool | Purpose | License |
|------|---------|---------|
| Python (stdlib) | Execute embedded parsing code | PSF |
| Pillow | Procedural icon rendering | Historical PIL (permissive) |

## Privacy Posture
The app has: no analytics SDKs, no crash reporting, no networking code making outbound requests, and writes no user-identifying data. All item queries are on-device (FTS over bundled SQLite). See `PRIVACY_POLICY.md` and `PrivacyInfo.xcprivacy`.

## Open Questions / Contributions
Issues welcome for:
- Data inaccuracies
- Additional provenance needs
- Repro build problems

Create an issue at: https://github.com/Gunnarguy/WoWCA/issues

---
Last updated: (update when pipeline changes)
