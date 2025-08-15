#!/usr/bin/env python3

import re
import sqlite3
import os
from collections import defaultdict

def build_items_with_patch_priority():
    """
    Rebuild items database with intelligent patch priority.
    When multiple versions of an item exist, prefer higher patch numbers.
    """
    
    print("Building items database with patch priority logic...")
    
    root = os.path.dirname(os.path.abspath(__file__))
    db_path = os.path.join(root, 'WoWCA', 'items.sqlite')
    src_sql = os.path.join(root, 'classic-wow-item-db', 'db', 'unmodified.sql')
    
    # Read and group all item versions by entry ID
    print("Reading source data and grouping by entry ID...")
    items_by_entry = defaultdict(list)
    
    with open(src_sql, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    insert_re = re.compile(r"INSERT INTO `items` .*? VALUES\s*(.*?);", re.DOTALL)
    
    processed = 0
    for payload in insert_re.findall(content):
        # Extract tuples from payload
        depth = 0
        current = []
        tuples = []
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
        
        for raw in tuples:
            try:
                values = eval(raw)
                if len(values) >= 110:  # Ensure we have all required fields
                    entry_id = values[0]
                    patch = values[1]
                    items_by_entry[entry_id].append((patch, values))
                    processed += 1
            except:
                continue
    
    print(f"Processed {processed} item records for {len(items_by_entry)} unique items")
    
    # Select best version for each item (highest patch number)
    print("Selecting best version for each item (preferring higher patches)...")
    final_items = {}
    conflicts_resolved = 0
    
    for entry_id, versions in items_by_entry.items():
        if len(versions) == 1:
            # Single version, use it
            final_items[entry_id] = versions[0][1]
        else:
            # Multiple versions, prefer highest patch number
            best_patch = max(v[0] for v in versions)
            best_versions = [v for v in versions if v[0] == best_patch]
            
            # If still multiple with same patch, take the first one
            final_items[entry_id] = best_versions[0][1]
            conflicts_resolved += 1
            
            # Log conflicts for armor values
            armor_values = [v[1][66] for v in versions if len(v[1]) > 66 and v[1][66] > 0]
            if len(set(armor_values)) > 1:
                name = versions[0][1][4] if len(versions[0][1]) > 4 else "Unknown"
                print(f"  Resolved armor conflict for {entry_id} ({name}): patches {[v[0] for v in versions]} -> selected patch {best_patch}")
    
    print(f"Resolved {conflicts_resolved} version conflicts")
    
    # Now insert into database
    print("Creating database with selected item versions...")
    
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    
    # Clear existing items (but keep schema)
    cur.execute("DELETE FROM items")
    
    inserted = 0
    for entry_id, values in final_items.items():
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
        cur.execute(f"INSERT INTO items ({cols}) VALUES ({ph})", list(item.values()))
        inserted += 1
        
        if inserted % 2000 == 0:
            print(f"  Inserted {inserted} items...")
    
    print(f"Inserted {inserted} items total")
    
    # Rebuild FTS index
    print("Rebuilding FTS index...")
    cur.execute("DELETE FROM items_fts")
    cur.execute("INSERT INTO items_fts(entry,name,description) SELECT entry,name,description FROM items")
    
    con.commit()
    con.close()
    
    print("Database rebuild complete with patch priority logic!")

if __name__ == '__main__':
    build_items_with_patch_priority()
