#!/usr/bin/env python3

import re
import sqlite3
import sys

def extract_spell_data():
    # Read the list of spell IDs we need
    with open('used_spell_ids.txt', 'r') as f:
        needed_spell_ids = set(int(line.strip()) for line in f if line.strip().isdigit())
    
    print(f"Looking for {len(needed_spell_ids)} spell IDs...")
    
    # Read the SQL file and extract spell entries
    found_spells = []
    with open('world_full_05_october_2019.sql', 'r', encoding='utf-8', errors='ignore') as f:
        inside_spell_template = False
        for line in f:
            # Check if we're in a spell_template INSERT section
            if 'INSERT INTO `spell_template`' in line:
                inside_spell_template = True
                continue
            elif inside_spell_template and line.strip().startswith('INSERT INTO'):
                inside_spell_template = False
                continue
            
            # Process spell data lines
            if inside_spell_template and line.strip().startswith('(') and ',' in line:
                # Try to extract spell ID (first field)
                match = re.match(r'\((\d+),', line.strip())
                if match:
                    spell_id = int(match.group(1))
                    if spell_id in needed_spell_ids:
                        # Parse the line more carefully
                        try:
                            # Remove the leading ( and trailing ),
                            data = line.strip()
                            if data.endswith('),'):
                                data = data[1:-2]  # Remove ( at start and ), at end
                            elif data.endswith(';'):
                                data = data[1:-2]  # Remove ( at start and ); at end
                            else:
                                data = data[1:-1]  # Remove ( at start and ) at end
                            
                            # Split by commas, but respect quoted strings
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
                            
                            # Add the last field
                            if current_field.strip():
                                fields.append(current_field.strip())
                            
                            if len(fields) >= 140:  # Ensure we have enough fields
                                # name1 is field 122 (0-indexed: 121), description1 is field 140 (0-indexed: 139)
                                name1 = fields[121].strip("'\"") if len(fields) > 121 else ""
                                description1 = fields[139].strip("'\"") if len(fields) > 139 else ""
                                
                                if name1 and name1 != 'NULL' and name1 != '':
                                    found_spells.append((spell_id, name1, description1))
                                    print(f"Found spell {spell_id}: {name1}")
                        except Exception as e:
                            print(f"Error parsing spell {spell_id}: {e}")
                            continue
    
    print(f"Found {len(found_spells)} spells with names")
    
    # Connect to the app database and insert the spell data
    conn = sqlite3.connect('WoWCA/items.sqlite')
    cursor = conn.cursor()
    
    # Clear existing data and insert new
    cursor.execute("DELETE FROM spell_template WHERE entry > 0")
    
    for spell_id, name, description in found_spells:
        cursor.execute("""
            INSERT OR REPLACE INTO spell_template (entry, name1, description1)
            VALUES (?, ?, ?)
        """, (spell_id, name, description))
    
    conn.commit()
    conn.close()
    
    print(f"Inserted {len(found_spells)} spells into the database")

if __name__ == "__main__":
    extract_spell_data()
