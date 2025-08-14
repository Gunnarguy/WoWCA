#!/bin/bash
set -euo pipefail

# Enhanced database builder for WoW Classic items with full weapon stats and more
OUT_DIR="build"
OUT_SQLITE="$OUT_DIR/items_enhanced.sqlite"
RESOURCES_DIR="Resources"

echo "[build_db_enhanced] Cleaning up"
rm -rf "$OUT_DIR/items_enhanced.sqlite"
mkdir -p "$OUT_DIR"

if [ ! -d "classic-wow-item-db" ]; then
    echo "[build_db_enhanced] Cloning data source"
    git clone --depth 1 https://github.com/thatsmybis/classic-wow-item-db.git
fi

echo "[build_db_enhanced] Creating enhanced SQLite database with comprehensive item data"
sqlite3 "$OUT_SQLITE" <<'EOF'
-- Create the enhanced items table with full weapon and item stats
CREATE TABLE items (
    entry INTEGER PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    quality INTEGER NOT NULL DEFAULT 0,
    class INTEGER DEFAULT 0,
    subclass INTEGER DEFAULT 0,
    inventory_type INTEGER DEFAULT 0,
    item_level INTEGER DEFAULT 0,
    required_level INTEGER DEFAULT 0,
    
    -- All 10 stat types and values
    stat_type1 INTEGER DEFAULT NULL,
    stat_value1 INTEGER DEFAULT NULL,
    stat_type2 INTEGER DEFAULT NULL,
    stat_value2 INTEGER DEFAULT NULL,
    stat_type3 INTEGER DEFAULT NULL,
    stat_value3 INTEGER DEFAULT NULL,
    stat_type4 INTEGER DEFAULT NULL,
    stat_value4 INTEGER DEFAULT NULL,
    stat_type5 INTEGER DEFAULT NULL,
    stat_value5 INTEGER DEFAULT NULL,
    stat_type6 INTEGER DEFAULT NULL,
    stat_value6 INTEGER DEFAULT NULL,
    stat_type7 INTEGER DEFAULT NULL,
    stat_value7 INTEGER DEFAULT NULL,
    stat_type8 INTEGER DEFAULT NULL,
    stat_value8 INTEGER DEFAULT NULL,
    stat_type9 INTEGER DEFAULT NULL,
    stat_value9 INTEGER DEFAULT NULL,
    stat_type10 INTEGER DEFAULT NULL,
    stat_value10 INTEGER DEFAULT NULL,
    
    -- Weapon stats
    delay INTEGER DEFAULT NULL,  -- Attack speed in milliseconds
    dmg_min1 REAL DEFAULT NULL,
    dmg_max1 REAL DEFAULT NULL,
    dmg_type1 INTEGER DEFAULT NULL,
    dmg_min2 REAL DEFAULT NULL,
    dmg_max2 REAL DEFAULT NULL,
    dmg_type2 INTEGER DEFAULT NULL,
    dmg_min3 REAL DEFAULT NULL,
    dmg_max3 REAL DEFAULT NULL,
    dmg_type3 INTEGER DEFAULT NULL,
    dmg_min4 REAL DEFAULT NULL,
    dmg_max4 REAL DEFAULT NULL,
    dmg_type4 INTEGER DEFAULT NULL,
    dmg_min5 REAL DEFAULT NULL,
    dmg_max5 REAL DEFAULT NULL,
    dmg_type5 INTEGER DEFAULT NULL,
    
    -- Armor and resistances
    armor INTEGER DEFAULT NULL,
    holy_res INTEGER DEFAULT NULL,
    fire_res INTEGER DEFAULT NULL,
    nature_res INTEGER DEFAULT NULL,
    frost_res INTEGER DEFAULT NULL,
    shadow_res INTEGER DEFAULT NULL,
    arcane_res INTEGER DEFAULT NULL,
    
    -- Spell effects (first 3 most common)
    spellid_1 INTEGER DEFAULT NULL,
    spelltrigger_1 INTEGER DEFAULT NULL,
    spellcharges_1 INTEGER DEFAULT NULL,
    spellppmrate_1 REAL DEFAULT NULL,
    spellcooldown_1 INTEGER DEFAULT NULL,
    
    spellid_2 INTEGER DEFAULT NULL,
    spelltrigger_2 INTEGER DEFAULT NULL,
    spellcharges_2 INTEGER DEFAULT NULL,
    spellppmrate_2 REAL DEFAULT NULL,
    spellcooldown_2 INTEGER DEFAULT NULL,
    
    spellid_3 INTEGER DEFAULT NULL,
    spelltrigger_3 INTEGER DEFAULT NULL,
    spellcharges_3 INTEGER DEFAULT NULL,
    spellppmrate_3 REAL DEFAULT NULL,
    spellcooldown_3 INTEGER DEFAULT NULL,
    
    -- Set bonuses and other useful fields
    set_id INTEGER DEFAULT NULL,
    allowable_class INTEGER DEFAULT NULL,
    buy_price INTEGER DEFAULT NULL,
    sell_price INTEGER DEFAULT NULL,
    max_durability INTEGER DEFAULT NULL
);
EOF

echo "[build_db_enhanced] Processing MySQL dump to extract comprehensive item data"
python3 << 'PYTHON_SCRIPT'
import re
import sqlite3

# Read the MySQL dump
with open('classic-wow-item-db/db/unmodified.sql', 'r') as f:
    content = f.read()

# Connect to our SQLite database
conn = sqlite3.connect('build/items_enhanced.sqlite')
cursor = conn.cursor()

# Field mapping from MySQL dump based on the actual field order in the schema
# This maps to positions in the VALUES tuples
FIELD_POSITIONS = {
    'entry': 0,           # item_id
    'name': 1,            # name  
    'quality': 14,        # quality
    'class': 16,          # class
    'subclass': 17,       # subclass
    'inventory_type': 23, # inventory_type
    'allowable_class': 24, # allowable_class
    'item_level': 26,     # item_level
    'required_level': 27, # required_level
    'buy_price': 21,      # buy_price
    'sell_price': 22,     # sell_price
    
    # Stats (stat_type1 through stat_type10, stat_value1 through stat_value10)
    'stat_type1': 34, 'stat_value1': 35,
    'stat_type2': 36, 'stat_value2': 37,
    'stat_type3': 38, 'stat_value3': 39,
    'stat_type4': 40, 'stat_value4': 41,
    'stat_type5': 42, 'stat_value5': 43,
    'stat_type6': 44, 'stat_value6': 45,
    'stat_type7': 46, 'stat_value7': 47,
    'stat_type8': 48, 'stat_value8': 49,
    'stat_type9': 50, 'stat_value9': 51,
    'stat_type10': 52, 'stat_value10': 53,
    
    # Weapon data
    'delay': 54,
    'dmg_min1': 56, 'dmg_max1': 57, 'dmg_type1': 58,
    'dmg_min2': 59, 'dmg_max2': 60, 'dmg_type2': 61,
    'dmg_min3': 62, 'dmg_max3': 63, 'dmg_type3': 64,
    'dmg_min4': 65, 'dmg_max4': 66, 'dmg_type4': 67,
    'dmg_min5': 68, 'dmg_max5': 69, 'dmg_type5': 70,
    
    # Armor and resistances
    'armor': 72,
    'holy_res': 73, 'fire_res': 74, 'nature_res': 75,
    'frost_res': 76, 'shadow_res': 77, 'arcane_res': 78,
    
    # Spell effects
    'spellid_1': 79, 'spelltrigger_1': 80, 'spellcharges_1': 81,
    'spellppmrate_1': 82, 'spellcooldown_1': 83,
    'spellid_2': 85, 'spelltrigger_2': 86, 'spellcharges_2': 87,
    'spellppmrate_2': 88, 'spellcooldown_2': 89,
    'spellid_3': 91, 'spelltrigger_3': 92, 'spellcharges_3': 93,
    'spellppmrate_3': 94, 'spellcooldown_3': 95,
    
    # Other useful fields
    'set_id': 113,
    'max_durability': 114,
}

def safe_convert(value, target_type, default=None):
    """Safely convert a value to target type with fallback"""
    if value is None or value == '' or value == 'NULL':
        return default
    try:
        if target_type == int:
            return int(float(value.strip("'")))
        elif target_type == float:
            return float(value.strip("'"))
        else:
            return str(value).strip("'")
    except (ValueError, AttributeError):
        return default

# Find all data tuples between the INSERT statements
insert_sections = re.findall(r'INSERT INTO `items`.*?VALUES\s*(.*?)(?=INSERT INTO|$)', content, re.DOTALL)

count = 0
for section in insert_sections:
    # Find all tuples in this section
    tuple_pattern = r'\([^)]+(?:\([^)]*\)[^)]*)*\)'
    tuples = re.findall(tuple_pattern, section)
    
    for tuple_str in tuples:
        try:
            # Remove outer parentheses
            inner = tuple_str[1:-1]
            
            # Parse CSV-like data handling nested quotes and parentheses
            values = []
            current_value = ""
            in_quotes = False
            paren_depth = 0
            i = 0
            
            while i < len(inner):
                char = inner[i]
                
                if char == "'" and (i == 0 or inner[i-1] != "\\"):
                    in_quotes = not in_quotes
                    current_value += char
                elif char == "(" and not in_quotes:
                    paren_depth += 1
                    current_value += char
                elif char == ")" and not in_quotes:
                    paren_depth -= 1
                    current_value += char
                elif char == "," and not in_quotes and paren_depth == 0:
                    values.append(current_value.strip())
                    current_value = ""
                else:
                    current_value += char
                i += 1
            
            # Add the last value
            if current_value.strip():
                values.append(current_value.strip())
            
            # Skip if we don't have enough fields
            if len(values) < 80:
                continue
                
            # Extract all the fields we need
            item_data = {}
            
            # Basic item info
            item_data['entry'] = safe_convert(values[FIELD_POSITIONS['entry']], int)
            item_data['name'] = safe_convert(values[FIELD_POSITIONS['name']], str, '').replace("\\'", "''")
            item_data['quality'] = safe_convert(values[FIELD_POSITIONS['quality']], int, 0)
            item_data['class'] = safe_convert(values[FIELD_POSITIONS['class']], int)
            item_data['subclass'] = safe_convert(values[FIELD_POSITIONS['subclass']], int)
            item_data['inventory_type'] = safe_convert(values[FIELD_POSITIONS['inventory_type']], int)
            item_data['item_level'] = safe_convert(values[FIELD_POSITIONS['item_level']], int)
            item_data['required_level'] = safe_convert(values[FIELD_POSITIONS['required_level']], int)
            item_data['allowable_class'] = safe_convert(values[FIELD_POSITIONS['allowable_class']], int)
            item_data['buy_price'] = safe_convert(values[FIELD_POSITIONS['buy_price']], int)
            item_data['sell_price'] = safe_convert(values[FIELD_POSITIONS['sell_price']], int)
            
            # All stats
            for i in range(1, 11):
                item_data[f'stat_type{i}'] = safe_convert(values[FIELD_POSITIONS[f'stat_type{i}']], int)
                item_data[f'stat_value{i}'] = safe_convert(values[FIELD_POSITIONS[f'stat_value{i}']], int)
            
            # Weapon data
            item_data['delay'] = safe_convert(values[FIELD_POSITIONS['delay']], int)
            for i in range(1, 6):
                item_data[f'dmg_min{i}'] = safe_convert(values[FIELD_POSITIONS[f'dmg_min{i}']], float)
                item_data[f'dmg_max{i}'] = safe_convert(values[FIELD_POSITIONS[f'dmg_max{i}']], float)
                item_data[f'dmg_type{i}'] = safe_convert(values[FIELD_POSITIONS[f'dmg_type{i}']], int)
            
            # Armor and resistances
            item_data['armor'] = safe_convert(values[FIELD_POSITIONS['armor']], int)
            for res in ['holy_res', 'fire_res', 'nature_res', 'frost_res', 'shadow_res', 'arcane_res']:
                item_data[res] = safe_convert(values[FIELD_POSITIONS[res]], int)
            
            # Spell effects
            for i in range(1, 4):
                item_data[f'spellid_{i}'] = safe_convert(values[FIELD_POSITIONS[f'spellid_{i}']], int)
                item_data[f'spelltrigger_{i}'] = safe_convert(values[FIELD_POSITIONS[f'spelltrigger_{i}']], int)
                item_data[f'spellcharges_{i}'] = safe_convert(values[FIELD_POSITIONS[f'spellcharges_{i}']], int)
                item_data[f'spellppmrate_{i}'] = safe_convert(values[FIELD_POSITIONS[f'spellppmrate_{i}']], float)
                item_data[f'spellcooldown_{i}'] = safe_convert(values[FIELD_POSITIONS[f'spellcooldown_{i}']], int)
            
            # Other fields
            item_data['set_id'] = safe_convert(values[FIELD_POSITIONS['set_id']], int)
            item_data['max_durability'] = safe_convert(values[FIELD_POSITIONS['max_durability']], int)
            
            # Skip items without valid entry or name
            if not item_data['entry'] or not item_data['name']:
                continue
            
            # Build and execute INSERT statement
            insert_sql = """
            INSERT OR IGNORE INTO items (
                entry, name, quality, class, subclass, inventory_type, item_level, required_level,
                stat_type1, stat_value1, stat_type2, stat_value2, stat_type3, stat_value3,
                stat_type4, stat_value4, stat_type5, stat_value5, stat_type6, stat_value6,
                stat_type7, stat_value7, stat_type8, stat_value8, stat_type9, stat_value9,
                stat_type10, stat_value10,
                delay, dmg_min1, dmg_max1, dmg_type1, dmg_min2, dmg_max2, dmg_type2,
                dmg_min3, dmg_max3, dmg_type3, dmg_min4, dmg_max4, dmg_type4,
                dmg_min5, dmg_max5, dmg_type5,
                armor, holy_res, fire_res, nature_res, frost_res, shadow_res, arcane_res,
                spellid_1, spelltrigger_1, spellcharges_1, spellppmrate_1, spellcooldown_1,
                spellid_2, spelltrigger_2, spellcharges_2, spellppmrate_2, spellcooldown_2,
                spellid_3, spelltrigger_3, spellcharges_3, spellppmrate_3, spellcooldown_3,
                set_id, allowable_class, buy_price, sell_price, max_durability
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            values_tuple = (
                item_data['entry'], item_data['name'], item_data['quality'],
                item_data['class'], item_data['subclass'], item_data['inventory_type'],
                item_data['item_level'], item_data['required_level'],
                item_data['stat_type1'], item_data['stat_value1'], item_data['stat_type2'], item_data['stat_value2'],
                item_data['stat_type3'], item_data['stat_value3'], item_data['stat_type4'], item_data['stat_value4'],
                item_data['stat_type5'], item_data['stat_value5'], item_data['stat_type6'], item_data['stat_value6'],
                item_data['stat_type7'], item_data['stat_value7'], item_data['stat_type8'], item_data['stat_value8'],
                item_data['stat_type9'], item_data['stat_value9'], item_data['stat_type10'], item_data['stat_value10'],
                item_data['delay'], item_data['dmg_min1'], item_data['dmg_max1'], item_data['dmg_type1'],
                item_data['dmg_min2'], item_data['dmg_max2'], item_data['dmg_type2'],
                item_data['dmg_min3'], item_data['dmg_max3'], item_data['dmg_type3'],
                item_data['dmg_min4'], item_data['dmg_max4'], item_data['dmg_type4'],
                item_data['dmg_min5'], item_data['dmg_max5'], item_data['dmg_type5'],
                item_data['armor'], item_data['holy_res'], item_data['fire_res'],
                item_data['nature_res'], item_data['frost_res'], item_data['shadow_res'], item_data['arcane_res'],
                item_data['spellid_1'], item_data['spelltrigger_1'], item_data['spellcharges_1'],
                item_data['spellppmrate_1'], item_data['spellcooldown_1'],
                item_data['spellid_2'], item_data['spelltrigger_2'], item_data['spellcharges_2'],
                item_data['spellppmrate_2'], item_data['spellcooldown_2'],
                item_data['spellid_3'], item_data['spelltrigger_3'], item_data['spellcharges_3'],
                item_data['spellppmrate_3'], item_data['spellcooldown_3'],
                item_data['set_id'], item_data['allowable_class'], item_data['buy_price'],
                item_data['sell_price'], item_data['max_durability']
            )
            
            cursor.execute(insert_sql, values_tuple)
            count += 1
            
            if count % 1000 == 0:
                print(f"Processed {count} items...")
                
        except Exception as e:
            # Skip problematic entries
            if "UNIQUE constraint failed" not in str(e):
                print(f"Error processing item: {e}")
            continue

print(f"Successfully inserted {count} items with enhanced data")
conn.commit()
conn.close()
PYTHON_SCRIPT

echo "[build_db_enhanced] Verifying enhanced data"
ITEM_COUNT=$(sqlite3 "$OUT_SQLITE" "SELECT COUNT(*) FROM items;")
echo "[build_db_enhanced] Inserted $ITEM_COUNT items"

if [ "$ITEM_COUNT" -lt 1000 ]; then
    echo "ERROR: Too few items inserted ($ITEM_COUNT)"
    exit 1
fi

echo "[build_db_enhanced] Creating FTS5 index and additional indexes"
sqlite3 "$OUT_SQLITE" <<'EOF'
-- Create FTS5 virtual table for fast search
CREATE VIRTUAL TABLE items_fts USING fts5(
    entry UNINDEXED,
    name,
    tokenize='unicode61 remove_diacritics 2'
);

-- Populate FTS index
INSERT INTO items_fts(entry, name)
SELECT entry, name FROM items WHERE name IS NOT NULL AND name != '';

-- Create helpful indexes for common queries
CREATE INDEX idx_items_entry ON items(entry);
CREATE INDEX idx_items_quality ON items(quality);
CREATE INDEX idx_items_class ON items(class);
CREATE INDEX idx_items_subclass ON items(subclass);
CREATE INDEX idx_items_inventory_type ON items(inventory_type);
CREATE INDEX idx_items_item_level ON items(item_level);
CREATE INDEX idx_items_required_level ON items(required_level);
CREATE INDEX idx_items_delay ON items(delay);

-- Optimize database
ANALYZE;
VACUUM;
EOF

echo "[build_db_enhanced] Testing enhanced search with weapon stats"
echo "Sample weapon data for Flurry Axe:"
sqlite3 "$OUT_SQLITE" "SELECT entry, name, dmg_min1, dmg_max1, delay, armor FROM items WHERE entry = 871;"

echo "[build_db_enhanced] Copying enhanced database to Resources"
mkdir -p "$RESOURCES_DIR"
cp "$OUT_SQLITE" "$RESOURCES_DIR/items_enhanced.sqlite"

echo "[build_db_enhanced] Success! Enhanced database created at $RESOURCES_DIR/items_enhanced.sqlite"
echo "[build_db_enhanced] Total items: $ITEM_COUNT"
echo ""
echo "Enhanced features added:"
echo "- All 10 stat types and values"
echo "- Weapon damage (up to 5 damage types per weapon)"
echo "- Attack speed (delay in milliseconds)"
echo "- Armor and all resistances"
echo "- Spell effects and procs"
echo "- Set bonuses, durability, and prices"
