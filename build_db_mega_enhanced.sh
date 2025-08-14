#!/bin/bash
# build_db_mega_enhanced.sh - Extract EVERY possible stat and ability from Classic WoW items

echo "🔥 Building MEGA Enhanced Classic WoW Item Database with ALL nerdy info..."

cd /Users/gunnarhostetler/Documents/GitHub/WoWCA

# Remove old database
rm -f build/items_mega_enhanced.sqlite

# Create the mega enhanced database with ALL fields
sqlite3 build/items_mega_enhanced.sqlite << 'EOF'
-- Create mega enhanced items table with ALL possible fields
CREATE TABLE items (
    -- Basic Item Info
    entry INTEGER PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    description TEXT DEFAULT '',
    quality INTEGER NOT NULL DEFAULT 0,
    class INTEGER DEFAULT 0,
    subclass INTEGER DEFAULT 0,
    patch INTEGER DEFAULT 0,
    
    -- Display & UI
    display_id INTEGER DEFAULT 0,
    inventory_type INTEGER DEFAULT 0,
    flags INTEGER DEFAULT 0,
    
    -- Economy
    buy_count INTEGER DEFAULT 1,
    buy_price INTEGER DEFAULT 0,
    sell_price INTEGER DEFAULT 0,
    
    -- Level & Requirements
    item_level INTEGER DEFAULT 0,
    required_level INTEGER DEFAULT 0,
    required_skill INTEGER DEFAULT 0,
    required_skill_rank INTEGER DEFAULT 0,
    required_spell INTEGER DEFAULT 0,
    required_honor_rank INTEGER DEFAULT 0,
    required_city_rank INTEGER DEFAULT 0,
    required_reputation_faction INTEGER DEFAULT 0,
    required_reputation_rank INTEGER DEFAULT 0,
    
    -- Class & Race Restrictions
    allowable_class INTEGER DEFAULT -1,
    allowable_race INTEGER DEFAULT -1,
    
    -- Item Properties
    max_count INTEGER DEFAULT 0,
    stackable INTEGER DEFAULT 1,
    container_slots INTEGER DEFAULT 0,
    bonding INTEGER DEFAULT 0,
    material INTEGER DEFAULT 0,
    sheath INTEGER DEFAULT 0,
    
    -- ALL 10 Stat Slots!
    stat_type1 INTEGER DEFAULT 0,
    stat_value1 INTEGER DEFAULT 0,
    stat_type2 INTEGER DEFAULT 0,
    stat_value2 INTEGER DEFAULT 0,
    stat_type3 INTEGER DEFAULT 0,
    stat_value3 INTEGER DEFAULT 0,
    stat_type4 INTEGER DEFAULT 0,
    stat_value4 INTEGER DEFAULT 0,
    stat_type5 INTEGER DEFAULT 0,
    stat_value5 INTEGER DEFAULT 0,
    stat_type6 INTEGER DEFAULT 0,
    stat_value6 INTEGER DEFAULT 0,
    stat_type7 INTEGER DEFAULT 0,
    stat_value7 INTEGER DEFAULT 0,
    stat_type8 INTEGER DEFAULT 0,
    stat_value8 INTEGER DEFAULT 0,
    stat_type9 INTEGER DEFAULT 0,
    stat_value9 INTEGER DEFAULT 0,
    stat_type10 INTEGER DEFAULT 0,
    stat_value10 INTEGER DEFAULT 0,
    
    -- Weapon Stats
    delay INTEGER DEFAULT 0,
    range_mod REAL DEFAULT 0,
    ammo_type INTEGER DEFAULT 0,
    
    -- ALL 5 Damage Types!
    dmg_min1 REAL DEFAULT 0,
    dmg_max1 REAL DEFAULT 0,
    dmg_type1 INTEGER DEFAULT 0,
    dmg_min2 REAL DEFAULT 0,
    dmg_max2 REAL DEFAULT 0,
    dmg_type2 INTEGER DEFAULT 0,
    dmg_min3 REAL DEFAULT 0,
    dmg_max3 REAL DEFAULT 0,
    dmg_type3 INTEGER DEFAULT 0,
    dmg_min4 REAL DEFAULT 0,
    dmg_max4 REAL DEFAULT 0,
    dmg_type4 INTEGER DEFAULT 0,
    dmg_min5 REAL DEFAULT 0,
    dmg_max5 REAL DEFAULT 0,
    dmg_type5 INTEGER DEFAULT 0,
    
    -- Armor & Block
    block INTEGER DEFAULT 0,
    armor INTEGER DEFAULT 0,
    
    -- ALL Resistances!
    holy_res INTEGER DEFAULT 0,
    fire_res INTEGER DEFAULT 0,
    nature_res INTEGER DEFAULT 0,
    frost_res INTEGER DEFAULT 0,
    shadow_res INTEGER DEFAULT 0,
    arcane_res INTEGER DEFAULT 0,
    
    -- ALL 5 Spell Slots!
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
    
    -- Special Properties
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

-- Create FTS5 table for search
CREATE VIRTUAL TABLE items_fts USING fts5(
    entry,
    name,
    description,
    content=items,
    content_rowid=entry,
    tokenize='unicode61'
);

-- Create indexes for performance
CREATE INDEX idx_items_class ON items(class);
CREATE INDEX idx_items_quality ON items(quality);
CREATE INDEX idx_items_level ON items(item_level);
CREATE INDEX idx_items_set ON items(set_id);
CREATE INDEX idx_items_spells ON items(spellid_1, spellid_2, spellid_3, spellid_4, spellid_5);
EOF

# Extract ALL data with Python parser
python3 << 'EOF'
import sqlite3
import re

print("🔍 Parsing full Classic WoW database with ALL fields...")

# Connect to database
conn = sqlite3.connect('build/items_mega_enhanced.sqlite')
cursor = conn.cursor()

# Read the unmodified database file
with open('classic-wow-item-db/db/unmodified.sql', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Find all INSERT statements
insert_pattern = r"INSERT INTO `items` \([^)]+\) VALUES\s*(.*?)(?=INSERT|\Z)"
inserts = re.findall(insert_pattern, content, re.DOTALL)

print(f"Found {len(inserts)} INSERT statements")

items_processed = 0
items_inserted = 0

for insert_block in inserts:
    # Split by lines and process each VALUES clause
    lines = insert_block.strip().split('\n')
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('--') or not line.startswith('('):
            continue
            
        # Remove trailing comma and semicolon
        line = line.rstrip(',;')
        
        try:
            # Use eval to parse the tuple (dangerous but works for clean data)
            values = eval(line)
            items_processed += 1
            
            if len(values) >= 111:  # Should have all fields
                # Map ALL the fields according to the schema
                item_data = {
                    'entry': values[0],  # item_id
                    'patch': values[1],
                    'class': values[2], 
                    'subclass': values[3],
                    'name': values[4],
                    'description': values[5],
                    'display_id': values[6],
                    'quality': values[7],
                    'flags': values[8],
                    'buy_count': values[9],
                    'buy_price': values[10],
                    'sell_price': values[11],
                    'inventory_type': values[12],
                    'allowable_class': values[13],
                    'allowable_race': values[14],
                    'item_level': values[15],
                    'required_level': values[16],
                    'required_skill': values[17],
                    'required_skill_rank': values[18],
                    'required_spell': values[19],
                    'required_honor_rank': values[20],
                    'required_city_rank': values[21],
                    'required_reputation_faction': values[22],
                    'required_reputation_rank': values[23],
                    'max_count': values[24],
                    'stackable': values[25],
                    'container_slots': values[26],
                    
                    # ALL 10 stats!
                    'stat_type1': values[27], 'stat_value1': values[28],
                    'stat_type2': values[29], 'stat_value2': values[30],
                    'stat_type3': values[31], 'stat_value3': values[32],
                    'stat_type4': values[33], 'stat_value4': values[34],
                    'stat_type5': values[35], 'stat_value5': values[36],
                    'stat_type6': values[37], 'stat_value6': values[38],
                    'stat_type7': values[39], 'stat_value7': values[40],
                    'stat_type8': values[41], 'stat_value8': values[42],
                    'stat_type9': values[43], 'stat_value9': values[44],
                    'stat_type10': values[45], 'stat_value10': values[46],
                    
                    # Weapon stats
                    'delay': values[47],
                    'range_mod': values[48],
                    'ammo_type': values[49],
                    
                    # ALL 5 damage types!
                    'dmg_min1': values[50], 'dmg_max1': values[51], 'dmg_type1': values[52],
                    'dmg_min2': values[53], 'dmg_max2': values[54], 'dmg_type2': values[55],
                    'dmg_min3': values[56], 'dmg_max3': values[57], 'dmg_type3': values[58],
                    'dmg_min4': values[59], 'dmg_max4': values[60], 'dmg_type4': values[61],
                    'dmg_min5': values[62], 'dmg_max5': values[63], 'dmg_type5': values[64],
                    
                    # Armor and block
                    'block': values[65],
                    'armor': values[66],
                    
                    # ALL resistances!
                    'holy_res': values[67],
                    'fire_res': values[68],
                    'nature_res': values[69],
                    'frost_res': values[70],
                    'shadow_res': values[71],
                    'arcane_res': values[72],
                    
                    # ALL 5 spell slots!
                    'spellid_1': values[73], 'spelltrigger_1': values[74], 'spellcharges_1': values[75],
                    'spellppmrate_1': values[76], 'spellcooldown_1': values[77], 'spellcategory_1': values[78],
                    'spellcategorycooldown_1': values[79],
                    
                    'spellid_2': values[80], 'spelltrigger_2': values[81], 'spellcharges_2': values[82],
                    'spellppmrate_2': values[83], 'spellcooldown_2': values[84], 'spellcategory_2': values[85],
                    'spellcategorycooldown_2': values[86],
                    
                    'spellid_3': values[87], 'spelltrigger_3': values[88], 'spellcharges_3': values[89],
                    'spellppmrate_3': values[90], 'spellcooldown_3': values[91], 'spellcategory_3': values[92],
                    'spellcategorycooldown_3': values[93],
                    
                    'spellid_4': values[94], 'spelltrigger_4': values[95], 'spellcharges_4': values[96],
                    'spellppmrate_4': values[97], 'spellcooldown_4': values[98], 'spellcategory_4': values[99],
                    'spellcategorycooldown_4': values[100],
                    
                    'spellid_5': values[101], 'spelltrigger_5': values[102], 'spellcharges_5': values[103],
                    'spellppmrate_5': values[104], 'spellcooldown_5': values[105], 'spellcategory_5': values[106],
                    'spellcategorycooldown_5': values[107],
                    
                    # Special properties
                    'bonding': values[108],
                    'page_text': values[109],
                    'page_language': values[110],
                    'page_material': values[111] if len(values) > 111 else 0,
                    'start_quest': values[112] if len(values) > 112 else 0,
                    'lock_id': values[113] if len(values) > 113 else 0,
                    'material': values[114] if len(values) > 114 else 0,
                    'sheath': values[115] if len(values) > 115 else 0,
                    'random_property': values[116] if len(values) > 116 else 0,
                    'set_id': values[117] if len(values) > 117 else 0,
                    'max_durability': values[118] if len(values) > 118 else 0,
                    'area_bound': values[119] if len(values) > 119 else 0,
                    'map_bound': values[120] if len(values) > 120 else 0,
                    'duration': values[121] if len(values) > 121 else 0,
                    'bag_family': values[122] if len(values) > 122 else 0,
                    'disenchant_id': values[123] if len(values) > 123 else 0,
                    'food_type': values[124] if len(values) > 124 else 0,
                    'min_money_loot': values[125] if len(values) > 125 else 0,
                    'max_money_loot': values[126] if len(values) > 126 else 0,
                    'extra_flags': values[127] if len(values) > 127 else 0,
                    'other_team_entry': values[128] if len(values) > 128 else 1
                }
                
                # Build INSERT query
                columns = ', '.join(item_data.keys())
                placeholders = ', '.join(['?' for _ in item_data])
                
                cursor.execute(f"""
                    INSERT OR REPLACE INTO items ({columns})
                    VALUES ({placeholders})
                """, list(item_data.values()))
                
                items_inserted += 1
                
                if items_inserted % 1000 == 0:
                    print(f"  Processed {items_inserted} items...")
                    
        except Exception as e:
            print(f"Error processing item {items_processed}: {e}")
            continue

print(f"✅ Processed {items_processed} items, inserted {items_inserted} into database")

# Populate FTS index
print("🔍 Building full-text search index...")
cursor.execute("INSERT INTO items_fts(entry, name, description) SELECT entry, name, description FROM items")

# Commit and close
conn.commit()
conn.close()

print("🎉 MEGA Enhanced database created with ALL nerdy WoW Classic item data!")
EOF

echo "✅ MEGA Enhanced database built: build/items_mega_enhanced.sqlite"
echo "📊 Testing with Flurry Axe..."

# Test the mega database
sqlite3 build/items_mega_enhanced.sqlite "
SELECT 
    entry, name, spellid_1, spelltrigger_1, spellppmrate_1,
    stat_type5, stat_value5, stat_type6, stat_value6,
    holy_res, arcane_res, bonding, set_id
FROM items 
WHERE entry = 871;
"

echo "🔍 Sample items with special abilities..."
sqlite3 build/items_mega_enhanced.sqlite "
SELECT entry, name, spellid_1, spelltrigger_1, spellppmrate_1 
FROM items 
WHERE spellid_1 > 0 
LIMIT 5;
"

echo "⚔️ Items with multiple damage types..."
sqlite3 build/items_mega_enhanced.sqlite "
SELECT entry, name, dmg_min1, dmg_type1, dmg_min2, dmg_type2 
FROM items 
WHERE dmg_min2 > 0 
LIMIT 5;
"

echo "🎁 Set items..."
sqlite3 build/items_mega_enhanced.sqlite "
SELECT entry, name, set_id 
FROM items 
WHERE set_id > 0 
LIMIT 5;
"
