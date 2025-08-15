import Foundation
import GRDB

struct Item: Identifiable {
    var entry: Int64
    var name: String
    var description: String?
    var quality: Int
    var `class`: Int?
    var subclass: Int?
    var patch: Int?
    var display_id: Int?
    var inventory_type: Int?
    var flags: Int?
    var buy_count: Int?
    var buy_price: Int?
    var sell_price: Int?
    var item_level: Int?
    var required_level: Int?
    var required_skill: Int?
    var required_skill_rank: Int?
    var required_spell: Int?
    var required_honor_rank: Int?
    var required_city_rank: Int?
    var required_reputation_faction: Int?
    var required_reputation_rank: Int?
    var allowable_class: Int?
    var allowable_race: Int?
    var max_count: Int?
    var stackable: Int?
    var container_slots: Int?
    var bonding: Int?
    var material: Int?
    var sheath: Int?
    var stat_type1: Int?
    var stat_value1: Int?
    var stat_type2: Int?
    var stat_value2: Int?
    var stat_type3: Int?
    var stat_value3: Int?
    var stat_type4: Int?
    var stat_value4: Int?
    var stat_type5: Int?
    var stat_value5: Int?
    var stat_type6: Int?
    var stat_value6: Int?
    var stat_type7: Int?
    var stat_value7: Int?
    var stat_type8: Int?
    var stat_value8: Int?
    var stat_type9: Int?
    var stat_value9: Int?
    var stat_type10: Int?
    var stat_value10: Int?
    var delay: Int?
    var range_mod: Double?
    var ammo_type: Int?
    var dmg_min1: Double?
    var dmg_max1: Double?
    var dmg_type1: Int?
    var dmg_min2: Double?
    var dmg_max2: Double?
    var dmg_type2: Int?
    var dmg_min3: Double?
    var dmg_max3: Double?
    var dmg_type3: Int?
    var dmg_min4: Double?
    var dmg_max4: Double?
    var dmg_type4: Int?
    var dmg_min5: Double?
    var dmg_max5: Double?
    var dmg_type5: Int?
    var block: Int?
    var armor: Int?
    var holy_res: Int?
    var fire_res: Int?
    var nature_res: Int?
    var frost_res: Int?
    var shadow_res: Int?
    var arcane_res: Int?
    var spellid_1: Int?
    var spelltrigger_1: Int?
    var spellcharges_1: Int?
    var spellppmrate_1: Double?
    var spellcooldown_1: Int?
    var spellcategory_1: Int?
    var spellcategorycooldown_1: Int?
    var spellid_2: Int?
    var spelltrigger_2: Int?
    var spellcharges_2: Int?
    var spellppmrate_2: Double?
    var spellcooldown_2: Int?
    var spellcategory_2: Int?
    var spellcategorycooldown_2: Int?
    var spellid_3: Int?
    var spelltrigger_3: Int?
    var spellcharges_3: Int?
    var spellppmrate_3: Double?
    var spellcooldown_3: Int?
    var spellcategory_3: Int?
    var spellcategorycooldown_3: Int?
    var spellid_4: Int?
    var spelltrigger_4: Int?
    var spellcharges_4: Int?
    var spellppmrate_4: Double?
    var spellcooldown_4: Int?
    var spellcategory_4: Int?
    var spellcategorycooldown_4: Int?
    var spellid_5: Int?
    var spelltrigger_5: Int?
    var spellcharges_5: Int?
    var spellppmrate_5: Double?
    var spellcooldown_5: Int?
    var spellcategory_5: Int?
    var spellcategorycooldown_5: Int?
    var page_text: Int?
    var page_language: Int?
    var page_material: Int?
    var start_quest: Int?
    var lock_id: Int?
    var random_property: Int?
    var set_id: Int?
    var max_durability: Int?
    var area_bound: Int?
    var map_bound: Int?
    var duration: Int?
    var bag_family: Int?
    var disenchant_id: Int?
    var food_type: Int?
    var min_money_loot: Int?
    var max_money_loot: Int?
    var extra_flags: Int?
    var other_team_entry: Int?

    // This property will hold the full "nerd stats" for each spell.
    var spells: [Spell] = []

    var id: Int64 { entry }
}

extension Item: Codable {
    enum CodingKeys: String, CodingKey {
        case entry, name, description, quality, `class`, subclass, patch, display_id,
            inventory_type, flags, buy_count, buy_price, sell_price, item_level, required_level,
            required_skill, required_skill_rank, required_spell, required_honor_rank,
            required_city_rank, required_reputation_faction, required_reputation_rank,
            allowable_class, allowable_race, max_count, stackable, container_slots, bonding,
            material, sheath, stat_type1, stat_value1, stat_type2, stat_value2, stat_type3,
            stat_value3, stat_type4, stat_value4, stat_type5, stat_value5, stat_type6, stat_value6,
            stat_type7, stat_value7, stat_type8, stat_value8, stat_type9, stat_value9, stat_type10,
            stat_value10, delay, range_mod, ammo_type, dmg_min1, dmg_max1, dmg_type1, dmg_min2,
            dmg_max2, dmg_type2, dmg_min3, dmg_max3, dmg_type3, dmg_min4, dmg_max4, dmg_type4,
            dmg_min5, dmg_max5, dmg_type5, block, armor, holy_res, fire_res, nature_res, frost_res,
            shadow_res, arcane_res, spellid_1, spelltrigger_1, spellcharges_1, spellppmrate_1,
            spellcooldown_1, spellcategory_1, spellcategorycooldown_1, spellid_2, spelltrigger_2,
            spellcharges_2, spellppmrate_2, spellcooldown_2, spellcategory_2,
            spellcategorycooldown_2, spellid_3, spelltrigger_3, spellcharges_3, spellppmrate_3,
            spellcooldown_3, spellcategory_3, spellcategorycooldown_3, spellid_4, spelltrigger_4,
            spellcharges_4, spellppmrate_4, spellcooldown_4, spellcategory_4,
            spellcategorycooldown_4, spellid_5, spelltrigger_5, spellcharges_5, spellppmrate_5,
            spellcooldown_5, spellcategory_5, spellcategorycooldown_5, page_text, page_language,
            page_material, start_quest, lock_id, random_property, set_id, max_durability,
            area_bound, map_bound, duration, bag_family, disenchant_id, food_type, min_money_loot,
            max_money_loot, extra_flags, other_team_entry
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entry = try container.decode(Int64.self, forKey: .entry)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        quality = try container.decode(Int.self, forKey: .quality)
        `class` = try container.decodeIfPresent(Int.self, forKey: .class)
        subclass = try container.decodeIfPresent(Int.self, forKey: .subclass)
        patch = try container.decodeIfPresent(Int.self, forKey: .patch)
        display_id = try container.decodeIfPresent(Int.self, forKey: .display_id)
        inventory_type = try container.decodeIfPresent(Int.self, forKey: .inventory_type)
        flags = try container.decodeIfPresent(Int.self, forKey: .flags)
        buy_count = try container.decodeIfPresent(Int.self, forKey: .buy_count)
        buy_price = try container.decodeIfPresent(Int.self, forKey: .buy_price)
        sell_price = try container.decodeIfPresent(Int.self, forKey: .sell_price)
        item_level = try container.decodeIfPresent(Int.self, forKey: .item_level)
        required_level = try container.decodeIfPresent(Int.self, forKey: .required_level)
        required_skill = try container.decodeIfPresent(Int.self, forKey: .required_skill)
        required_skill_rank = try container.decodeIfPresent(Int.self, forKey: .required_skill_rank)
        required_spell = try container.decodeIfPresent(Int.self, forKey: .required_spell)
        required_honor_rank = try container.decodeIfPresent(Int.self, forKey: .required_honor_rank)
        required_city_rank = try container.decodeIfPresent(Int.self, forKey: .required_city_rank)
        required_reputation_faction = try container.decodeIfPresent(
            Int.self, forKey: .required_reputation_faction)
        required_reputation_rank = try container.decodeIfPresent(
            Int.self, forKey: .required_reputation_rank)
        allowable_class = try container.decodeIfPresent(Int.self, forKey: .allowable_class)
        allowable_race = try container.decodeIfPresent(Int.self, forKey: .allowable_race)
        max_count = try container.decodeIfPresent(Int.self, forKey: .max_count)
        stackable = try container.decodeIfPresent(Int.self, forKey: .stackable)
        container_slots = try container.decodeIfPresent(Int.self, forKey: .container_slots)
        bonding = try container.decodeIfPresent(Int.self, forKey: .bonding)
        material = try container.decodeIfPresent(Int.self, forKey: .material)
        sheath = try container.decodeIfPresent(Int.self, forKey: .sheath)
        stat_type1 = try container.decodeIfPresent(Int.self, forKey: .stat_type1)
        stat_value1 = try container.decodeIfPresent(Int.self, forKey: .stat_value1)
        stat_type2 = try container.decodeIfPresent(Int.self, forKey: .stat_type2)
        stat_value2 = try container.decodeIfPresent(Int.self, forKey: .stat_value2)
        stat_type3 = try container.decodeIfPresent(Int.self, forKey: .stat_type3)
        stat_value3 = try container.decodeIfPresent(Int.self, forKey: .stat_value3)
        stat_type4 = try container.decodeIfPresent(Int.self, forKey: .stat_type4)
        stat_value4 = try container.decodeIfPresent(Int.self, forKey: .stat_value4)
        stat_type5 = try container.decodeIfPresent(Int.self, forKey: .stat_type5)
        stat_value5 = try container.decodeIfPresent(Int.self, forKey: .stat_value5)
        stat_type6 = try container.decodeIfPresent(Int.self, forKey: .stat_type6)
        stat_value6 = try container.decodeIfPresent(Int.self, forKey: .stat_value6)
        stat_type7 = try container.decodeIfPresent(Int.self, forKey: .stat_type7)
        stat_value7 = try container.decodeIfPresent(Int.self, forKey: .stat_value7)
        stat_type8 = try container.decodeIfPresent(Int.self, forKey: .stat_type8)
        stat_value8 = try container.decodeIfPresent(Int.self, forKey: .stat_value8)
        stat_type9 = try container.decodeIfPresent(Int.self, forKey: .stat_type9)
        stat_value9 = try container.decodeIfPresent(Int.self, forKey: .stat_value9)
        stat_type10 = try container.decodeIfPresent(Int.self, forKey: .stat_type10)
        stat_value10 = try container.decodeIfPresent(Int.self, forKey: .stat_value10)
        delay = try container.decodeIfPresent(Int.self, forKey: .delay)
        range_mod = try container.decodeIfPresent(Double.self, forKey: .range_mod)
        ammo_type = try container.decodeIfPresent(Int.self, forKey: .ammo_type)
        dmg_min1 = try container.decodeIfPresent(Double.self, forKey: .dmg_min1)
        dmg_max1 = try container.decodeIfPresent(Double.self, forKey: .dmg_max1)
        dmg_type1 = try container.decodeIfPresent(Int.self, forKey: .dmg_type1)
        dmg_min2 = try container.decodeIfPresent(Double.self, forKey: .dmg_min2)
        dmg_max2 = try container.decodeIfPresent(Double.self, forKey: .dmg_max2)
        dmg_type2 = try container.decodeIfPresent(Int.self, forKey: .dmg_type2)
        dmg_min3 = try container.decodeIfPresent(Double.self, forKey: .dmg_min3)
        dmg_max3 = try container.decodeIfPresent(Double.self, forKey: .dmg_max3)
        dmg_type3 = try container.decodeIfPresent(Int.self, forKey: .dmg_type3)
        dmg_min4 = try container.decodeIfPresent(Double.self, forKey: .dmg_min4)
        dmg_max4 = try container.decodeIfPresent(Double.self, forKey: .dmg_max4)
        dmg_type4 = try container.decodeIfPresent(Int.self, forKey: .dmg_type4)
        dmg_min5 = try container.decodeIfPresent(Double.self, forKey: .dmg_min5)
        dmg_max5 = try container.decodeIfPresent(Double.self, forKey: .dmg_max5)
        dmg_type5 = try container.decodeIfPresent(Int.self, forKey: .dmg_type5)
        block = try container.decodeIfPresent(Int.self, forKey: .block)
        armor = try container.decodeIfPresent(Int.self, forKey: .armor)
        holy_res = try container.decodeIfPresent(Int.self, forKey: .holy_res)
        fire_res = try container.decodeIfPresent(Int.self, forKey: .fire_res)
        nature_res = try container.decodeIfPresent(Int.self, forKey: .nature_res)
        frost_res = try container.decodeIfPresent(Int.self, forKey: .frost_res)
        shadow_res = try container.decodeIfPresent(Int.self, forKey: .shadow_res)
        arcane_res = try container.decodeIfPresent(Int.self, forKey: .arcane_res)
        spellid_1 = try container.decodeIfPresent(Int.self, forKey: .spellid_1)
        spelltrigger_1 = try container.decodeIfPresent(Int.self, forKey: .spelltrigger_1)
        spellcharges_1 = try container.decodeIfPresent(Int.self, forKey: .spellcharges_1)
        spellppmrate_1 = try container.decodeIfPresent(Double.self, forKey: .spellppmrate_1)
        spellcooldown_1 = try container.decodeIfPresent(Int.self, forKey: .spellcooldown_1)
        spellcategory_1 = try container.decodeIfPresent(Int.self, forKey: .spellcategory_1)
        spellcategorycooldown_1 = try container.decodeIfPresent(
            Int.self, forKey: .spellcategorycooldown_1)
        spellid_2 = try container.decodeIfPresent(Int.self, forKey: .spellid_2)
        spelltrigger_2 = try container.decodeIfPresent(Int.self, forKey: .spelltrigger_2)
        spellcharges_2 = try container.decodeIfPresent(Int.self, forKey: .spellcharges_2)
        spellppmrate_2 = try container.decodeIfPresent(Double.self, forKey: .spellppmrate_2)
        spellcooldown_2 = try container.decodeIfPresent(Int.self, forKey: .spellcooldown_2)
        spellcategory_2 = try container.decodeIfPresent(Int.self, forKey: .spellcategory_2)
        spellcategorycooldown_2 = try container.decodeIfPresent(
            Int.self, forKey: .spellcategorycooldown_2)
        spellid_3 = try container.decodeIfPresent(Int.self, forKey: .spellid_3)
        spelltrigger_3 = try container.decodeIfPresent(Int.self, forKey: .spelltrigger_3)
        spellcharges_3 = try container.decodeIfPresent(Int.self, forKey: .spellcharges_3)
        spellppmrate_3 = try container.decodeIfPresent(Double.self, forKey: .spellppmrate_3)
        spellcooldown_3 = try container.decodeIfPresent(Int.self, forKey: .spellcooldown_3)
        spellcategory_3 = try container.decodeIfPresent(Int.self, forKey: .spellcategory_3)
        spellcategorycooldown_3 = try container.decodeIfPresent(
            Int.self, forKey: .spellcategorycooldown_3)
        spellid_4 = try container.decodeIfPresent(Int.self, forKey: .spellid_4)
        spelltrigger_4 = try container.decodeIfPresent(Int.self, forKey: .spelltrigger_4)
        spellcharges_4 = try container.decodeIfPresent(Int.self, forKey: .spellcharges_4)
        spellppmrate_4 = try container.decodeIfPresent(Double.self, forKey: .spellppmrate_4)
        spellcooldown_4 = try container.decodeIfPresent(Int.self, forKey: .spellcooldown_4)
        spellcategory_4 = try container.decodeIfPresent(Int.self, forKey: .spellcategory_4)
        spellcategorycooldown_4 = try container.decodeIfPresent(
            Int.self, forKey: .spellcategorycooldown_4)
        spellid_5 = try container.decodeIfPresent(Int.self, forKey: .spellid_5)
        spelltrigger_5 = try container.decodeIfPresent(Int.self, forKey: .spelltrigger_5)
        spellcharges_5 = try container.decodeIfPresent(Int.self, forKey: .spellcharges_5)
        spellppmrate_5 = try container.decodeIfPresent(Double.self, forKey: .spellppmrate_5)
        spellcooldown_5 = try container.decodeIfPresent(Int.self, forKey: .spellcooldown_5)
        spellcategory_5 = try container.decodeIfPresent(Int.self, forKey: .spellcategory_5)
        spellcategorycooldown_5 = try container.decodeIfPresent(
            Int.self, forKey: .spellcategorycooldown_5)
        page_text = try container.decodeIfPresent(Int.self, forKey: .page_text)
        page_language = try container.decodeIfPresent(Int.self, forKey: .page_language)
        page_material = try container.decodeIfPresent(Int.self, forKey: .page_material)
        start_quest = try container.decodeIfPresent(Int.self, forKey: .start_quest)
        lock_id = try container.decodeIfPresent(Int.self, forKey: .lock_id)
        random_property = try container.decodeIfPresent(Int.self, forKey: .random_property)
        set_id = try container.decodeIfPresent(Int.self, forKey: .set_id)
        max_durability = try container.decodeIfPresent(Int.self, forKey: .max_durability)
        area_bound = try container.decodeIfPresent(Int.self, forKey: .area_bound)
        map_bound = try container.decodeIfPresent(Int.self, forKey: .map_bound)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        bag_family = try container.decodeIfPresent(Int.self, forKey: .bag_family)
        disenchant_id = try container.decodeIfPresent(Int.self, forKey: .disenchant_id)
        food_type = try container.decodeIfPresent(Int.self, forKey: .food_type)
        min_money_loot = try container.decodeIfPresent(Int.self, forKey: .min_money_loot)
        max_money_loot = try container.decodeIfPresent(Int.self, forKey: .max_money_loot)
        extra_flags = try container.decodeIfPresent(Int.self, forKey: .extra_flags)
        other_team_entry = try container.decodeIfPresent(Int.self, forKey: .other_team_entry)

        // spells is not decoded from the database, it's populated later.
        spells = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entry, forKey: .entry)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(quality, forKey: .quality)
        try container.encode(`class`, forKey: .class)
        try container.encode(subclass, forKey: .subclass)
        try container.encode(patch, forKey: .patch)
        try container.encode(display_id, forKey: .display_id)
        try container.encode(inventory_type, forKey: .inventory_type)
        try container.encode(flags, forKey: .flags)
        try container.encode(buy_count, forKey: .buy_count)
        try container.encode(buy_price, forKey: .buy_price)
        try container.encode(sell_price, forKey: .sell_price)
        try container.encode(item_level, forKey: .item_level)
        try container.encode(required_level, forKey: .required_level)
        try container.encode(required_skill, forKey: .required_skill)
        try container.encode(required_skill_rank, forKey: .required_skill_rank)
        try container.encode(required_spell, forKey: .required_spell)
        try container.encode(required_honor_rank, forKey: .required_honor_rank)
        try container.encode(required_city_rank, forKey: .required_city_rank)
        try container.encode(required_reputation_faction, forKey: .required_reputation_faction)
        try container.encode(required_reputation_rank, forKey: .required_reputation_rank)
        try container.encode(allowable_class, forKey: .allowable_class)
        try container.encode(allowable_race, forKey: .allowable_race)
        try container.encode(max_count, forKey: .max_count)
        try container.encode(stackable, forKey: .stackable)
        try container.encode(container_slots, forKey: .container_slots)
        try container.encode(bonding, forKey: .bonding)
        try container.encode(material, forKey: .material)
        try container.encode(sheath, forKey: .sheath)
        try container.encode(stat_type1, forKey: .stat_type1)
        try container.encode(stat_value1, forKey: .stat_value1)
        try container.encode(stat_type2, forKey: .stat_type2)
        try container.encode(stat_value2, forKey: .stat_value2)
        try container.encode(stat_type3, forKey: .stat_type3)
        try container.encode(stat_value3, forKey: .stat_value3)
        try container.encode(stat_type4, forKey: .stat_type4)
        try container.encode(stat_value4, forKey: .stat_value4)
        try container.encode(stat_type5, forKey: .stat_type5)
        try container.encode(stat_value5, forKey: .stat_value5)
        try container.encode(stat_type6, forKey: .stat_type6)
        try container.encode(stat_value6, forKey: .stat_value6)
        try container.encode(stat_type7, forKey: .stat_type7)
        try container.encode(stat_value7, forKey: .stat_value7)
        try container.encode(stat_type8, forKey: .stat_type8)
        try container.encode(stat_value8, forKey: .stat_value8)
        try container.encode(stat_type9, forKey: .stat_type9)
        try container.encode(stat_value9, forKey: .stat_value9)
        try container.encode(stat_type10, forKey: .stat_type10)
        try container.encode(stat_value10, forKey: .stat_value10)
        try container.encode(delay, forKey: .delay)
        try container.encode(range_mod, forKey: .range_mod)
        try container.encode(ammo_type, forKey: .ammo_type)
        try container.encode(dmg_min1, forKey: .dmg_min1)
        try container.encode(dmg_max1, forKey: .dmg_max1)
        try container.encode(dmg_type1, forKey: .dmg_type1)
        try container.encode(dmg_min2, forKey: .dmg_min2)
        try container.encode(dmg_max2, forKey: .dmg_max2)
        try container.encode(dmg_type2, forKey: .dmg_type2)
        try container.encode(dmg_min3, forKey: .dmg_min3)
        try container.encode(dmg_max3, forKey: .dmg_max3)
        try container.encode(dmg_type3, forKey: .dmg_type3)
        try container.encode(dmg_min4, forKey: .dmg_min4)
        try container.encode(dmg_max4, forKey: .dmg_max4)
        try container.encode(dmg_type4, forKey: .dmg_type4)
        try container.encode(dmg_min5, forKey: .dmg_min5)
        try container.encode(dmg_max5, forKey: .dmg_max5)
        try container.encode(dmg_type5, forKey: .dmg_type5)
        try container.encode(block, forKey: .block)
        try container.encode(armor, forKey: .armor)
        try container.encode(holy_res, forKey: .holy_res)
        try container.encode(fire_res, forKey: .fire_res)
        try container.encode(nature_res, forKey: .nature_res)
        try container.encode(frost_res, forKey: .frost_res)
        try container.encode(shadow_res, forKey: .shadow_res)
        try container.encode(arcane_res, forKey: .arcane_res)
        try container.encode(spellid_1, forKey: .spellid_1)
        try container.encode(spelltrigger_1, forKey: .spelltrigger_1)
        try container.encode(spellcharges_1, forKey: .spellcharges_1)
        try container.encode(spellppmrate_1, forKey: .spellppmrate_1)
        try container.encode(spellcooldown_1, forKey: .spellcooldown_1)
        try container.encode(spellcategory_1, forKey: .spellcategory_1)
        try container.encode(spellcategorycooldown_1, forKey: .spellcategorycooldown_1)
        try container.encode(spellid_2, forKey: .spellid_2)
        try container.encode(spelltrigger_2, forKey: .spelltrigger_2)
        try container.encode(spellcharges_2, forKey: .spellcharges_2)
        try container.encode(spellppmrate_2, forKey: .spellppmrate_2)
        try container.encode(spellcooldown_2, forKey: .spellcooldown_2)
        try container.encode(spellcategory_2, forKey: .spellcategory_2)
        try container.encode(spellcategorycooldown_2, forKey: .spellcategorycooldown_2)
        try container.encode(spellid_3, forKey: .spellid_3)
        try container.encode(spelltrigger_3, forKey: .spelltrigger_3)
        try container.encode(spellcharges_3, forKey: .spellcharges_3)
        try container.encode(spellppmrate_3, forKey: .spellppmrate_3)
        try container.encode(spellcooldown_3, forKey: .spellcooldown_3)
        try container.encode(spellcategory_3, forKey: .spellcategory_3)
        try container.encode(spellcategorycooldown_3, forKey: .spellcategorycooldown_3)
        try container.encode(spellid_4, forKey: .spellid_4)
        try container.encode(spelltrigger_4, forKey: .spelltrigger_4)
        try container.encode(spellcharges_4, forKey: .spellcharges_4)
        try container.encode(spellppmrate_4, forKey: .spellppmrate_4)
        try container.encode(spellcooldown_4, forKey: .spellcooldown_4)
        try container.encode(spellcategory_4, forKey: .spellcategory_4)
        try container.encode(spellcategorycooldown_4, forKey: .spellcategorycooldown_4)
        try container.encode(spellid_5, forKey: .spellid_5)
        try container.encode(spelltrigger_5, forKey: .spelltrigger_5)
        try container.encode(spellcharges_5, forKey: .spellcharges_5)
        try container.encode(spellppmrate_5, forKey: .spellppmrate_5)
        try container.encode(spellcooldown_5, forKey: .spellcooldown_5)
        try container.encode(spellcategory_5, forKey: .spellcategory_5)
        try container.encode(spellcategorycooldown_5, forKey: .spellcategorycooldown_5)
        try container.encode(page_text, forKey: .page_text)
        try container.encode(page_language, forKey: .page_language)
        try container.encode(page_material, forKey: .page_material)
        try container.encode(start_quest, forKey: .start_quest)
        try container.encode(lock_id, forKey: .lock_id)
        try container.encode(random_property, forKey: .random_property)
        try container.encode(set_id, forKey: .set_id)
        try container.encode(max_durability, forKey: .max_durability)
        try container.encode(area_bound, forKey: .area_bound)
        try container.encode(map_bound, forKey: .map_bound)
        try container.encode(duration, forKey: .duration)
        try container.encode(bag_family, forKey: .bag_family)
        try container.encode(disenchant_id, forKey: .disenchant_id)
        try container.encode(food_type, forKey: .food_type)
        try container.encode(min_money_loot, forKey: .min_money_loot)
        try container.encode(max_money_loot, forKey: .max_money_loot)
        try container.encode(extra_flags, forKey: .extra_flags)
        try container.encode(other_team_entry, forKey: .other_team_entry)
    }
}

extension Item: Equatable, Hashable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.entry == rhs.entry
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(entry)
    }
}

extension Item: FetchableRecord, TableRecord {
    nonisolated static var databaseTableName: String { "items" }
}

struct SpellEffect: Codable, Hashable {
    var spellId: Int
    var trigger: Int?
    var charges: Int?
    var cooldown: Int?
    var ppmRate: Double?
    var procChance: Double?
    var category: Int?
    var categoryCooldown: Int?

    var triggerDescription: String {
        guard let trigger = trigger else { return "Use" }
        switch trigger {
        case 0: return "Use"
        case 1: return "On Equip"
        case 2: return "Chance on Hit"
        case 3: return "Soulstone"
        case 4: return "Use (No Delay)"
        case 5: return "On Learn"
        default: return "Unknown Trigger (\(trigger))"
        }
    }
}

extension Item {
    var allSpellEffects: [SpellEffect] {
        var effects: [SpellEffect] = []
        if let spellId = spellid_1, spellId != 0 {
            effects.append(
                SpellEffect(
                    spellId: spellId, trigger: spelltrigger_1, charges: spellcharges_1,
                    cooldown: spellcooldown_1, ppmRate: spellppmrate_1, category: spellcategory_1,
                    categoryCooldown: spellcategorycooldown_1))
        }
        if let spellId = spellid_2, spellId != 0 {
            effects.append(
                SpellEffect(
                    spellId: spellId, trigger: spelltrigger_2, charges: spellcharges_2,
                    cooldown: spellcooldown_2, ppmRate: spellppmrate_2, category: spellcategory_2,
                    categoryCooldown: spellcategorycooldown_2))
        }
        if let spellId = spellid_3, spellId != 0 {
            effects.append(
                SpellEffect(
                    spellId: spellId, trigger: spelltrigger_3, charges: spellcharges_3,
                    cooldown: spellcooldown_3, ppmRate: spellppmrate_3, category: spellcategory_3,
                    categoryCooldown: spellcategorycooldown_3))
        }
        if let spellId = spellid_4, spellId != 0 {
            effects.append(
                SpellEffect(
                    spellId: spellId, trigger: spelltrigger_4, charges: spellcharges_4,
                    cooldown: spellcooldown_4, ppmRate: spellppmrate_4, category: spellcategory_4,
                    categoryCooldown: spellcategorycooldown_4))
        }
        if let spellId = spellid_5, spellId != 0 {
            effects.append(
                SpellEffect(
                    spellId: spellId, trigger: spelltrigger_5, charges: spellcharges_5,
                    cooldown: spellcooldown_5, ppmRate: spellppmrate_5, category: spellcategory_5,
                    categoryCooldown: spellcategorycooldown_5))
        }
        return effects
    }
}

extension Item {
    var qualityName: String {
        switch quality {
        case 0: return "Poor"
        case 1: return "Common"
        case 2: return "Uncommon"
        case 3: return "Rare"
        case 4: return "Epic"
        case 5: return "Legendary"
        default: return "Artifact"
        }
    }

    var itemTypeName: String {
        guard let itemClass = self.class, let subClass = self.subclass else { return "Unknown" }
        switch itemClass {
        case 2:  // Weapon
            switch subClass {
            case 0: return "Axe"
            case 1: return "Two-Handed Axe"
            case 2: return "Bow"
            case 3: return "Gun"
            case 4: return "Mace"
            case 5: return "Two-Handed Mace"
            case 6: return "Polearm"
            case 7: return "Sword"
            case 8: return "Two-Handed Sword"
            case 10: return "Dagger"
            case 13: return "Fist Weapon"
            case 15: return "Wand"
            case 16: return "Fishing Pole"
            default: return "Weapon"
            }
        case 4:  // Armor
            switch subClass {
            case 1: return "Cloth"
            case 2: return "Leather"
            case 3: return "Mail"
            case 4: return "Plate"
            case 5: return "Shield"
            default: return "Armor"
            }
        default:
            return "Item"
        }
    }

    var isWeapon: Bool {
        return self.class == 2
    }

    var hasArmor: Bool {
        return armor ?? 0 > 0
    }

    var formattedStats: [String] {
        var stats: [String] = []
        let statMap: [Int: String] = [
            3: "Agility", 4: "Strength", 5: "Intellect", 6: "Spirit", 7: "Stamina",
        ]

        for i in 1...10 {
            if let type = self.value(forKey: "stat_type\(i)") as? Int,
                let value = self.value(forKey: "stat_value\(i)") as? Int,
                value != 0, let statName = statMap[type]
            {
                stats.append("+\(value) \(statName)")
            }
        }
        return stats
    }

    var hasSpellEffects: Bool {
        return !allSpellEffects.isEmpty
    }

    var bindingDescription: String? {
        guard let bonding = bonding else { return nil }
        switch bonding {
        case 1: return "Binds when picked up"
        case 2: return "Binds when equipped"
        case 3: return "Binds when used"
        case 4: return "Quest Item"
        default: return nil
        }
    }

    var isSetItem: Bool {
        return set_id ?? 0 != 0
    }

    var startsQuest: Bool {
        return start_quest ?? 0 != 0
    }

    var isReadable: Bool {
        return page_text ?? 0 != 0
    }

    var secondaryDamageTypes: [String] {
        var damages: [String] = []
        for i in 2...5 {
            if let minDmg = self.value(forKey: "dmg_min\(i)") as? Double,
                let maxDmg = self.value(forKey: "dmg_max\(i)") as? Double,
                let type = self.value(forKey: "dmg_type\(i)") as? Int,
                minDmg > 0 || maxDmg > 0
            {
                let typeName = damageTypeName(for: type)
                damages.append("+\(Int(minDmg))-\(Int(maxDmg)) \(typeName) Damage")
            }
        }
        return damages
    }

    var formattedResistances: [String] {
        var resists: [String] = []
        if let holy = holy_res, holy > 0 { resists.append("+\(holy) Holy Resistance") }
        if let fire = fire_res, fire > 0 { resists.append("+\(fire) Fire Resistance") }
        if let nature = nature_res, nature > 0 { resists.append("+\(nature) Nature Resistance") }
        if let frost = frost_res, frost > 0 { resists.append("+\(frost) Frost Resistance") }
        if let shadow = shadow_res, shadow > 0 { resists.append("+\(shadow) Shadow Resistance") }
        if let arcane = arcane_res, arcane > 0 { resists.append("+\(arcane) Arcane Resistance") }
        return resists
    }

    var weaponDamageString: String? {
        guard isWeapon, let minDmg = dmg_min1, let maxDmg = dmg_max1 else { return nil }
        return "\(Int(minDmg)) - \(Int(maxDmg))"
    }

    var weaponSpeed: String? {
        guard isWeapon, let delay = delay else { return nil }
        return String(format: "%.2f", Double(delay) / 1000.0)
    }

    var dpsString: String? {
        guard isWeapon, let minDmg = dmg_min1, let maxDmg = dmg_max1, let delay = delay, delay > 0
        else { return nil }
        let avgDmg = (minDmg + maxDmg) / 2.0
        let dps = avgDmg / (Double(delay) / 1000.0)
        return String(format: "%.2f", dps)
    }

    var armorString: String? {
        guard let armor = armor, armor > 0 else { return nil }
        return "\(armor) Armor"
    }

    private func damageTypeName(for type: Int) -> String {
        switch type {
        case 1: return "Holy"
        case 2: return "Fire"
        case 3: return "Nature"
        case 4: return "Frost"
        case 5: return "Shadow"
        case 6: return "Arcane"
        default: return "Physical"
        }
    }

    private func value(forKey key: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        return mirror.children.first { $0.label == key }?.value
    }
}
