#!/usr/bin/env bash
set -euo pipefail
DB=${1:-build/items_mega_enhanced.sqlite}
EXPECTED_PATCH=${EXPECTED_PATCH:-1.15.7}

fail(){ echo "❌ $1" >&2; exit 1; }
[ -f "$DB" ] || fail "Database not found: $DB"

echo "🔎 Verifying $DB"
# 1. Version table
if sqlite3 "$DB" \
  "SELECT 1 FROM sqlite_master WHERE type='table' AND name='data_version';" | grep -q 1; then
  read PATCH BUILD_DATE ITEM_COUNT MAX_ILVL <<<"$(sqlite3 "$DB" "SELECT patch_version, build_date, item_count, max_item_level FROM data_version ORDER BY id DESC LIMIT 1;")"
  echo "   Patch: $PATCH  Build Date: $BUILD_DATE  Items: $ITEM_COUNT  Max iLvl: $MAX_ILVL"
  [ "$PATCH" = "$EXPECTED_PATCH" ] || echo "   ⚠️ Expected patch $EXPECTED_PATCH got $PATCH"
else
  echo "   ⚠️ data_version table missing"
fi

# 2. Basic invariants
read COUNT MAX_ILVL_ACTUAL <<<"$(sqlite3 "$DB" "SELECT COUNT(*), MAX(item_level) FROM items;")"
[ "$COUNT" -ge 1000 ] || fail "Too few items ($COUNT)"
[ "$MAX_ILVL_ACTUAL" -ge 60 ] || fail "Suspicious max item_level ($MAX_ILVL_ACTUAL)"
echo "   Item count + max item_level OK"

# 3. Drillborer Disk armor check (entry 17066)
DRILL_ARMOR=$(sqlite3 "$DB" "SELECT armor FROM items WHERE entry=17066;") || true
if [ -n "$DRILL_ARMOR" ]; then
  echo "   Drillborer Disk armor: $DRILL_ARMOR"
  [ "$DRILL_ARMOR" = "2539" ] || echo "   ⚠️ Expected 2539; app will show override if running DEBUG build"
else
  echo "   ⚠️ Drillborer Disk not found (entry 17066)"
fi

# 4. Random shield sample
sqlite3 "$DB" "SELECT entry,name,armor,block FROM items WHERE class=4 AND subclass=6 ORDER BY RANDOM() LIMIT 5;" | sed 's/^/   /'

# 5. Change tracking
if sqlite3 "$DB" "SELECT 1 FROM sqlite_master WHERE type='table' AND name='item_changes';" | grep -q 1; then
  CHANGED_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM item_changes;")
  echo "   item_changes rows: $CHANGED_COUNT"
fi

echo "✅ Verification complete"
