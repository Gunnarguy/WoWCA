#!/usr/bin/env bash
set -euo pipefail

# generate_diff_report.sh - Compare two SQLite item databases and emit armor/block deltas
# Usage: ./generate_diff_report.sh OLD_DB NEW_DB [OUT_CSV]
# Default OUT_CSV = diff_report.csv

OLD_DB=${1:?"OLD_DB path required"}
NEW_DB=${2:?"NEW_DB path required"}
OUT_CSV=${3:-diff_report.csv}

if [ ! -f "$OLD_DB" ]; then echo "Old DB not found: $OLD_DB" >&2; exit 1; fi
if [ ! -f "$NEW_DB" ]; then echo "New DB not found: $NEW_DB" >&2; exit 1; fi

sqlite3 -csv "$NEW_DB" "ATTACH DATABASE '$OLD_DB' AS olddb; \
WITH comp AS ( \
  SELECT n.entry, \
         IFNULL(o.armor,0) AS oldArmor, IFNULL(n.armor,0) AS newArmor, \
         (IFNULL(n.armor,0)-IFNULL(o.armor,0)) AS deltaArmor, \
         IFNULL(o.block,0) AS oldBlock, IFNULL(n.block,0) AS newBlock, \
         (IFNULL(n.block,0)-IFNULL(o.block,0)) AS deltaBlock, \
         n.name \
  FROM items n LEFT JOIN olddb.items o ON o.entry = n.entry \
  WHERE (IFNULL(n.armor,0)!=IFNULL(o.armor,0)) OR (IFNULL(n.block,0)!=IFNULL(o.block,0)) \
) SELECT entry,name,oldArmor,newArmor,deltaArmor,oldBlock,newBlock,deltaBlock FROM comp ORDER BY ABS(deltaArmor)+ABS(deltaBlock) DESC;" > "$OUT_CSV"

echo "Wrote $OUT_CSV"
