#!/bin/bash
set -euo pipefail

# Simplified enhanced database builder for WoW Classic items with weapon stats
OUT_DIR="build"
OUT_SQLITE="$OUT_DIR/items_enhanced.sqlite"
RESOURCES_DIR="Resources"

echo "[build_db_enhanced] Creating enhanced SQLite database with weapon stats"
rm -rf "$OUT_SQLITE"
mkdir -p "$OUT_DIR"

if [ ! -d "classic-wow-item-db" ]; then
    echo "[build_db_enhanced] Cloning data source"
    git clone --depth 1 https://github.com/thatsmybis/classic-wow-item-db.git
fi

sqlite3 "$OUT_SQLITE" <<'EOF'
-- Create enhanced items table with weapon stats
CREATE TABLE items (
    entry INTEGER PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    quality INTEGER NOT NULL DEFAULT 0,
    class INTEGER DEFAULT 0,
    subclass INTEGER DEFAULT 0,
    inventory_type INTEGER DEFAULT 0,
    item_level INTEGER DEFAULT 0,
    required_level INTEGER DEFAULT 0,
    
    -- Basic stats (first 4)
    stat_type1 INTEGER DEFAULT NULL,
    stat_value1 INTEGER DEFAULT NULL,
    stat_type2 INTEGER DEFAULT NULL,
    stat_value2 INTEGER DEFAULT NULL,
    stat_type3 INTEGER DEFAULT NULL,
    stat_value3 INTEGER DEFAULT NULL,
    stat_type4 INTEGER DEFAULT NULL,
    stat_value4 INTEGER DEFAULT NULL,
    
    -- Weapon stats
    delay INTEGER DEFAULT NULL,  -- Attack speed in milliseconds
    dmg_min1 REAL DEFAULT NULL,
    dmg_max1 REAL DEFAULT NULL,
    dmg_type1 INTEGER DEFAULT NULL,
    
    -- Armor and basic resistances
    armor INTEGER DEFAULT NULL,
    fire_res INTEGER DEFAULT NULL,
    nature_res INTEGER DEFAULT NULL,
    frost_res INTEGER DEFAULT NULL,
    shadow_res INTEGER DEFAULT NULL,
    
    -- Basic info
    allowable_class INTEGER DEFAULT NULL,
    buy_price INTEGER DEFAULT NULL,
    sell_price INTEGER DEFAULT NULL
);
EOF

echo "[build_db_enhanced] Processing MySQL dump with correct field mapping"
python3 << 'PYTHON_SCRIPT'
import re
import sqlite3

# Read the MySQL dump
with open('classic-wow-item-db/db/unmodified.sql', 'r') as f:
    content = f.read()

# Connect to our SQLite database
conn = sqlite3.connect('build/items_enhanced.sqlite')
cursor = conn.cursor()

# Correct field mapping based on the actual INSERT statement order
FIELDS = [
    'item_id', 'patch', 'class', 'subclass', 'name', 'description', 'display_id', 
    'quality', 'flags', 'buy_count', 'buy_price', 'sell_price', 'inventory_type', 
    'allowable_class', 'allowable_race', 'item_level', 'required_level', 
    'required_skill', 'required_skill_rank', 'required_spell', 'required_honor_rank', 
    'required_city_rank', 'required_reputation_faction', 'required_reputation_rank', 
    'max_count', 'stackable', 'container_slots', 
    'stat_type1', 'stat_value1', 'stat_type2', 'stat_value2', 'stat_type3', 'stat_value3',
    'stat_type4', 'stat_value4', 'stat_type5', 'stat_value5', 'stat_type6', 'stat_value6',
    'stat_type7', 'stat_value7', 'stat_type8', 'stat_value8', 'stat_type9', 'stat_value9',
    'stat_type10', 'stat_value10', 
    'delay', 'range_mod', 'ammo_type', 
    'dmg_min1', 'dmg_max1', 'dmg_type1', 'dmg_min2', 'dmg_max2', 'dmg_type2',
    'dmg_min3', 'dmg_max3', 'dmg_type3', 'dmg_min4', 'dmg_max4', 'dmg_type4',
    'dmg_min5', 'dmg_max5', 'dmg_type5', 'block', 
    'armor', 'holy_res', 'fire_res', 'nature_res', 'frost_res', 'shadow_res', 'arcane_res'
    # ... and more fields but we'll stop here for now
]

def safe_convert(value, target_type, default=None):
    """Safely convert a value to target type with fallback"""
    if value is None or value == '' or value == 'NULL':
        return default
    try:
        value_str = str(value).strip().strip("'")
        if target_type == int:
            return int(float(value_str)) if value_str else default
        elif target_type == float:
            return float(value_str) if value_str else default
        else:
            return value_str.replace("\\'", "''")
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
            
            # Parse CSV-like data handling nested quotes
            values = []
            current_value = ""
            in_quotes = False
            i = 0
            
            while i < len(inner):
                char = inner[i]
                
                if char == "'" and (i == 0 or inner[i-1] != "\\"):
                    in_quotes = not in_quotes
                    current_value += char
                elif char == "," and not in_quotes:
                    values.append(current_value.strip())
                    current_value = ""
                else:
                    current_value += char
                i += 1
            
            # Add the last value
            if current_value.strip():
                values.append(current_value.strip())
            
            # Skip if we don't have enough fields
            if len(values) < 60:
                continue
                
            # Extract the fields we need using correct positions
            entry = safe_convert(values[0], int)  # item_id
            name = safe_convert(values[4], str, '')  # name
            quality = safe_convert(values[7], int, 0)  # quality
            item_class = safe_convert(values[2], int)  # class
            subclass = safe_convert(values[3], int)  # subclass
            inventory_type = safe_convert(values[12], int)  # inventory_type
            item_level = safe_convert(values[15], int)  # item_level
            required_level = safe_convert(values[16], int)  # required_level
            allowable_class = safe_convert(values[13], int)  # allowable_class
            buy_price = safe_convert(values[10], int)  # buy_price
            sell_price = safe_convert(values[11], int)  # sell_price
            
            # Stats
            stat_type1 = safe_convert(values[27], int)  # stat_type1
            stat_value1 = safe_convert(values[28], int)  # stat_value1
            stat_type2 = safe_convert(values[29], int)  # stat_type2
            stat_value2 = safe_convert(values[30], int)  # stat_value2
            stat_type3 = safe_convert(values[31], int)  # stat_type3
            stat_value3 = safe_convert(values[32], int)  # stat_value3
            stat_type4 = safe_convert(values[33], int)  # stat_type4
            stat_value4 = safe_convert(values[34], int)  # stat_value4
            
            # Weapon data
            delay = safe_convert(values[47], int)  # delay (field 48, index 47)
            dmg_min1 = safe_convert(values[50], float)  # dmg_min1 (field 51, index 50)
            dmg_max1 = safe_convert(values[51], float)  # dmg_max1 (field 52, index 51)
            dmg_type1 = safe_convert(values[52], int)  # dmg_type1 (field 53, index 52)
            
            # Armor and resistances  
            armor = safe_convert(values[62], int) if len(values) > 62 else None  # armor (field 63, index 62)
            fire_res = safe_convert(values[65], int) if len(values) > 65 else None  # fire_res (field 66, index 65)
            nature_res = safe_convert(values[66], int) if len(values) > 66 else None  # nature_res (field 67, index 66)
            frost_res = safe_convert(values[67], int) if len(values) > 67 else None  # frost_res (field 68, index 67)
            shadow_res = safe_convert(values[68], int) if len(values) > 68 else None  # shadow_res (field 69, index 68)
            
            # Skip items without valid entry or name
            if not entry or not name:
                continue
            
            # Build and execute INSERT statement
            insert_sql = """
            INSERT OR IGNORE INTO items (
                entry, name, quality, class, subclass, inventory_type, item_level, required_level,
                stat_type1, stat_value1, stat_type2, stat_value2, stat_type3, stat_value3,
                stat_type4, stat_value4, delay, dmg_min1, dmg_max1, dmg_type1,
                armor, fire_res, nature_res, frost_res, shadow_res,
                allowable_class, buy_price, sell_price
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            cursor.execute(insert_sql, (
                entry, name, quality, item_class, subclass, inventory_type, item_level, required_level,
                stat_type1, stat_value1, stat_type2, stat_value2, stat_type3, stat_value3,
                stat_type4, stat_value4, delay, dmg_min1, dmg_max1, dmg_type1,
                armor, fire_res, nature_res, frost_res, shadow_res,
                allowable_class, buy_price, sell_price
            ))
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
CREATE INDEX idx_items_inventory_type ON items(inventory_type);
CREATE INDEX idx_items_item_level ON items(item_level);
CREATE INDEX idx_items_delay ON items(delay);

-- Optimize database
ANALYZE;
VACUUM;
EOF

echo "[build_db_enhanced] Testing enhanced search with weapon stats"
echo "Sample weapon data for Flurry Axe:"
sqlite3 "$OUT_SQLITE" "SELECT entry, name, dmg_min1, dmg_max1, delay, quality, item_level FROM items WHERE entry = 871;"

echo ""
echo "All weapons with damage data (first 5):"
sqlite3 "$OUT_SQLITE" "SELECT entry, name, dmg_min1, dmg_max1, delay FROM items WHERE dmg_min1 > 0 LIMIT 5;"

echo "[build_db_enhanced] Copying enhanced database to Resources"
mkdir -p "$RESOURCES_DIR"
cp "$OUT_SQLITE" "$RESOURCES_DIR/items_enhanced.sqlite"

echo "[build_db_enhanced] Success! Enhanced database created at $RESOURCES_DIR/items_enhanced.sqlite"
echo "[build_db_enhanced] Total items: $ITEM_COUNT"
echo ""
echo "Enhanced features added:"
echo "- Weapon damage and attack speed"
echo "- First 4 stat types and values"
echo "- Armor and elemental resistances"
echo "- Item level, class restrictions, and pricing"
