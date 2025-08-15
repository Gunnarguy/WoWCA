# Item Data Quality Fix - August 2025

## Problem
The original build script (`build_db.sh`) was using `INSERT OR REPLACE` to handle duplicate item entries from different WoW patches, but this caused the last entry in the source file to overwrite earlier (and often more accurate) entries, regardless of patch quality.

## Specific Issue
**Drillborer Disk (ID: 17066)** had incorrect armor value:
- Patch 2 & 7: armor 2539 (correct)
- Patch 0: armor 2291 (incorrect)
- Problem: Patch 0 came last in file, so it overwrote the correct values

## Root Cause
193 items had conflicting armor values across different patches. The build script processed entries in file order without considering patch quality, leading to systematic data corruption where patch 0 (often incomplete/inaccurate) overwrote better patch data.

## Solution
Created `rebuild_items_with_priority.py` which:

1. **Groups all item versions by entry ID** before inserting anything
2. **Selects highest patch number** when conflicts exist (higher = more complete/accurate)
3. **Logs all armor conflicts resolved** for transparency
4. **Rebuilds FTS index** after data correction

## Items Fixed
Fixed 193 items with conflicting armor values, including:
- Drillborer Disk: 2291 → 2539 armor
- Murloc Scale Belt: 40 → 42 armor  
- All Marshal's/Warlord's PvP gear with patch conflicts
- All cloth/leather armor items with patch version conflicts

## Prevention
- **Always use `rebuild_items_with_priority.py`** instead of the original build script
- **Higher patch numbers are preferred** (patch 9 > patch 8 > ... > patch 0)
- **Conflicts are logged** so you can verify corrections are sensible

## Usage
```bash
# To rebuild database with proper patch priority:
python3 rebuild_items_with_priority.py

# Database will be rebuilt in WoWCA/items.sqlite with correct armor values
```

## Result
- ✅ All 193 armor conflicts resolved
- ✅ Drillborer Disk now shows correct 2539 armor
- ✅ App database updated and FTS rebuilt
- ✅ No more "last entry wins" data corruption

**This should be the FINAL fix for item data discrepancies.**
