#!/usr/bin/env bash
set -euo pipefail

# build_db.sh - Single authoritative Classic WoW item database builder
#
# Features:
#  - Full 129-column mega schema (all stats, damages, resistances, 5 spell slots, quest/set/page/etc.)
#  - FTS5 search table (items_fts)
#  - Version metadata table (data_version)
#  - Optional diff vs previous DB (item_changes table with changed field list)
#  - Copies final DB to Resources/items.sqlite for the app bundle
#
# Usage:
#   ./build_db.sh [PREVIOUS_DB_PATH]
#   PREVIOUS_DB_PATH (optional) path to earlier items.sqlite to compute changes.
#
# Environment overrides:
#   PATCH_VERSION (default: 1.15.7)
#   BUILD_DATE    (default: UTC today)
#   SOURCE_LABEL  (default: thatsmybis/classic-wow-item-db)
#   SOURCE_URL    (default: https://github.com/thatsmybis/classic-wow-item-db)
#   SCHEMA_VERSION (default: 3)
#
# Outputs:
#   build/items.sqlite (authoritative build)
#   build/item_changes_report.csv (if previous DB provided)

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$ROOT_DIR/build"
OUT_DB="$BUILD_DIR/items.sqlite"
SRC_SQL="$ROOT_DIR/classic-wow-item-db/db/unmodified.sql"
PREV_DB="${1:-}"

PATCH_VERSION=${PATCH_VERSION:-1.15.7}
BUILD_DATE=${BUILD_DATE:-$(date -u +%F)}
SOURCE_LABEL=${SOURCE_LABEL:-thatsmybis/classic-wow-item-db}
SOURCE_URL=${SOURCE_URL:-https://github.com/thatsmybis/classic-wow-item-db}
SCHEMA_VERSION=${SCHEMA_VERSION:-3}

mkdir -p "$BUILD_DIR"

if [ ! -f "$SRC_SQL" ]; then
  echo "ERROR: Source SQL not found: $SRC_SQL" >&2
  echo "Clone the data source repo: git clone --depth 1 https://github.com/thatsmybis/classic-wow-item-db.git" >&2
  exit 1
fi

echo "[build_db] Creating schema (mega + metadata)"
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
    
	display_id INTEGER DEFAULT 0,
	inventory_type INTEGER DEFAULT 0,
	flags INTEGER DEFAULT 0,
    
	buy_count INTEGER DEFAULT 1,
	buy_price INTEGER DEFAULT 0,
	sell_price INTEGER DEFAULT 0,
    
	item_level INTEGER DEFAULT 0,
	required_level INTEGER DEFAULT 0,
	required_skill INTEGER DEFAULT 0,
	required_skill_rank INTEGER DEFAULT 0,
	required_spell INTEGER DEFAULT 0,
	required_honor_rank INTEGER DEFAULT 0,
	required_city_rank INTEGER DEFAULT 0,
	required_reputation_faction INTEGER DEFAULT 0,
	required_reputation_rank INTEGER DEFAULT 0,
    
	allowable_class INTEGER DEFAULT -1,
	allowable_race INTEGER DEFAULT -1,
    
	max_count INTEGER DEFAULT 0,
	stackable INTEGER DEFAULT 1,
	container_slots INTEGER DEFAULT 0,
	bonding INTEGER DEFAULT 0,
	material INTEGER DEFAULT 0,
	sheath INTEGER DEFAULT 0,
    
	stat_type1 INTEGER DEFAULT 0,  stat_value1 INTEGER DEFAULT 0,
	stat_type2 INTEGER DEFAULT 0,  stat_value2 INTEGER DEFAULT 0,
	stat_type3 INTEGER DEFAULT 0,  stat_value3 INTEGER DEFAULT 0,
	stat_type4 INTEGER DEFAULT 0,  stat_value4 INTEGER DEFAULT 0,
	stat_type5 INTEGER DEFAULT 0,  stat_value5 INTEGER DEFAULT 0,
	stat_type6 INTEGER DEFAULT 0,  stat_value6 INTEGER DEFAULT 0,
	stat_type7 INTEGER DEFAULT 0,  stat_value7 INTEGER DEFAULT 0,
	stat_type8 INTEGER DEFAULT 0,  stat_value8 INTEGER DEFAULT 0,
	stat_type9 INTEGER DEFAULT 0,  stat_value9 INTEGER DEFAULT 0,
	stat_type10 INTEGER DEFAULT 0, stat_value10 INTEGER DEFAULT 0,
    
	delay INTEGER DEFAULT 0,
	range_mod REAL DEFAULT 0,
	ammo_type INTEGER DEFAULT 0,
    
	dmg_min1 REAL DEFAULT 0, dmg_max1 REAL DEFAULT 0, dmg_type1 INTEGER DEFAULT 0,
	dmg_min2 REAL DEFAULT 0, dmg_max2 REAL DEFAULT 0, dmg_type2 INTEGER DEFAULT 0,
	dmg_min3 REAL DEFAULT 0, dmg_max3 REAL DEFAULT 0, dmg_type3 INTEGER DEFAULT 0,
	dmg_min4 REAL DEFAULT 0, dmg_max4 REAL DEFAULT 0, dmg_type4 INTEGER DEFAULT 0,
	dmg_min5 REAL DEFAULT 0, dmg_max5 REAL DEFAULT 0, dmg_type5 INTEGER DEFAULT 0,
    
	block INTEGER DEFAULT 0,
	armor INTEGER DEFAULT 0,
    
	holy_res INTEGER DEFAULT 0,
	fire_res INTEGER DEFAULT 0,
	nature_res INTEGER DEFAULT 0,
	frost_res INTEGER DEFAULT 0,
	shadow_res INTEGER DEFAULT 0,
	arcane_res INTEGER DEFAULT 0,
    
	spellid_1 INTEGER DEFAULT 0,
	spelltrigger_1 INTEGER DEFAULT 0,
	spellcharges_1 INTEGER DEFAULT 0,
	spellppmrate_1 REAL DEFAULT 0,
	spellcooldown_1 INTEGER DEFAULT -1,
	spellcategory_1 INTEGER DEFAULT 0,
	spellcategorycooldown_1 INTEGER DEFAULT -1,
    
	spellid_2 INTEGER DEFAULT 0,
	spelltrigger_2 INTEGER DEFAULT 0,
	spellcharges_2 INTEGER DEFAULT 0,
	spellppmrate_2 REAL DEFAULT 0,
	spellcooldown_2 INTEGER DEFAULT -1,
	spellcategory_2 INTEGER DEFAULT 0,
	spellcategorycooldown_2 INTEGER DEFAULT -1,
    
	spellid_3 INTEGER DEFAULT 0,
	spelltrigger_3 INTEGER DEFAULT 0,
	spellcharges_3 INTEGER DEFAULT 0,
	spellppmrate_3 REAL DEFAULT 0,
	spellcooldown_3 INTEGER DEFAULT -1,
	spellcategory_3 INTEGER DEFAULT 0,
	spellcategorycooldown_3 INTEGER DEFAULT -1,
    
	spellid_4 INTEGER DEFAULT 0,
	spelltrigger_4 INTEGER DEFAULT 0,
	spellcharges_4 INTEGER DEFAULT 0,
	spellppmrate_4 REAL DEFAULT 0,
	spellcooldown_4 INTEGER DEFAULT -1,
	spellcategory_4 INTEGER DEFAULT 0,
	spellcategorycooldown_4 INTEGER DEFAULT -1,
    
	spellid_5 INTEGER DEFAULT 0,
	spelltrigger_5 INTEGER DEFAULT 0,
	spellcharges_5 INTEGER DEFAULT 0,
	spellppmrate_5 REAL DEFAULT 0,
	spellcooldown_5 INTEGER DEFAULT -1,
	spellcategory_5 INTEGER DEFAULT 0,
	spellcategorycooldown_5 INTEGER DEFAULT -1,
    
	page_text INTEGER DEFAULT 0,
	page_language INTEGER DEFAULT 0,
	page_material INTEGER DEFAULT 0,
	start_quest INTEGER DEFAULT 0,
	lock_id INTEGER DEFAULT 0,
	random_property INTEGER DEFAULT 0,
	set_id INTEGER DEFAULT 0,
	max_durability INTEGER DEFAULT 0,
	area_bound INTEGER DEFAULT 0,
	map_bound INTEGER DEFAULT 0,
	duration INTEGER DEFAULT 0,
	bag_family INTEGER DEFAULT 0,
	disenchant_id INTEGER DEFAULT 0,
	food_type INTEGER DEFAULT 0,
	min_money_loot INTEGER DEFAULT 0,
	max_money_loot INTEGER DEFAULT 0,
	extra_flags INTEGER DEFAULT 0,
	other_team_entry INTEGER DEFAULT 1
);

CREATE VIRTUAL TABLE items_fts USING fts5(
  entry,
  name,
  description,
  content=items,
  content_rowid=entry,
  tokenize='unicode61'
);

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

CREATE TABLE item_changes (
  entry INTEGER PRIMARY KEY,
  changed_fields TEXT
);

CREATE INDEX idx_items_class ON items(class, subclass);
CREATE INDEX idx_items_quality ON items(quality);
CREATE INDEX idx_items_level ON items(item_level);
CREATE INDEX idx_items_set ON items(set_id);
CREATE INDEX idx_items_spellids ON items(spellid_1, spellid_2, spellid_3, spellid_4, spellid_5);
EOF

echo "[build_db] Parsing & importing items (this can take a moment)"

python3 - <<'PY'
import re, sqlite3, os, sys
root = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(root, 'build', 'items.sqlite')
src_sql = os.path.join(root, 'classic-wow-item-db', 'db', 'unmodified.sql')

con = sqlite3.connect(db_path)
cur = con.cursor()

with open(src_sql, 'r', encoding='utf-8', errors='ignore') as f:
	content = f.read()

# The INSERT statements can span many lines and contain thousands of tuples separated by commas and newlines.
# Strategy: find each INSERT ... VALUES <payload> ;  then scan payload extracting top-level parenthesis groups.
insert_re = re.compile(r"INSERT INTO `items` .*? VALUES\s*(.*?);", re.DOTALL)

processed = inserted = 0

def extract_tuples(payload: str):
	tuples = []
	depth = 0
	current = []
	for ch in payload:
		if ch == '(':
			if depth == 0:
				current = []
			depth += 1
			current.append(ch)
		elif ch == ')':
			current.append(ch)
			depth -= 1
			if depth == 0:
				tuples.append(''.join(current))
		else:
			if depth > 0:
				current.append(ch)
	return tuples

for payload in insert_re.findall(content):
	for raw in extract_tuples(payload):
		try:
			values = eval(raw)
		except Exception:
			continue
		processed += 1
		if not isinstance(values, (list, tuple)) or len(values) < 110:
			continue
		# Map positions to our mega schema (mirrors previous mega script ordering)
		def gv(i, default=0):
			return values[i] if i < len(values) else default
		item = {
			'entry': gv(0), 'patch': gv(1), 'class': gv(2), 'subclass': gv(3), 'name': gv(4), 'description': gv(5),
			'display_id': gv(6), 'quality': gv(7), 'flags': gv(8), 'buy_count': gv(9), 'buy_price': gv(10), 'sell_price': gv(11),
			'inventory_type': gv(12), 'allowable_class': gv(13), 'allowable_race': gv(14), 'item_level': gv(15), 'required_level': gv(16),
			'required_skill': gv(17), 'required_skill_rank': gv(18), 'required_spell': gv(19), 'required_honor_rank': gv(20),
			'required_city_rank': gv(21), 'required_reputation_faction': gv(22), 'required_reputation_rank': gv(23), 'max_count': gv(24),
			'stackable': gv(25), 'container_slots': gv(26),
			'stat_type1': gv(27), 'stat_value1': gv(28), 'stat_type2': gv(29), 'stat_value2': gv(30), 'stat_type3': gv(31), 'stat_value3': gv(32),
			'stat_type4': gv(33), 'stat_value4': gv(34), 'stat_type5': gv(35), 'stat_value5': gv(36), 'stat_type6': gv(37), 'stat_value6': gv(38),
			'stat_type7': gv(39), 'stat_value7': gv(40), 'stat_type8': gv(41), 'stat_value8': gv(42), 'stat_type9': gv(43), 'stat_value9': gv(44),
			'stat_type10': gv(45), 'stat_value10': gv(46), 'delay': gv(47), 'range_mod': gv(48), 'ammo_type': gv(49),
			'dmg_min1': gv(50), 'dmg_max1': gv(51), 'dmg_type1': gv(52), 'dmg_min2': gv(53), 'dmg_max2': gv(54), 'dmg_type2': gv(55),
			'dmg_min3': gv(56), 'dmg_max3': gv(57), 'dmg_type3': gv(58), 'dmg_min4': gv(59), 'dmg_max4': gv(60), 'dmg_type4': gv(61),
			'dmg_min5': gv(62), 'dmg_max5': gv(63), 'dmg_type5': gv(64), 'block': gv(65), 'armor': gv(66), 'holy_res': gv(67), 'fire_res': gv(68),
			'nature_res': gv(69), 'frost_res': gv(70), 'shadow_res': gv(71), 'arcane_res': gv(72), 'spellid_1': gv(73), 'spelltrigger_1': gv(74),
			'spellcharges_1': gv(75), 'spellppmrate_1': gv(76), 'spellcooldown_1': gv(77), 'spellcategory_1': gv(78), 'spellcategorycooldown_1': gv(79),
			'spellid_2': gv(80), 'spelltrigger_2': gv(81), 'spellcharges_2': gv(82), 'spellppmrate_2': gv(83), 'spellcooldown_2': gv(84), 'spellcategory_2': gv(85), 'spellcategorycooldown_2': gv(86),
			'spellid_3': gv(87), 'spelltrigger_3': gv(88), 'spellcharges_3': gv(89), 'spellppmrate_3': gv(90), 'spellcooldown_3': gv(91), 'spellcategory_3': gv(92), 'spellcategorycooldown_3': gv(93),
			'spellid_4': gv(94), 'spelltrigger_4': gv(95), 'spellcharges_4': gv(96), 'spellppmrate_4': gv(97), 'spellcooldown_4': gv(98), 'spellcategory_4': gv(99), 'spellcategorycooldown_4': gv(100),
			'spellid_5': gv(101), 'spelltrigger_5': gv(102), 'spellcharges_5': gv(103), 'spellppmrate_5': gv(104), 'spellcooldown_5': gv(105), 'spellcategory_5': gv(106), 'spellcategorycooldown_5': gv(107),
			'bonding': gv(108), 'page_text': gv(109), 'page_language': gv(110), 'page_material': gv(111), 'start_quest': gv(112), 'lock_id': gv(113), 'material': gv(114), 'sheath': gv(115), 'random_property': gv(116), 'set_id': gv(117), 'max_durability': gv(118), 'area_bound': gv(119), 'map_bound': gv(120), 'duration': gv(121), 'bag_family': gv(122), 'disenchant_id': gv(123), 'food_type': gv(124), 'min_money_loot': gv(125), 'max_money_loot': gv(126), 'extra_flags': gv(127), 'other_team_entry': gv(128)
		}
		cols = ','.join(item.keys())
		ph = ','.join(['?']*len(item))
		cur.execute(f"INSERT OR REPLACE INTO items ({cols}) VALUES ({ph})", list(item.values()))
		inserted += 1
		if inserted and inserted % 2000 == 0:
			print(f"  inserted {inserted} items (processed {processed})")

print(f"Processed {processed} raw tuples, inserted {inserted} items")
cur.execute("INSERT INTO items_fts(entry,name,description) SELECT entry,name,description FROM items")
con.commit(); con.close()
PY

echo "[build_db] Inserting version metadata"
sqlite3 "$OUT_DB" <<EOF
INSERT INTO data_version(patch_version, build_date, source, source_url, item_count, max_item_level, schema_version)
SELECT '$PATCH_VERSION', '$BUILD_DATE', '$SOURCE_LABEL', '$SOURCE_URL', COUNT(*), MAX(item_level), $SCHEMA_VERSION FROM items;
EOF

if [ -n "$PREV_DB" ] && [ -f "$PREV_DB" ]; then
  echo "[build_db] Computing changes vs $PREV_DB"
  python3 - <<PY
import sqlite3, os, csv, sys
new_db = os.path.join('${ROOT_DIR}', 'build', 'items.sqlite')
prev_db = os.path.abspath('${PREV_DB}')
out_csv = os.path.join('${ROOT_DIR}', 'build', 'item_changes_report.csv')

cols_to_track = [
  'armor','block','item_level','quality','set_id','max_durability'
]

new = sqlite3.connect(new_db)
prev = sqlite3.connect(prev_db)
nc = new.cursor(); pc = prev.cursor()

pc.execute('SELECT entry,' + ','.join(cols_to_track) + ' FROM items')
prev_map = {r[0]: r[1:] for r in pc.fetchall()}

changes = []
nc.execute('SELECT entry,name,' + ','.join(cols_to_track) + ' FROM items')
for row in nc.fetchall():
	entry, name, *vals = row
	if entry not in prev_map: continue
	old_vals = prev_map[entry]
	changed_fields = [c for c,(ov,nv) in zip(cols_to_track, zip(old_vals, vals)) if ov != nv]
	if changed_fields:
		changes.append((entry, ','.join(changed_fields)))

if changes:
	nc.executemany('INSERT OR REPLACE INTO item_changes(entry, changed_fields) VALUES (?,?)', changes)
	with open(out_csv, 'w', newline='') as f:
		w = csv.writer(f); w.writerow(['entry','changed_fields']); w.writerows(changes)
	new.commit()
	print(f"Recorded {len(changes)} changed items; CSV at {out_csv}")
else:
	print('No changes detected vs previous DB')

new.close(); prev.close()
PY
fi

echo "[build_db] Sanity checks"
sqlite3 "$OUT_DB" "SELECT COUNT(*)||' items, max iLvl '||MAX(item_level) FROM items;" | sed 's/^/  /'
sqlite3 "$OUT_DB" "SELECT COUNT(*) FROM data_version;" | sed 's/^/  version rows: /'

echo "[build_db] Copying to Resources/items.sqlite"
cp "$OUT_DB" "$ROOT_DIR/Resources/items.sqlite"

echo "✅ build complete: $OUT_DB"

