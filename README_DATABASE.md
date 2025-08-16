# WoW Classic Item Database - Project Status

## ✅ FINAL STABLE STATE

### Current Database
- **File**: `Resources/items.sqlite` (canonical, bundled with app)
- **Items**: 16,870 Classic WoW items
- **Schema**: 129 columns with complete weapon stats, spell effects, resistances
- **Max Item Level**: 100
- **Source**: thatsmybis/classic-wow-item-db (unmodified.sql)
- **Build Date**: 2025-08-14
- **Patch Version**: 1.15.7

### Database Features
- **Weapon Stats**: Damage ranges (5 slots), weapon speed, DPS calculations
- **Character Stats**: All 10 primary/secondary stat slots
- **Spell Effects**: 5 spell slots with trigger types, cooldowns, proc rates
- **Resistances**: All 6 resistance types (Fire, Nature, Frost, Shadow, Holy, Arcane)
- **Item Properties**: Binding, durability, set IDs, quest items, requirements
- **Full-Text Search**: FTS5 with BM25 ranking for fast name/description search

### App Integration
- **Database Service**: `WoWCA/DatabaseService.swift` (loads `items.sqlite`)
- **Item Model**: Enhanced with 37+ properties and computed values
- **Search**: Fixed FTS query syntax, supports both name and ID search
- **UI**: Enhanced detail and row views showing all weapon/stat data

### Build Pipeline
- **Script**: `./build_db.sh` (single authoritative builder)
- **Verification**: `./verify_db.sh Resources/items.sqlite`
- **Output**: `build/items.sqlite` → copied to `Resources/items.sqlite`

### Verified Examples
- **Flurry Axe (871)**: 37-69 damage, 1.5s speed, spell ID 18797 (chance on hit)
- **Search Results**: "flurry axe" and "871" both return correct results
- **Special Abilities**: Items with procs, on-use effects, set bonuses working

### What Was Cleaned Up
- ❌ Removed 5 obsolete build scripts
- ❌ Removed duplicate DatabaseService.swift
- ❌ Removed unused .sqlite variants
- ✅ Single canonical database pipeline
- ✅ Enhanced UI components integrated
- ✅ Complete weapon and spell data

## 🎯 Ready to Iterate

The project is now in a clean, stable state with:
- Working search for all items including Flurry Axe
- Complete weapon damage, speed, and special ability data
- Clean build pipeline for future updates
- Enhanced UI showing all available item properties

All nerdy WoW Classic item data is now accessible in your app! 🏆

## Version Bumping (App Store Release)

Use the helper script to increment versions prior to a release build.

```
chmod +x ./bump_version.sh
./bump_version.sh patch   # or minor / major
```

This updates:
- MARKETING_VERSION (user-visible)
- CURRENT_PROJECT_VERSION (build number)

Then commit and optionally tag:

```
git commit -am "release: vX.Y.Z"
git tag vX.Y.Z
```

Push tags if you want them on GitHub:

```
git push --follow-tags
```
