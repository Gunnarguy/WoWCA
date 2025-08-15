#!/usr/bin/env python3

import re
import sqlite3
from collections import defaultdict

def analyze_spell_discrepancies():
    """Analyze all spells to find discrepancies between builds and create comprehensive fixes."""
    
    print("Analyzing spell discrepancies across all builds...")
    
    # Read the list of spell IDs we need
    with open('used_spell_ids.txt', 'r') as f:
        needed_spell_ids = set(int(line.strip()) for line in f if line.strip().isdigit())
    
    # Store all versions of each spell
    spell_builds = defaultdict(list)  # spell_id -> [(build, name, effectBasePoints1)]
    
    # Read the SQL file and extract all spell variants
    with open('world_full_05_october_2019.sql', 'r', encoding='utf-8', errors='ignore') as f:
        inside_spell_template = False
        for line in f:
            if 'INSERT INTO `spell_template`' in line:
                inside_spell_template = True
                continue
            elif inside_spell_template and line.strip().startswith('INSERT INTO'):
                inside_spell_template = False
                continue
            
            if inside_spell_template and line.strip().startswith('(') and ',' in line:
                match = re.match(r'\((\d+),\s*(\d+),', line.strip())
                if match:
                    spell_id = int(match.group(1))
                    build = int(match.group(2))
                    if spell_id in needed_spell_ids:
                        try:
                            # Parse the line
                            data = line.strip()
                            if data.endswith('),'):
                                data = data[1:-2]
                            elif data.endswith(';'):
                                data = data[1:-2]
                            else:
                                data = data[1:-1]
                            
                            # Split fields carefully
                            fields = []
                            current_field = ""
                            in_quotes = False
                            quote_char = None
                            i = 0
                            
                            while i < len(data):
                                char = data[i]
                                if not in_quotes:
                                    if char in ("'", '"'):
                                        in_quotes = True
                                        quote_char = char
                                        current_field += char
                                    elif char == ',':
                                        fields.append(current_field.strip())
                                        current_field = ""
                                    else:
                                        current_field += char
                                else:
                                    current_field += char
                                    if char == quote_char and (i == 0 or data[i-1] != '\\'):
                                        in_quotes = False
                                        quote_char = None
                                i += 1
                            
                            if current_field.strip():
                                fields.append(current_field.strip())
                            
                            if len(fields) >= 122:
                                name1 = fields[121].strip("'\"") if len(fields) > 121 else ""
                                effect1 = int(fields[76]) if len(fields) > 76 and fields[76].lstrip('-').isdigit() else None
                                
                                if name1 and name1 != 'NULL' and name1 != '':
                                    spell_builds[spell_id].append((build, name1, effect1))
                        except Exception as e:
                            continue
    
    print(f"Found spell data for {len(spell_builds)} spells")
    
    # Analyze discrepancies
    discrepancies = []
    spell_damage_corrections = {}
    
    for spell_id, builds in spell_builds.items():
        if len(builds) <= 1:
            continue
        
        # Look for spell damage discrepancies
        spell_damage_values = {}
        for build, name, effect1 in builds:
            # Extract spell damage from name
            match = re.search(r'Increase Spell Dam (\d+)', name)
            if match:
                value = int(match.group(1))
                spell_damage_values[build] = value
        
        if len(spell_damage_values) >= 2:
            values = list(spell_damage_values.values())
            builds_list = list(spell_damage_values.keys())
            
            # Check for significant discrepancies
            min_val = min(values)
            max_val = max(values)
            
            if max_val - min_val >= 5:  # Significant difference
                # Get build 4222 and 5875 values specifically
                val_4222 = spell_damage_values.get(4222)
                val_5875 = spell_damage_values.get(5875)
                
                if val_4222 and val_5875 and val_4222 != val_5875:
                    discrepancies.append({
                        'spell_id': spell_id,
                        'build_4222': val_4222,
                        'build_5875': val_5875,
                        'difference': abs(val_5875 - val_4222),
                        'all_builds': spell_damage_values
                    })
                    
                    # Apply heuristic: if 5875 is significantly higher, prefer 4222
                    # This is based on the pattern that newer builds often have inflated values
                    if val_5875 > val_4222 and (val_5875 - val_4222) >= 5:
                        spell_damage_corrections[spell_id] = 4222
                        print(f"Spell {spell_id}: Build 5875 shows {val_5875}, Build 4222 shows {val_4222} - preferring {val_4222}")
    
    print(f"\nFound {len(discrepancies)} spells with significant spell damage discrepancies")
    print(f"Generated corrections for {len(spell_damage_corrections)} spells")
    
    # Show some examples
    print("\nTop 10 discrepancies:")
    sorted_discrepancies = sorted(discrepancies, key=lambda x: x['difference'], reverse=True)
    for disc in sorted_discrepancies[:10]:
        print(f"Spell {disc['spell_id']}: Build 4222={disc['build_4222']}, Build 5875={disc['build_5875']}, diff={disc['difference']}")
    
    # Save the corrections to a file
    with open('spell_build_corrections.py', 'w') as f:
        f.write("# Auto-generated spell build corrections based on discrepancy analysis\n")
        f.write("# Prefer older builds when newer builds show significantly inflated values\n\n")
        f.write("SPELL_BUILD_CORRECTIONS = {\n")
        for spell_id, preferred_build in sorted(spell_damage_corrections.items()):
            f.write(f"    {spell_id}: {preferred_build},  # Spell damage discrepancy detected\n")
        f.write("}\n")
    
    print(f"\nSaved corrections to spell_build_corrections.py")
    return spell_damage_corrections

if __name__ == "__main__":
    analyze_spell_discrepancies()
