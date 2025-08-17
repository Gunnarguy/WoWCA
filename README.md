# WoWCA: A World of Warcraft Classic Item Database for iOS

![WoWCA Screenshot](https://raw.githubusercontent.com/Gunnarguy/WoWCA/main/wowca_promo.png)

WoWCA is an offline item database browser for World of Warcraft Classic, built for iOS. It includes a SwiftUI client and a reproducible data build pipeline that produces the bundled `items.sqlite`. Initial version built in ~6 hours.

---

## Features

- Offline, read‑only SQLite item database
- Fast name / ID search (FTS5 prefix queries + direct ID lookup)
- Detailed item view: stats, damage ranges, resistances, spell procs, requirements
- Fully on‑device (no network requests)
- SwiftUI + GRDB + structured concurrency (actor‑isolated DB access)

---

## Architecture Overview

### Data Pipeline

Scripts (shell + Python) transform upstream Classic item data into a single normalized SQLite file with:

- `items` table (wide schema ~129 columns in upstream form; app model pares to needed fields)
- FTS5 virtual table for name/description searching
- Optional metadata table (`data_version`) for patch + build info

High level steps:

1. Acquire upstream SQL dump (vendored snapshot of `classic-wow-item-db` -> `unmodified.sql`).
2. Parse / filter / normalize columns (Python helpers inside shell script or standalone rebuild script).
3. Resolve duplicate item rows across patches (prefer highest patch when conflicts).
4. Create tables + indexes + FTS5 content.
5. Package final `items.sqlite` into `Resources/` for app bundling.

### iOS Application

- `DatabaseService`: Copies bundled DB to Application Support (fresh each launch in current setup).
- `ItemRepository` (actor): Serializes all GRDB `DatabaseQueue` reads to avoid concurrency diagnostics.
- `ItemSearchViewModel`: MainActor state (query, results, progress flag).
- Views: `SearchView` (searchable list), `ItemDetailView`, `ItemRowView`, `AboutView`.

---

## Building & Running

```bash
# Clone
git clone https://github.com/Gunnarguy/WoWCA.git
cd WoWCA

# Open in Xcode
xed .
# Or open WoWCA.xcodeproj manually
```

Select the `WoWCA` scheme and run on simulator or device. The included `items.sqlite` is copied automatically.

---

## Rebuilding the Database (Summary)

(The original standalone docs have been condensed here.)

Typical rebuild entry point (example name may vary if you add one):

```bash
./items_build.sh
```

Expected outputs:

- `build/items.sqlite` (fresh build)
- Copied to `Resources/items.sqlite`

Integrity / spot checks (examples):

```bash
sqlite3 build/items.sqlite 'select count(*) from items;'
sqlite3 build/items.sqlite "select entry,name from items_fts where items_fts match 'sulfuras*' limit 5;"
```

Armor conflict / patch priority resolution (historical fix): previous duplication issues were solved by grouping rows per `entry` and selecting the highest `patch` when conflicting armor values existed (e.g. Drillborer Disk 2291 -> 2539). Use the priority‑aware rebuild script (if present) instead of naive "last row wins" logic.

Determinism: Output is stable given identical input dump + script revisions (aside from underlying SQLite FTS implementation differences between SQLite versions).

---

## App Store Deployment (Condensed Checklist)

1. Bump version / build:

   ```bash
   ./bump_version.sh patch   # or minor / major
   ```

2. Archive (Any iOS Device) → Organizer → Validate → Distribute.
3. Provide metadata (name, subtitle, keywords, privacy policy URL, screenshots).
4. Confirm: no custom encryption, no tracking, offline‑only.
5. Submit / (optionally) TestFlight first.

Screenshots: Search view, item detail (with stats + procs), empty state, about screen.

---

## Privacy & Disclaimer

### Privacy

- No analytics, crash reporters, ads, or tracking identifiers.
- No network calls; all queries executed locally over bundled SQLite.
- No user data persisted beyond standard OS caches.

### Disclaimer

This project is an independent, fan‑made reference. It is not affiliated with or endorsed by Blizzard Entertainment. "World of Warcraft" and related names are trademarks of Blizzard Entertainment, Inc. Only numerical/item data derived from publicly accessible sources is included; no proprietary artwork or copyrighted assets are distributed.

Report concerns via GitHub issues.

---

## Third‑Party & Licensing

| Component | Purpose | License |
|----------|---------|---------|
| GRDB.swift | SQLite wrapper / FTS access | MIT |
| Python (stdlib) | Build scripting | PSF |
| (Optional) Pillow | Icon generation (if used) | Historical PIL |

Project code: MIT (see `LICENSE`).

---

## Maintenance Notes / Future Ideas

- Optional: retain cached DB instead of re‑copying each launch.
- Add lightweight unit tests for search edge cases (numeric ID vs text, empty query).
- Add favorites / recently viewed table (would require write access & migration policy).
- Provide diff tooling for multi‑patch historical comparisons.

---

## Provenance Snapshot (Example)

(Adjust when regenerating DB.)

- Source dump: `classic-wow-item-db/db/unmodified.sql` (snapshot date: 2025-08-14)
- Rows (items): (run integrity query to confirm)
- Max item level: (query)
- Patch preference logic: highest `patch` per `entry`.

---

## Removed Separate Docs

The following standalone markdown files were consolidated into this README for brevity: privacy policy, disclaimer, database status, transparency, data refresh instructions, item data quality fix notes, App Store checklist. Original commit history retains their full text if needed.

---

## Issue Reporting

Open an issue with:

- Reproduction (if app bug)
- Item ID(s) (if data discrepancy)
- Expected vs observed values

---

## Quick Reference Commands

```bash
# Build DB
./items_build.sh

# Verify FTS sample
sqlite3 build/items.sqlite "select entry,name from items_fts where items_fts match 'arcanite*' limit 5;"

# Count items
sqlite3 build/items.sqlite 'select count(*) from items;'
```

---

MIT © 2025 Gunndamental
