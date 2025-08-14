#!/usr/bin/env bash
set -euo pipefail

# build_db_1157.sh - Regenerate Classic Era (1.15.7) item database with version + change tracking
#
# Usage:
#   ./build_db_1157.sh [PREVIOUS_DB_PATH]
#
# Optional:
#   PREVIOUS_DB_PATH   Path to an older items_mega_enhanced.sqlite to compute per-item change flags.
#
# Environment overrides:
#   PATCH_VERSION      (default: 1.15.7)
#   BUILD_DATE         (default: current UTC date YYYY-MM-DD)
#   SOURCE_LABEL       (default: Wowhead/Wow Tools composite)
#   SOURCE_URL         (default: https://www.wowhead.com/classic)
#   SCHEMA_VERSION     (default: 1)
#
# Data acquisition:
#   This script now parses the `unmodified.sql` file from the `classic-wow-item-db` repo.
#   The repo is expected to be cloned in the project's root directory.
#
# Outputs:
#   build/items_mega_enhanced.sqlite  (primary DB consumed by app)
#   build/item_changes_report.csv     (human readable diff summary vs previous DB if provided)

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$ROOT_DIR/build"
OUT_DB="$BUILD_DIR/items_mega_enhanced.sqlite"
SRC_SQL="$ROOT_DIR/classic-wow-item-db/db/unmodified.sql"
PREV_DB="${1:-}"

PATCH_VERSION=${PATCH_VERSION:-1.15.7}
BUILD_DATE=${BUILD_DATE:-$(date -u +%F)}
SOURCE_LABEL=${SOURCE_LABEL:-thatsmybis/classic-wow-item-db}
SOURCE_URL=${SOURCE_URL:-https://github.com/thatsmybis/classic-wow-item-db}
SCHEMA_VERSION=${SCHEMA_VERSION:-2} # Bump schema for new data source

mkdir -p "$BUILD_DIR"

if [ ! -f "$SRC_SQL" ]; then
  echo "ERROR: Source SQL file not found: $SRC_SQL" >&2
  echo "Please ensure 'classic-wow-item-db' is cloned in the root directory." >&2
  exit 1
fi

echo "[build_db_1157] Creating schema (+ version + change tracking)" 
rm -f "$OUT_DB"

sqlite3 "$OUT_DB" <<'EOF'
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE items (
  entry INTEGER PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  quality INTEGER NOT NULL DEFAULT 0,
  class INTEGER DEFAULT 0,
  subclass INTEGER DEFAULT 0,
  patch INTEGER DEFAULT 0,
  inventory_type INTEGER DEFAULT 0,
  item_level INTEGER DEFAULT 0,
  required_level INTEGER DEFAULT 0,
  allowable_class INTEGER DEFAULT -1,
  buy_price INTEGER DEFAULT 0,
  sell_price INTEGER DEFAULT 0,
  -- 10 stats
  stat_type1 INTEGER, stat_value1 INTEGER,
  stat_type2 INTEGER, stat_value2 INTEGER,
  stat_type3 INTEGER, stat_value3 INTEGER,
  stat_type4 INTEGER, stat_value4 INTEGER,
  stat_type5 INTEGER, stat_value5 INTEGER,
  stat_type6 INTEGER, stat_value6 INTEGER,
  stat_type7 INTEGER, stat_value7 INTEGER,
  stat_type8 INTEGER, stat_value8 INTEGER,
  stat_type9 INTEGER, stat_value9 INTEGER,
  stat_type10 INTEGER, stat_value10 INTEGER,
  -- weapon
  delay INTEGER, dmg_min1 REAL, dmg_max1 REAL, dmg_type1 INTEGER,
  dmg_min2 REAL, dmg_max2 REAL, dmg_type2 INTEGER,
  dmg_min3 REAL, dmg_max3 REAL, dmg_type3 INTEGER,
  dmg_min4 REAL, dmg_max4 REAL, dmg_type4 INTEGER,
  dmg_min5 REAL, dmg_max5 REAL, dmg_type5 INTEGER,
  -- armor / defense
  armor INTEGER DEFAULT 0,
  block INTEGER DEFAULT 0,
  -- resist
  holy_res INTEGER DEFAULT 0,
  fire_res INTEGER DEFAULT 0,
  nature_res INTEGER DEFAULT 0,
  frost_res INTEGER DEFAULT 0,
  shadow_res INTEGER DEFAULT 0,
  arcane_res INTEGER DEFAULT 0,
  -- spells
  spellid_1 INTEGER, spelltrigger_1 INTEGER, spellcharges_1 INTEGER, spellppmrate_1 REAL, spellcooldown_1 INTEGER,
  spellid_2 INTEGER, spelltrigger_2 INTEGER, spellcharges_2 INTEGER, spellppmrate_2 REAL, spellcooldown_2 INTEGER,
  spellid_3 INTEGER, spelltrigger_3 INTEGER, spellcharges_3 INTEGER, spellppmrate_3 REAL, spellcooldown_3 INTEGER,
  spellid_4 INTEGER, spelltrigger_4 INTEGER, spellcharges_4 INTEGER, spellppmrate_4 REAL, spellcooldown_4 INTEGER,
  spellid_5 INTEGER, spelltrigger_5 INTEGER, spellcharges_5 INTEGER, spellppmrate_5 REAL, spellcooldown_5 INTEGER,
  -- misc
  set_id INTEGER, max_durability INTEGER
);

CREATE VIRTUAL TABLE items_fts USING fts5(entry, name, description, content=items, content_rowid=entry, tokenize='unicode61');

-- Version meta
CREATE TABLE data_version (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  patch_version TEXT NOT NULL,
  build_date TEXT NOT NULL,
  source TEXT,
  source_url TEXT,
  item_count INTEGER,
  max_item_level INTEGER,
  schema_version INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

-- Changed items (vs previous DB). changed_fields is comma list e.g. 'armor,block'
CREATE TABLE item_changes (
  entry INTEGER PRIMARY KEY,
  changed_fields TEXT
);

CREATE INDEX idx_items_quality ON items(quality);
CREATE INDEX idx_items_level ON items(item_level);
CREATE INDEX idx_items_class ON items(class, subclass);
EOF

echo "[build_db_1157] Importing from SQL dump -> items" 

# Write a temporary import script for sqlite (requires consistent column ordering)
python3 - <<'PY'
import csv, sqlite3, os, sys, re

root = os.path.dirname(os.path.abspath(sys.argv[0]))
db_path = os.path.join(root, 'build', 'items_mega_enhanced.sqlite')
sql_path = os.path.join(root, 'classic-wow-item-db', 'db', 'unmodified.sql')

con = sqlite3.connect(db_path)
cur = con.cursor()

# These are the columns we want to insert into our new 'items' table.
# The order MUST match the table schema defined above.
db_columns = [
    'entry', 'name', 'description', 'quality', 'class', 'subclass', 'patch',
    'inventory_type', 'item_level', 'required_level', 'allowable_class',
    'buy_price', 'sell_price',
    'stat_type1', 'stat_value1', 'stat_type2', 'stat_value2', 'stat_type3', 'stat_value3',
    'stat_type4', 'stat_value4', 'stat_type5', 'stat_value5', 'stat_type6', 'stat_value6',
    'stat_type7', 'stat_value7', 'stat_type8', 'stat_value8', 'stat_type9', 'stat_value9',
    'stat_type10', 'stat_value10',
    'delay', 'dmg_min1', 'dmg_max1', 'dmg_type1', 'dmg_min2', 'dmg_max2', 'dmg_type2',
    'dmg_min3', 'dmg_max3', 'dmg_type3', 'dmg_min4', 'dmg_max4', 'dmg_type4',
    'dmg_min5', 'dmg_max5', 'dmg_type5',
    'armor', 'block',
    'holy_res', 'fire_res', 'nature_res', 'frost_res', 'shadow_res', 'arcane_res',
    'spellid_1', 'spelltrigger_1', 'spellcharges_1', 'spellppmrate_1', 'spellcooldown_1',
    'spellid_2', 'spelltrigger_2', 'spellcharges_2', 'spellppmrate_2', 'spellcooldown_2',
    'spellid_3', 'spelltrigger_3', 'spellcharges_3', 'spellppmrate_3', 'spellcooldown_3',
    'spellid_4', 'spelltrigger_4', 'spellcharges_4', 'spellppmrate_4', 'spellcooldown_4',
    'spellid_5', 'spelltrigger_5', 'spellcharges_5', 'spellppmrate_5', 'spellcooldown_5',
    'set_id', 'max_durability'
]

# This maps our desired column name to its index in the raw SQL dump tuple.
sql_dump_field_map = {
    'entry': 0, 'patch': 1, 'class': 2, 'subclass': 3, 'name': 4, 'description': 5,
    'display_id': 6, 'quality': 7, 'flags': 8, 'buy_count': 9, 'buy_price': 10,
    'sell_price': 11, 'inventory_type': 12, 'allowable_class': 13, 'allowable_race': 14,
    'item_level': 15, 'required_level': 16, 'required_skill': 17, 'required_skill_rank': 18,
    'required_spell': 19, 'required_honor_rank': 20, 'required_city_rank': 21,
    'required_reputation_faction': 22, 'required_reputation_rank': 23, 'max_count': 24,
    'stackable': 25, 'container_slots': 26,
    'stat_type1': 27, 'stat_value1': 28, 'stat_type2': 29, 'stat_value2': 30,
    'stat_type3': 31, 'stat_value3': 32,. 

# Write a temporary import script for sqlite (requires consistent column ordering)
python3 - <<'PY'
import csv, sqlite3, os, sys, re

root = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(root, 'build', 'items_mega_enhanced.sqlite')
sql_path = os.path.join(root, 'classic-wow-item-db', 'db', 'unmodified.sql')

con = sqlite3.connect(db_path)
cur = con.cursor()

# These are the columns we want to insert into our new 'items' table.
# The order MUST match the table schema defined above.
db_columns = [
    'entry', 'name', 'description', 'quality', 'class', 'subclass', 'patch',
    'inventory_type', 'item_level', 'required_level', 'allowable_class',
    'buy_price', 'sell_price',
    'stat_type1', 'stat_value1', 'stat_type2', 'stat_value2', 'stat_type3', 'stat_value3',
    'stat_type4', 'stat_value4', 'stat_type5', 'stat_value5', 'stat_type6', 'stat_value6',
    'stat_type7', 'stat_value7', 'stat_type8', 'stat_value8', 'stat_type9', 'stat_value9',
    'stat_type10', 'stat_value10',
    'delay', 'dmg_min1', 'dmg_max1', 'dmg_type1', 'dmg_min2', 'dmg_max2', 'dmg_type2',
    'dmg_min3', 'dmg_max3', 'dmg_type3', 'dmg_min4', 'dmg_max4', 'dmg_type4',
    'dmg_min5', 'dmg_max5', 'dmg_type5',
    'armor', 'block',
    'holy_res', 'fire_res', 'nature_res', 'frost_res', 'shadow_res', 'arcane_res',
    'spellid_1', 'spelltrigger_1', 'spellcharges_1', 'spellppmrate_1', 'spellcooldown_1',
    'spellid_2', 'spelltrigger_2', 'spellcharges_2', 'spellppmrate_2', 'spellcooldown_2',
    'spellid_3', 'spelltrigger_3', 'spellcharges_3', 'spellppmrate_3', 'spellcooldown_3',
    'spellid_4', 'spelltrigger_4', 'spellcharges_4', 'spellppmrate_4', 'spellcooldown_4',
    'spellid_5', 'spelltrigger_5', 'spellcharges_5', 'spellppmrate_5', 'spellcooldown_5',
    'set_id', 'max_durability'
]

# This maps our desired column name to its index in the raw SQL dump tuple.
sql_dump_field_map = {
    'entry': 0, 'patch': 1, 'class': 2, 'subclass': 3, 'name': 4, 'description': 5,
    'display_id': 6, 'quality': 7, 'flags': 8, 'buy_count': 9, 'buy_price': 10,
    'sell_price': 11, 'inventory_type': 12, 'allowable_class': 13, 'allowable_race': 14,
    'item_level': 15, 'required_level': 16, 'required_skill': 17, 'required_skill_rank': 18,
    'required_spell': 19, 'required_honor_rank': 20, 'required_city_rank': 21,
    'required_reputation_faction': 22, 'required_reputation_rank': 23, 'max_count': 24,
    'stackable': 25, 'container_slots': 26,
    'stat_type1': 27, 'stat_value1': 28, 'stat_type2': 29, 'stat_value2': 30,
    'stat_type3': 31, 'stat_value3': 32, 'stat_type4': 33, 'stat_value4': 34,
    'stat_type5': 35, 'stat_value5': 36, 'stat_type6': 37, 'stat_value6': 38,
    'stat_type7': 39, 'stat_value7': 40, 'stat_type8': 41, 'stat_value8': 42,
    'stat_type9': 43, 'stat_value9': 44, 'stat_type10': 45, 'stat_value10': 46,
    'delay': 47, 'range_mod': 48, 'ammo_type': 49,
    'dmg_min1': 50, 'dmg_max1': 51, 'dmg_type1': 52,
    'dmg_min2': 53, 'dmg_max2': 54, 'dmg_type2': 55,
    'dmg_min3': 56, 'dmg_max3': 57, 'dmg_type3': 58,
    'dmg_min4': 59, 'dmg_max4': 60, 'dmg_type4': 61,
    'dmg_min5': 62, 'dmg_max5': 63, 'dmg_type5': 64,
    'block': 65, 'armor': 66,
    'holy_res': 67, 'fire_res': 68, 'nature_res': 69, 'frost_res': 70, 'shadow_res': 71, 'arcane_res': 72,
    'spellid_1': 73, 'spelltrigger_1': 74, 'spellcharges_1': 75, 'spellppmrate_1': 76, 'spellcooldown_1': 77,
    'spellid_2': 79, 'spelltrigger_2': 80, 'spellcharges_2': 81, 'spellppmrate_2': 82, 'spellcooldown_2': 83,
    'spellid_3': 85, 'spelltrigger_3': 86, 'spellcharges_3': 87, 'spellppmrate_3': 88, 'spellcooldown_3': 89,
    'spellid_4': 91, 'spelltrigger_4': 92, 'spellcharges_4': 93, 'spellppmrate_4': 94, 'spellcooldown_4': 95,
    'spellid_5': 97, 'spelltrigger_5': 98, 'spellcharges_5': 99, 'spellppmrate_5': 100, 'spellcooldown_5': 101,
    'set_id': 107, 'max_durability': 108
}

def safe_get(values, key, default=None):
    """Safely gets a value from the tuple by mapped key, returning default if not found."""
    idx = sql_dump_field_map.get(key)
    if idx is None or idx >= len(values):
        return default
    val = values[idx]
    if val == 'NULL':
        return None
    if isinstance(val, str):
        return val.strip("'").replace("\\'", "''") # Handle escaped quotes for SQL
    return val

with open(sql_path, 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

insert_pattern = re.compile(r"INSERT INTO `items` VALUES\s*(.*?);", re.DOTALL)
# A more robust regex for tuples that can handle nested parentheses and escaped quotes
tuple_pattern = re.compile(r"\(([^)]*(?:\([^)]*\)[^)]*)*)\)")

rows = 0
for insert_block in insert_pattern.findall(content):
    for match in tuple_pattern.finditer(insert_block):
        try:
            # This is a bit of a hack to parse the tuple string correctly
            # It wraps the group in parentheses so eval sees it as a tuple
            raw_values = eval(f"({match.group(1)})")

            # Build a dictionary of data for the current item
            item_data = {col: safe_get(raw_values, col) for col in db_columns}

            # Ensure required fields are not null
            if item_data.get('entry') is None or item_data.get('name') is None:
                continue

            cols = ','.join(item_data.keys())
            placeholders = ','.join(['?'] * len(item_data))
            
            cur.execute(f'INSERT OR REPLACE INTO items ({cols}) VALUES ({placeholders})', list(item_data.values()))
            rows += 1
            if rows % 2000 == 0:
                print(f'  imported {rows} rows')
        except Exception as e:
            # print(f"Skipping row due to error: {e} -> {match.group(1)[:100]}")
            continue

con.commit()
print(f'Imported {rows} items')

# FTS
cur.execute("INSERT INTO items_fts(entry, name, description) SELECT entry, name, description FROM items")
con.commit()
con.close()
#
#   You can regenerate this CSV by adding a separate fetch script (not included here to avoid TOS issues).
#
# Outputs:
#   build/items_mega_enhanced.sqlite  (primary DB consumed by app)
#   build/item_changes_report.csv     (human readable diff summary vs previous DB if provided)

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$ROOT_DIR/build"
OUT_DB="$BUILD_DIR/items_mega_enhanced.sqlite"
SRC_CSV="$ROOT_DIR/data_sources/1157/items_core.csv"
PREV_DB="${1:-}"

PATCH_VERSION=${PATCH_VERSION:-1.15.7}
BUILD_DATE=${BUILD_DATE:-$(date -u +%F)}
SOURCE_LABEL=${SOURCE_LABEL:-Wowhead/Wow Tools}
SOURCE_URL=${SOURCE_URL:-https://www.wowhead.com/classic}
SCHEMA_VERSION=${SCHEMA_VERSION:-1}

mkdir -p "$BUILD_DIR"

if [ ! -f "$SRC_CSV" ]; then
  echo "ERROR: Source CSV not found: $SRC_CSV" >&2
  echo "Please create it as described in header comments." >&2
  exit 1
fi

echo "[build_db_1157] Creating schema (+ version + change tracking)" 
rm -f "$OUT_DB"

sqlite3 "$OUT_DB" <<'EOF'
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE items (
  entry INTEGER PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  quality INTEGER NOT NULL DEFAULT 0,
  class INTEGER DEFAULT 0,
  subclass INTEGER DEFAULT 0,
  patch INTEGER DEFAULT 0,
  inventory_type INTEGER DEFAULT 0,
  item_level INTEGER DEFAULT 0,
  required_level INTEGER DEFAULT 0,
  allowable_class INTEGER DEFAULT -1,
  buy_price INTEGER DEFAULT 0,
  sell_price INTEGER DEFAULT 0,
  -- 10 stats
  stat_type1 INTEGER, stat_value1 INTEGER,
  stat_type2 INTEGER, stat_value2 INTEGER,
  stat_type3 INTEGER, stat_value3 INTEGER,
  stat_type4 INTEGER, stat_value4 INTEGER,
  stat_type5 INTEGER, stat_value5 INTEGER,
  stat_type6 INTEGER, stat_value6 INTEGER,
  stat_type7 INTEGER, stat_value7 INTEGER,
  stat_type8 INTEGER, stat_value8 INTEGER,
  stat_type9 INTEGER, stat_value9 INTEGER,
  stat_type10 INTEGER, stat_value10 INTEGER,
  -- weapon
  delay INTEGER, dmg_min1 REAL, dmg_max1 REAL, dmg_type1 INTEGER,
  dmg_min2 REAL, dmg_max2 REAL, dmg_type2 INTEGER,
  dmg_min3 REAL, dmg_max3 REAL, dmg_type3 INTEGER,
  dmg_min4 REAL, dmg_max4 REAL, dmg_type4 INTEGER,
  dmg_min5 REAL, dmg_max5 REAL, dmg_type5 INTEGER,
  -- armor / defense
  armor INTEGER DEFAULT 0,
  block INTEGER DEFAULT 0,
  -- resist
  holy_res INTEGER DEFAULT 0,
  fire_res INTEGER DEFAULT 0,
  nature_res INTEGER DEFAULT 0,
  frost_res INTEGER DEFAULT 0,
  shadow_res INTEGER DEFAULT 0,
  arcane_res INTEGER DEFAULT 0,
  -- spells
  spellid_1 INTEGER, spelltrigger_1 INTEGER, spellcharges_1 INTEGER, spellppmrate_1 REAL, spellcooldown_1 INTEGER,
  spellid_2 INTEGER, spelltrigger_2 INTEGER, spellcharges_2 INTEGER, spellppmrate_2 REAL, spellcooldown_2 INTEGER,
  spellid_3 INTEGER, spelltrigger_3 INTEGER, spellcharges_3 INTEGER, spellppmrate_3 REAL, spellcooldown_3 INTEGER,
  spellid_4 INTEGER, spelltrigger_4 INTEGER, spellcharges_4 INTEGER, spellppmrate_4 REAL, spellcooldown_4 INTEGER,
  spellid_5 INTEGER, spelltrigger_5 INTEGER, spellcharges_5 INTEGER, spellppmrate_5 REAL, spellcooldown_5 INTEGER,
  -- misc
  set_id INTEGER, max_durability INTEGER
);

CREATE VIRTUAL TABLE items_fts USING fts5(entry, name, description, content=items, content_rowid=entry, tokenize='unicode61');

-- Version meta
CREATE TABLE data_version (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  patch_version TEXT NOT NULL,
  build_date TEXT NOT NULL,
  source TEXT,
  source_url TEXT,
  item_count INTEGER,
  max_item_level INTEGER,
  schema_version INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);

-- Changed items (vs previous DB). changed_fields is comma list e.g. 'armor,block'
CREATE TABLE item_changes (
  entry INTEGER PRIMARY KEY,
  changed_fields TEXT
);

CREATE INDEX idx_items_quality ON items(quality);
CREATE INDEX idx_items_level ON items(item_level);
CREATE INDEX idx_items_class ON items(class, subclass);
EOF

echo "[build_db_1157] Importing CSV -> items" 

# Write a temporary import script for sqlite (requires consistent column ordering)
python3 - <<'PY'
import csv, sqlite3, os, sys
root = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(root, 'build', 'items_mega_enhanced.sqlite')
csv_path = os.path.join(root, 'data_sources', '1157', 'items_core.csv')

con = sqlite3.connect(db_path)
cur = con.cursor()

with open(csv_path, newline='', encoding='utf-8') as f:
    r = csv.DictReader(f)
    rows = 0
    for row in r:
        # Minimal field normalization helpers
        def gi(key, default=0):
            v = row.get(key, '')
            if v == '' or v is None: return default
            try: return int(float(v))
            except: return default
        def gf(key, default=0.0):
            v = row.get(key, '')
            if v == '' or v is None: return default
            try: return float(v)
            except: return default
        def gs(key):
            v = row.get(key, '')
            return v if v is not None else ''

        data = {
            'entry': gi('entry'), 'name': gs('name'), 'description': gs('description'), 'quality': gi('quality'),
            'class': gi('class'), 'subclass': gi('subclass'), 'patch': gi('patch'), 'inventory_type': gi('inventory_type'),
            'item_level': gi('item_level'), 'required_level': gi('required_level'), 'allowable_class': gi('allowable_class', -1),
            'buy_price': gi('buy_price'), 'sell_price': gi('sell_price'),
            # stats
        }
        for i in range(1,11):
            data[f'stat_type{i}'] = gi(f'stat_type{i}')
            data[f'stat_value{i}'] = gi(f'stat_value{i}')
        # weapon
        data['delay'] = gi('delay')
        for i in range(1,6):
            data[f'dmg_min{i}'] = gf(f'dmg_min{i}')
            data[f'dmg_max{i}'] = gf(f'dmg_max{i}')
            data[f'dmg_type{i}'] = gi(f'dmg_type{i}')
        # defense
        data['armor'] = gi('armor')
        data['block'] = gi('block')
        # resist
        for res in ['holy_res','fire_res','nature_res','frost_res','shadow_res','arcane_res']:
            data[res] = gi(res)
        # spells
        for i in range(1,6):
            for col in ['spellid','spelltrigger','spellcharges','spellppmrate','spellcooldown']:
                key = f'{col}_{i}'
                if 'ppmrate' in col:
                    data[key] = float(row.get(key,'') or 0) if row.get(key,'') else 0
                else:
                    data[key] = gi(key)
        data['set_id'] = gi('set_id')
        data['max_durability'] = gi('max_durability')

        cols = ','.join(data.keys())
        placeholders = ','.join(['?']*len(data))
        cur.execute(f'INSERT OR REPLACE INTO items ({cols}) VALUES ({placeholders})', list(data.values()))
        rows +=1
        if rows % 2000 ==0:
            print(f'  imported {rows} rows')

con.commit()
print(f'Imported {rows} items')

# FTS
cur.execute("INSERT INTO items_fts(entry, name, description) SELECT entry, name, description FROM items")
con.commit()
con.close()
PY

echo "[build_db_1157] Computing version metadata"
ITEM_COUNT=$(sqlite3 "$OUT_DB" 'SELECT COUNT(*) FROM items;')
MAX_ILVL=$(sqlite3 "$OUT_DB" 'SELECT MAX(item_level) FROM items;')

sqlite3 "$OUT_DB" <<EOF
INSERT INTO data_version(patch_version, build_date, source, source_url, item_count, max_item_level, schema_version)
VALUES('$PATCH_VERSION', '$BUILD_DATE', '$SOURCE_LABEL', '$SOURCE_URL', $ITEM_COUNT, $MAX_ILVL, $SCHEMA_VERSION);
EOF

if [ -n "$PREV_DB" ] && [ -f "$PREV_DB" ]; then
  echo "[build_db_1157] Calculating per-item changes vs $PREV_DB" 
  sqlite3 "$OUT_DB" <<EOF
  ATTACH DATABASE '$PREV_DB' AS olddb;
  INSERT INTO item_changes(entry, changed_fields)
  SELECT n.entry,
         trim(
           (CASE WHEN IFNULL(n.armor,0) != IFNULL(o.armor,0) THEN 'armor,' ELSE '' END) ||
           (CASE WHEN IFNULL(n.block,0) != IFNULL(o.block,0) THEN 'block,' ELSE '' END)
         , ',') AS changed_fields
  FROM items n
  LEFT JOIN olddb.items o ON o.entry = n.entry
  WHERE (IFNULL(n.armor,0) != IFNULL(o.armor,0)) OR (IFNULL(n.block,0) != IFNULL(o.block,0));
EOF

  echo "entry,oldArmor,newArmor,deltaArmor,oldBlock,newBlock,deltaBlock" > "$BUILD_DIR/item_changes_report.csv"
  sqlite3 -csv "$OUT_DB" "ATTACH DATABASE '$PREV_DB' AS olddb; SELECT n.entry, IFNULL(o.armor,0), IFNULL(n.armor,0), (IFNULL(n.armor,0)-IFNULL(o.armor,0)), IFNULL(o.block,0), IFNULL(n.block,0), (IFNULL(n.block,0)-IFNULL(o.block,0)) FROM items n LEFT JOIN olddb.items o ON o.entry = n.entry WHERE n.entry IN (SELECT entry FROM item_changes);" >> "$BUILD_DIR/item_changes_report.csv"
fi

echo "[build_db_1157] Done. Output: $OUT_DB"
