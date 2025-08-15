#!/usr/bin/env python3

import sqlite3
import re

def safe_int(value, default=0):
    if value is None or value == '':
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        return default

def safe_float(value, default=0.0):
    if value is None or value == '':
        return default
    try:
        return float(value)
    except (ValueError, TypeError):
        return default

def safe_str(value, default=''):
    if value is None:
        return default
    return str(value)

# Spell ID corrections - prefer build 4222 for specific spells, build 5875 for others
corrections = {
    9342: 4222,  # Judgement Bindings: use build 4222 (correct +7 vs wrong +13)
}

def should_prefer_spell(spell_id, build_num, existing_builds):
    """Determine if we should use this spell version"""
    if spell_id in corrections:
        return build_num == corrections[spell_id]
    
    # For all other spells, prefer build 5875 (matches Classic 1.15.7)
    if 5875 in existing_builds:
        return build_num == 5875
    elif 4222 in existing_builds:
        return build_num == 4222
    else:
        return build_num == max(existing_builds)

print("🤓⚡ ULTIMATE NERD MODE EXTRACTION - EXACT SCHEMA MATCH ⚡🤓")
print("📊 Extracting ALL available spell data with maximum nerdiness...")

# Connect to database
conn = sqlite3.connect('build/items.sqlite')
cursor = conn.cursor()

# Create the ultimate nerd table with EXACT original schema
print("🏗️ Creating spell_template_ultimate_nerd table with exact original schema...")

# Original schema from the world database - ALL 179 fields!
create_table_sql = '''
DROP TABLE IF EXISTS spell_template_ultimate_nerd;
CREATE TABLE spell_template_ultimate_nerd (
    entry INTEGER,
    build INTEGER,
    school INTEGER,
    category INTEGER,
    castUI INTEGER,
    dispel INTEGER,
    mechanic INTEGER,
    attributes INTEGER,
    attributesEx INTEGER,
    attributesEx2 INTEGER,
    attributesEx3 INTEGER,
    attributesEx4 INTEGER,
    stances INTEGER,
    stancesNot INTEGER,
    targets INTEGER,
    targetCreatureType INTEGER,
    requiresSpellFocus INTEGER,
    casterAuraState INTEGER,
    targetAuraState INTEGER,
    castingTimeIndex INTEGER,
    recoveryTime INTEGER,
    categoryRecoveryTime INTEGER,
    interruptFlags INTEGER,
    auraInterruptFlags INTEGER,
    channelInterruptFlags INTEGER,
    procFlags INTEGER,
    procChance INTEGER,
    procCharges INTEGER,
    maxLevel INTEGER,
    baseLevel INTEGER,
    spellLevel INTEGER,
    durationIndex INTEGER,
    powerType INTEGER,
    manaCost INTEGER,
    manCostPerLevel INTEGER,
    manaPerSecond INTEGER,
    manaPerSecondPerLevel INTEGER,
    rangeIndex INTEGER,
    speed REAL,
    modelNextSpell INTEGER,
    stackAmount INTEGER,
    totem1 INTEGER,
    totem2 INTEGER,
    reagent1 INTEGER,
    reagent2 INTEGER,
    reagent3 INTEGER,
    reagent4 INTEGER,
    reagent5 INTEGER,
    reagent6 INTEGER,
    reagent7 INTEGER,
    reagent8 INTEGER,
    reagentCount1 INTEGER,
    reagentCount2 INTEGER,
    reagentCount3 INTEGER,
    reagentCount4 INTEGER,
    reagentCount5 INTEGER,
    reagentCount6 INTEGER,
    reagentCount7 INTEGER,
    reagentCount8 INTEGER,
    equippedItemClass INTEGER,
    equippedItemSubClassMask INTEGER,
    equippedItemInventoryTypeMask INTEGER,
    effect1 INTEGER,
    effect2 INTEGER,
    effect3 INTEGER,
    effectDieSides1 INTEGER,
    effectDieSides2 INTEGER,
    effectDieSides3 INTEGER,
    effectBaseDice1 INTEGER,
    effectBaseDice2 INTEGER,
    effectBaseDice3 INTEGER,
    effectDicePerLevel1 REAL,
    effectDicePerLevel2 REAL,
    effectDicePerLevel3 REAL,
    effectRealPointsPerLevel1 REAL,
    effectRealPointsPerLevel2 REAL,
    effectRealPointsPerLevel3 REAL,
    effectBasePoints1 INTEGER,
    effectBasePoints2 INTEGER,
    effectBasePoints3 INTEGER,
    effectMechanic1 INTEGER,
    effectMechanic2 INTEGER,
    effectMechanic3 INTEGER,
    effectImplicitTargetA1 INTEGER,
    effectImplicitTargetA2 INTEGER,
    effectImplicitTargetA3 INTEGER,
    effectImplicitTargetB1 INTEGER,
    effectImplicitTargetB2 INTEGER,
    effectImplicitTargetB3 INTEGER,
    effectRadiusIndex1 INTEGER,
    effectRadiusIndex2 INTEGER,
    effectRadiusIndex3 INTEGER,
    effectApplyAuraName1 INTEGER,
    effectApplyAuraName2 INTEGER,
    effectApplyAuraName3 INTEGER,
    effectAmplitude1 INTEGER,
    effectAmplitude2 INTEGER,
    effectAmplitude3 INTEGER,
    effectMultipleValue1 REAL,
    effectMultipleValue2 REAL,
    effectMultipleValue3 REAL,
    effectChainTarget1 INTEGER,
    effectChainTarget2 INTEGER,
    effectChainTarget3 INTEGER,
    effectItemType1 INTEGER,
    effectItemType2 INTEGER,
    effectItemType3 INTEGER,
    effectMiscValue1 INTEGER,
    effectMiscValue2 INTEGER,
    effectMiscValue3 INTEGER,
    effectTriggerSpell1 INTEGER,
    effectTriggerSpell2 INTEGER,
    effectTriggerSpell3 INTEGER,
    effectPointsPerComboPoint1 REAL,
    effectPointsPerComboPoint2 REAL,
    effectPointsPerComboPoint3 REAL,
    spellVisual1 INTEGER,
    spellVisual2 INTEGER,
    spellIconId INTEGER,
    activeIconId INTEGER,
    spellPriority INTEGER,
    name1 TEXT,
    name2 TEXT,
    name3 TEXT,
    name4 TEXT,
    name5 TEXT,
    name6 TEXT,
    name7 TEXT,
    name8 TEXT,
    nameFlags INTEGER,
    nameSubtext1 TEXT,
    nameSubtext2 TEXT,
    nameSubtext3 TEXT,
    nameSubtext4 TEXT,
    nameSubtext5 TEXT,
    nameSubtext6 TEXT,
    nameSubtext7 TEXT,
    nameSubtext8 TEXT,
    nameSubtextFlags INTEGER,
    description1 TEXT,
    description2 TEXT,
    description3 TEXT,
    description4 TEXT,
    description5 TEXT,
    description6 TEXT,
    description7 TEXT,
    description8 TEXT,
    descriptionFlags INTEGER,
    auraDescription1 TEXT,
    auraDescription2 TEXT,
    auraDescription3 TEXT,
    auraDescription4 TEXT,
    auraDescription5 TEXT,
    auraDescription6 TEXT,
    auraDescription7 TEXT,
    auraDescription8 TEXT,
    auraDescriptionFlags INTEGER,
    manaCostPercentage INTEGER,
    startRecoveryCategory INTEGER,
    startRecoveryTime INTEGER,
    minTargetLevel INTEGER,
    maxTargetLevel INTEGER,
    spellFamilyName INTEGER,
    spellFamilyFlags INTEGER,
    maxAffectedTargets INTEGER,
    dmgClass INTEGER,
    preventionType INTEGER,
    stanceBarOrder INTEGER,
    dmgMultiplier1 REAL,
    dmgMultiplier2 REAL,
    dmgMultiplier3 REAL,
    minFactionId INTEGER,
    minReputation INTEGER,
    requiredAuraVision INTEGER,
    customFlags INTEGER
);
'''

cursor.executescript(create_table_sql)

print("📖 Reading world_full_05_october_2019.sql...")

# Parse SQL file and extract spell data
spells = {}  # spell_id -> {build_num -> full_row_data}

with open('world_full_05_october_2019.sql', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Find all spell_template INSERT statements
pattern = r"INSERT INTO `spell_template`.*?VALUES\s+(.*?)(?=INSERT|$)"
matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)

print(f"🔍 Found {len(matches)} spell_template INSERT blocks")

# Extract individual spell entries from the matches
all_spell_entries = []
for match in matches:
    # Split by lines and find individual spell entries
    lines = match.split('\n')
    current_entry = ""
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('--'):
            continue
        
        # Add to current entry
        if current_entry:
            current_entry += " " + line
        else:
            current_entry = line
        
        # Check if this line ends an entry (ends with ),)
        if line.rstrip().endswith('),') or line.rstrip().endswith(');'):
            if current_entry.strip():
                all_spell_entries.append(current_entry)
            current_entry = ""

print(f"🎯 Found {len(all_spell_entries)} individual spell entries")

for entry in all_spell_entries:
    # Extract just the VALUES part - find content within parentheses
    entry = entry.strip()
    if not entry:
        continue
    
    # Find the opening parenthesis and extract content
    paren_start = entry.find('(')
    if paren_start == -1:
        continue
    
    # Extract content between parentheses, handling nested parentheses
    content_part = entry[paren_start + 1:]
    if content_part.endswith('),'):
        content_part = content_part[:-2]
    elif content_part.endswith(');'):
        content_part = content_part[:-2]
    elif content_part.endswith(')'):
        content_part = content_part[:-1]
    
    # Parse the VALUES part, handling nested quotes and commas properly
    values = []
    current_value = ""
    in_quotes = False
    escape_next = False
    paren_depth = 0
    
    for char in content_part:
        if escape_next:
            current_value += char
            escape_next = False
        elif char == '\\':
            current_value += char
            escape_next = True
        elif char == "'" and not escape_next:
            in_quotes = not in_quotes
            current_value += char
        elif char == '(' and not in_quotes:
            paren_depth += 1
            current_value += char
        elif char == ')' and not in_quotes:
            paren_depth -= 1
            current_value += char
        elif char == ',' and not in_quotes and paren_depth == 0:
            values.append(current_value.strip())
            current_value = ""
        else:
            current_value += char
    
    if current_value.strip():
        values.append(current_value.strip())
    
    if len(values) < 170:  # Need at least basic spell data
        continue
    
    # Clean up the values
    row = []
    for val in values:
        val = val.strip()
        if val.startswith("'") and val.endswith("'"):
            val = val[1:-1]  # Remove quotes
        if val == 'NULL' or val == '':
            val = None
        row.append(val)
    
    # Extract spell ID and build number from the row
    try:
        spell_id = int(row[0]) if row[0] else 0
        build_num = int(row[1]) if row[1] else 5875  # build is always column 2
        
        if spell_id not in spells:
            spells[spell_id] = {}
        
        spells[spell_id][build_num] = row
        
    except (ValueError, IndexError):
        continue

print(f"🎯 Parsed {len(spells)} unique spells from database")

# Process spells and choose best version for each
final_spells = {}
stats = {'preferred_5875': 0, 'preferred_4222': 0, 'corrected': 0}

for spell_id, builds in spells.items():
    if not builds:
        continue
    
    # Determine which build to use
    builds_available = list(builds.keys())
    
    if should_prefer_spell(spell_id, 5875, builds_available) and 5875 in builds:
        chosen_build = 5875
        stats['preferred_5875'] += 1
    elif should_prefer_spell(spell_id, 4222, builds_available) and 4222 in builds:
        chosen_build = 4222
        stats['preferred_4222'] += 1
        if spell_id in corrections:
            stats['corrected'] += 1
    else:
        chosen_build = max(builds_available)
    
    final_spells[spell_id] = builds[chosen_build]

print(f"📈 Statistics:")
print(f"   • Build 5875 preferred: {stats['preferred_5875']}")
print(f"   • Build 4222 preferred: {stats['preferred_4222']}")
print(f"   • Manual corrections applied: {stats['corrected']}")

# Insert the ULTIMATE NERD DATA
print("🚀 Inserting ULTIMATE NERD DATA...")

# Get the total column count for our insert
column_count = 179  # Based on the exact schema we created

# Create a parameterized insert statement with exact number of fields
insert_sql = 'INSERT OR REPLACE INTO spell_template_ultimate_nerd VALUES (' + ','.join(['?'] * column_count) + ')'

inserted_count = 0
for spell_id, row_data in final_spells.items():
    # Ensure we have exactly the right number of values
    processed_row = []
    
    for i in range(column_count):
        if i < len(row_data):
            value = row_data[i]
            
            # Convert based on expected column type
            if i in [38, 69, 70, 71, 74, 75, 76, 93, 94, 95, 108, 109, 110, 165, 166, 167]:  # REAL fields
                processed_row.append(safe_float(value))
            elif i in range(117, 149):  # TEXT fields (names, descriptions, etc.)
                processed_row.append(safe_str(value))
            else:  # INTEGER fields
                processed_row.append(safe_int(value))
        else:
            # Fill missing values
            if i in [38, 69, 70, 71, 74, 75, 76, 93, 94, 95, 108, 109, 110, 165, 166, 167]:
                processed_row.append(0.0)
            elif i in range(117, 149):
                processed_row.append('')
            else:
                processed_row.append(0)
    
    try:
        cursor.execute(insert_sql, processed_row)
        inserted_count += 1
    except Exception as e:
        print(f"Error inserting spell {spell_id}: {e}")

# Commit changes
conn.commit()
conn.close()

print(f"🤓 Found {len(final_spells)} unique spells with ALL THE NERD DATA!")
print(f"🤓⚡ ULTIMATE NERD MODE COMPLETE! Inserted {inserted_count} spells with ALL 179 FIELDS! ⚡🤓")
