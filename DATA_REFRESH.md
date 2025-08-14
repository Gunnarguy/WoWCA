# Data Refresh & Patch 1.15.7 Migration

This document explains how to rebuild the item database with authoritative Classic Era (1.15.7) stats, track version metadata, and highlight changed armor/block values (e.g. shield armor corrections).

## 1. Authoritative Source Assumptions
Because Blizzard does not publish a full raw Classic Era item template dump, we compose data from community-accessible sources:
- Wowhead Classic web tooltips (human verified) for spot‑checks.
- wow.tools DB2 export (Item + ItemSparse) filtered to Classic Era build; provides raw numeric fields.

> You must manually export & normalize to `data_sources/1157/items_core.csv`; automated scraping intentionally excluded.

## 2. Prepare Source CSV
Place `items_core.csv` in `data_sources/1157/` using the header described inside that folder's README. Include at minimum: identity, core stats, armor, block, damage groups, resistances, spell slots, and patch indicator.

## 3. Build New Database (Unified Script)
```
./build_db.sh [optional path/to/previous/items.sqlite]
```
Outputs:
- `build/items.sqlite` (full mega schema: 129 columns + FTS + metadata + change tracking)
- `Resources/items.sqlite` (copied for the app bundle)
- `build/item_changes_report.csv` (if previous DB path passed)

## 4. Version Metadata
`data_version` row captures:
- patch_version (e.g., 1.15.7)
- build_date (UTC YYYY-MM-DD)
- item_count, max_item_level for integrity verification
- source + source_url for provenance

## 5. Change Tracking
If a previous DB is supplied, changed armor or block values produce entries in `item_changes` with a comma list of changed_fields. UI displays an "Updated" badge.

## 6. Diff Reports (Standalone)
You can also diff any two DBs:
```
./generate_diff_report.sh old.sqlite new.sqlite changed_armor_block.csv
```
Columns: entry,name,oldArmor,newArmor,deltaArmor,oldBlock,newBlock,deltaBlock

## 7. Integrity Checks (Runtime)
`DatabaseService` runs lightweight checks: row count, max item_level, consistency with `data_version` row. Warnings surface via a triangle icon next to the data version in the item detail view.

## 8. Display in UI
Item Detail shows:
- Data version: `1.15.7 (YYYY-MM-DD)`
- Updated badge when present in `item_changes`.

## 9. Historical Toggle (Future Option)
To support a "Pre‑1.15.7" toggle:
- Keep previous DB as `items_prev.sqlite` or add a `historical_items` table with columns (entry, patch_version, armor, block,...). Merge on build.
- Add optional query in UI to show alternate values.

## 10. Verification Queries
```
# Row count & max level
sqlite3 build/items_mega_enhanced.sqlite "SELECT COUNT(*) items, MAX(item_level) max_ilvl FROM items;"

# Random sample of shields
sqlite3 build/items_mega_enhanced.sqlite "SELECT entry,name,armor,block FROM items WHERE subclass=6 AND class=4 ORDER BY RANDOM() LIMIT 5;"

# Changed items summary
sqlite3 build/items_mega_enhanced.sqlite "SELECT COUNT(*) FROM item_changes;"

# Specific shield check (replace 17182 etc.)
sqlite3 build/items_mega_enhanced.sqlite "SELECT entry,name,armor,block FROM items WHERE entry IN (17182,13245,1168,1979,1204);"
```

## 11. Updating the App Bundle
Automatic: the build script copies the freshly built `items.sqlite` into `Resources/`. Rebuild the app after running `./build_db.sh`.

## 12. Release Checklist
- [ ] Source CSV updated & committed (if permissible)
- [ ] Build script run (no errors) `./build_db.sh`
- [ ] Integrity checks show no warnings
- [ ] Spot‑checked ≥5 shields & ≥5 other armor pieces vs Wowhead
- [ ] Diff report generated & reviewed
- [ ] App UI shows correct version string

## 13. Follow‑Up Enhancements
- Add caching layer for multiple patch snapshots.
- Expand `item_changes` to include per-field old/new values (JSON blob for UI diffing).
- Integrate automated wow.tools export (if API license/permissions allow) behind a script.
- Add unit tests that open each DB and assert basic invariants.

---
Questions that remain (need product decision):
1. How frequently to refresh (weekly, per Blizzard hotfix, manual)?
2. Do we store historic snapshots inside shipping app or fetch remotely?
3. Additional fields to track for changes (stats, damage, spell data)?
