# 1.15.7 Data Source Notes

Place normalized CSV `items_core.csv` here with current Classic Era (1.15.7) stats.

Columns (minimum):
entry,name,quality,class,subclass,inventory_type,item_level,required_level,armor,block,stat_type1,stat_value1,stat_type2,stat_value2,stat_type3,stat_value3,stat_type4,stat_value4,stat_type5,stat_value5,stat_type6,stat_value6,stat_type7,stat_value7,stat_type8,stat_value8,stat_type9,stat_value9,stat_type10,stat_value10,delay,dmg_min1,dmg_max1,dmg_type1,dmg_min2,dmg_max2,dmg_type2,dmg_min3,dmg_max3,dmg_type3,dmg_min4,dmg_max4,dmg_type4,dmg_min5,dmg_max5,dmg_type5,holy_res,fire_res,nature_res,frost_res,shadow_res,arcane_res,spellid_1,spelltrigger_1,spellcharges_1,spellppmrate_1,spellcooldown_1,spellid_2,spelltrigger_2,spellcharges_2,spellppmrate_2,spellcooldown_2,spellid_3,spelltrigger_3,spellcharges_3,spellppmrate_3,spellcooldown_3,spellid_4,spelltrigger_4,spellcharges_4,spellppmrate_4,spellcooldown_4,spellid_5,spelltrigger_5,spellcharges_5,spellppmrate_5,spellcooldown_5,set_id,allowable_class,buy_price,sell_price,max_durability,patch

You may include extra columns; they will be ignored.

Acquisition suggestions:
1. Use wow.tools to export ItemSparse & Item for the Classic Era build, join on ID, select needed fields.
2. Cross-check 10 sample shields vs live Wowhead tooltips (to validate armor + block).

After placing the file, run:
./build_db_1157.sh [optional path to previous sqlite]
