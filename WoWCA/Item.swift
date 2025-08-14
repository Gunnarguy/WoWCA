// Data/Models/Item.swift
import Foundation

#if canImport(GRDB)
    import GRDB
#endif

struct SpellMeta: Hashable {
    var name: String
    var description: String
    var minDamage: Int?
    var maxDamage: Int?
    var extra: String?
    var grantedManaPer5: Int?
    var grantedHealthPer5: Int?
    var grantedHeal: Int?
    var grantedSpellPower: Int?

    static let library: [Int: SpellMeta] = [
        // Thunderfury, Blessed Blade of the Windseeker
        21992: SpellMeta(
            name: "Thunderfury",
            description:
                "Blasts your enemy with lightning, dealing 300 Nature damage and then jumping to additional nearby enemies. Each jump reduces that victim's Nature resistance by 25. Your primary target is also consumed by a cyclone, slowing its attack speed for 12 sec.",
            minDamage: 300, maxDamage: 300,
            extra: "Reduces Nature Resistance by 25 and Attack Speed by 20%."
        ),

        // Rejuvenating Gem - VERIFIED from Classic WoW Database
        18041: SpellMeta(
            name: "Increase Healing 66",
            description: "Increases healing done by spells and effects by up to 66.",
            grantedHeal: 66
        ),
        21365: SpellMeta(
            name: "Increased Mana Regen",
            description: "Restores 9 mana per 5 sec.",
            grantedManaPer5: 9
        ),

        // Royal Seal of Eldre'Thalas
        22962: SpellMeta(
            name: "Mana Regeneration",
            description: "Restores 9 mana per 5 seconds.",
            grantedManaPer5: 9
        ),
        18396: SpellMeta(
            name: "Increased Healing",
            description: "Improves healing spells by up to 66.",
            grantedHeal: 66
        ),
    ]
}

struct SpellEffect: Hashable {
    var spellId: Int
    var trigger: Int?
    var charges: Int?
    var cooldown: Int?
    var ppmRate: Double?
    var procChance: Double?
    var category: Int?
    var categoryCooldown: Int?
    var meta: SpellMeta? { SpellMeta.library[spellId] }

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

// Aggregation helpers for spell-based bonuses
// Aggregation helpers for spell-based bonuses
extension Item {
    var spellGrantedManaPer5: Int {
        spellEffects.compactMap { $0.meta?.grantedManaPer5 }.reduce(0, +)
    }
    var spellGrantedHealing: Int { spellEffects.compactMap { $0.meta?.grantedHeal }.reduce(0, +) }
    var spellGrantedSpellPower: Int {
        spellEffects.compactMap { $0.meta?.grantedSpellPower }.reduce(0, +)
    }
    var spellGrantedHealthPer5: Int {
        spellEffects.compactMap { $0.meta?.grantedHealthPer5 }.reduce(0, +)
    }
}

#if canImport(GRDB)
    typealias FetchableMaybe = FetchableRecord
#else
    protocol FetchableMaybe {}
#endif

struct Item: Codable, Identifiable, Equatable, Hashable, FetchableMaybe {
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

    // ALL 10 stat slots
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

    // Weapon properties
    var delay: Int?
    var range_mod: Double?
    var ammo_type: Int?

    // ALL 5 damage types
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

    // Defense
    var block: Int?
    var armor: Int?

    // ALL resistances
    var holy_res: Int?
    var fire_res: Int?
    var nature_res: Int?
    var frost_res: Int?
    var shadow_res: Int?
    var arcane_res: Int?

    // ALL 5 spell slots
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

    // Special properties
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

    var id: Int64 { entry }

    // MARK: - Convenience Initializer (stabilizes previews & avoids fragile memberwise ordering)
    // This lets UI previews or focused call sites create an Item without supplying every single field
    // in the exact stored-property order (the synthesized memberwise initializer is extremely long
    // and easy to misuse – producing errors like: Argument 'buy_price' must precede 'item_level').
    init(
        entry: Int64,
        name: String,
        quality: Int,
        class: Int? = nil,
        subclass: Int? = nil,
        inventory_type: Int? = nil,
        item_level: Int? = nil,
        required_level: Int? = nil,
        stat_type1: Int? = nil, stat_value1: Int? = nil,
        stat_type2: Int? = nil, stat_value2: Int? = nil,
        stat_type3: Int? = nil, stat_value3: Int? = nil,
        stat_type4: Int? = nil, stat_value4: Int? = nil,
        delay: Int? = nil,
        dmg_min1: Double? = nil, dmg_max1: Double? = nil, dmg_type1: Int? = nil,
        armor: Int? = nil,
        fire_res: Int? = nil, nature_res: Int? = nil, frost_res: Int? = nil, shadow_res: Int? = nil,
        allowable_class: Int? = nil,
        buy_price: Int? = nil, sell_price: Int? = nil
    ) {
        // Required
        self.entry = entry
        self.name = name
        self.quality = quality

        // Basic classification
        self.description = nil
        self.class = `class`
        self.subclass = subclass
        self.patch = nil
        self.display_id = nil
        self.inventory_type = inventory_type
        self.flags = nil

        // Economy
        self.buy_count = nil
        self.buy_price = buy_price
        self.sell_price = sell_price

        // Level / requirements
        self.item_level = item_level
        self.required_level = required_level
        self.required_skill = nil
        self.required_skill_rank = nil
        self.required_spell = nil
        self.required_honor_rank = nil
        self.required_city_rank = nil
        self.required_reputation_faction = nil
        self.required_reputation_rank = nil
        self.allowable_class = allowable_class
        self.allowable_race = nil
        self.max_count = nil
        self.stackable = nil
        self.container_slots = nil
        self.bonding = nil
        self.material = nil
        self.sheath = nil

        // Stats
        self.stat_type1 = stat_type1
        self.stat_value1 = stat_value1
        self.stat_type2 = stat_type2
        self.stat_value2 = stat_value2
        self.stat_type3 = stat_type3
        self.stat_value3 = stat_value3
        self.stat_type4 = stat_type4
        self.stat_value4 = stat_value4
        self.stat_type5 = nil
        self.stat_value5 = nil
        self.stat_type6 = nil
        self.stat_value6 = nil
        self.stat_type7 = nil
        self.stat_value7 = nil
        self.stat_type8 = nil
        self.stat_value8 = nil
        self.stat_type9 = nil
        self.stat_value9 = nil
        self.stat_type10 = nil
        self.stat_value10 = nil

        // Weapon
        self.delay = delay
        self.range_mod = nil
        self.ammo_type = nil

        // Damage slots
        self.dmg_min1 = dmg_min1
        self.dmg_max1 = dmg_max1
        self.dmg_type1 = dmg_type1
        self.dmg_min2 = nil
        self.dmg_max2 = nil
        self.dmg_type2 = nil
        self.dmg_min3 = nil
        self.dmg_max3 = nil
        self.dmg_type3 = nil
        self.dmg_min4 = nil
        self.dmg_max4 = nil
        self.dmg_type4 = nil
        self.dmg_min5 = nil
        self.dmg_max5 = nil
        self.dmg_type5 = nil

        // Defense / armor / resist
        self.block = nil
        self.armor = armor
        self.holy_res = nil
        self.fire_res = fire_res
        self.nature_res = nature_res
        self.frost_res = frost_res
        self.shadow_res = shadow_res
        self.arcane_res = nil

        // Spells (empty)
        self.spellid_1 = nil
        self.spelltrigger_1 = nil
        self.spellcharges_1 = nil
        self.spellppmrate_1 = nil
        self.spellcooldown_1 = nil
        self.spellcategory_1 = nil
        self.spellcategorycooldown_1 = nil
        self.spellid_2 = nil
        self.spelltrigger_2 = nil
        self.spellcharges_2 = nil
        self.spellppmrate_2 = nil
        self.spellcooldown_2 = nil
        self.spellcategory_2 = nil
        self.spellcategorycooldown_2 = nil
        self.spellid_3 = nil
        self.spelltrigger_3 = nil
        self.spellcharges_3 = nil
        self.spellppmrate_3 = nil
        self.spellcooldown_3 = nil
        self.spellcategory_3 = nil
        self.spellcategorycooldown_3 = nil
        self.spellid_4 = nil
        self.spelltrigger_4 = nil
        self.spellcharges_4 = nil
        self.spellppmrate_4 = nil
        self.spellcooldown_4 = nil
        self.spellcategory_4 = nil
        self.spellcategorycooldown_4 = nil
        self.spellid_5 = nil
        self.spelltrigger_5 = nil
        self.spellcharges_5 = nil
        self.spellppmrate_5 = nil
        self.spellcooldown_5 = nil
        self.spellcategory_5 = nil
        self.spellcategorycooldown_5 = nil

        // Special / misc
        self.page_text = nil
        self.page_language = nil
        self.page_material = nil
        self.start_quest = nil
        self.lock_id = nil
        self.random_property = nil
        self.set_id = nil
        self.max_durability = nil
        self.area_bound = nil
        self.map_bound = nil
        self.duration = nil
        self.bag_family = nil
        self.disenchant_id = nil
        self.food_type = nil
        self.min_money_loot = nil
        self.max_money_loot = nil
        self.extra_flags = nil
        self.other_team_entry = nil
    }

    // MARK: - Computed Properties

    /// Returns quality color name for UI
    var qualityColor: String {
        switch quality {
        case 0: return "gray"  // Poor
        case 1: return "white"  // Common
        case 2: return "green"  // Uncommon
        case 3: return "blue"  // Rare
        case 4: return "purple"  // Epic
        case 5: return "orange"  // Legendary
        default: return "white"
        }
    }

    /// Returns quality name
    var qualityName: String {
        switch quality {
        case 0: return "Poor"
        case 1: return "Common"
        case 2: return "Uncommon"
        case 3: return "Rare"
        case 4: return "Epic"
        case 5: return "Legendary"
        default: return "Unknown"
        }
    }

    // Human-readable class mask (Classic era). Returns nil if unrestricted or unknown.
    var allowableClassNames: String? {
        guard let mask = allowable_class, mask != -1 else { return nil }
        let mapping: [(Int, String)] = [
            (1, "Warrior"), (2, "Paladin"), (4, "Hunter"), (8, "Rogue"),
            (16, "Priest"), (64, "Shaman"), (128, "Mage"), (256, "Warlock"),
            (1024, "Druid"),
        ]
        let names = mapping.compactMap { (bit, name) -> String? in (mask & bit) != 0 ? name : nil }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    // Human-readable race mask (Classic era). Returns nil if unrestricted or unknown.
    var allowableRaceNames: String? {
        guard let mask = allowable_race, mask != -1 else { return nil }
        let mapping: [(Int, String)] = [
            (1, "Human"), (2, "Orc"), (4, "Dwarf"), (8, "Night Elf"),
            (16, "Undead"), (32, "Tauren"), (64, "Gnome"), (128, "Troll"),
        ]
        let names = mapping.compactMap { (bit, name) -> String? in (mask & bit) != 0 ? name : nil }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    // Formatted skill requirement (e.g., "Engineering (225)").
    var skillRequirementString: String? {
        guard let skill = required_skill else { return nil }
        var base: String
        switch skill {
        case 164: base = "Blacksmithing"
        case 165: base = "Leatherworking"
        case 171: base = "Alchemy"
        case 182: base = "Herbalism"
        case 185: base = "Cooking"
        case 186: base = "Mining"
        case 197: base = "Tailoring"
        case 202: base = "Engineering"
        case 333: base = "Enchanting"
        case 356: base = "Fishing"
        case 393: base = "Skinning"
        case 755: base = "Jewelcrafting"  // (TBC onward)
        default: base = "Skill \(skill)"
        }
        if let rank = required_skill_rank, rank > 0 { return "\(base) (\(rank))" }
        return base
    }

    // Reputation requirement string if present.
    var reputationRequirementString: String? {
        guard let faction = required_reputation_faction, let rank = required_reputation_rank else {
            return nil
        }
        let rankName: String
        switch rank {
        case 0: rankName = "Hated"
        case 1: rankName = "Hostile"
        case 2: rankName = "Unfriendly"
        case 3: rankName = "Neutral"
        case 4: rankName = "Friendly"
        case 5: rankName = "Honored"
        case 6: rankName = "Revered"
        case 7: rankName = "Exalted"
        default: rankName = "Rank \(rank)"
        }
        return "Faction \(faction) (\(rankName))"
    }

    // Durability string.
    var durabilityString: String? {
        guard let dur = max_durability, dur > 0 else { return nil }
        return "Durability \(dur)"
    }

    // Block value description (only if positive). Separate from stat mapping for shields.
    var blockString: String? {
        guard let blk = block, blk > 0 else { return nil }
        return "Block \(blk)"
    }

    // Bag / container slots (if item is a container)
    var containerSlotsString: String? {
        guard let slots = container_slots, slots > 0 else { return nil }
        return "\(slots) Slot Bag"
    }

    // Bag family (specialized bag type) simplified mapping.
    var bagFamilyName: String? {
        guard let family = bag_family, family > 0 else { return nil }
        // This is a mask; for simplicity return first matched known type.
        let mapping: [(Int, String)] = [
            (0x01, "Arrows"), (0x02, "Bullets"), (0x04, "Soul Shards"),
            (0x08, "Leatherworking"), (0x10, "Inscription"), (0x20, "Herbs"),
            (0x40, "Enchanting"), (0x80, "Engineering"), (0x100, "Keys"),
            (0x200, "Gems"), (0x400, "Mining"), (0x800, "Soulbound Equipment"),
            (0x1000, "Vanity Pets"), (0x2000, "Currency"), (0x4000, "Quest"),
        ]
        let names = mapping.compactMap { (bit, name) -> String? in (family & bit) != 0 ? name : nil
        }
        return names.isEmpty ? "Bag Family \(family)" : names.joined(separator: ", ")
    }

    // Aggregated advanced / rarely used fields (only those present will be shown in UI Advanced section).
    var advancedAttributes: [(String, String)] {
        var rows: [(String, String)] = []
        if let rp = random_property { rows.append(("Random Property", "\(rp)")) }
        if let lock = lock_id { rows.append(("Lock ID", "\(lock)")) }
        if let dis = disenchant_id { rows.append(("Disenchant ID", "\(dis)")) }
        if let area = area_bound { rows.append(("Area Bound", "\(area)")) }
        if let map = map_bound { rows.append(("Map Bound", "\(map)")) }
        if let dur = duration, dur > 0 { rows.append(("Duration (ms)", "\(dur)")) }
        if let mm = min_money_loot, mm > 0 { rows.append(("Min Money Loot", "\(mm)")) }
        if let mx = max_money_loot, mx > 0 { rows.append(("Max Money Loot", "\(mx)")) }
        if let other = other_team_entry { rows.append(("Other Team Entry", "\(other)")) }
        if let flags = extra_flags, flags != 0 {
            rows.append(("Extra Flags", "0x\(String(flags, radix: 16))"))
        }
        return rows
    }

    /// Returns weapon DPS (damage per second) if it's a weapon
    var weaponDPS: Double? {
        guard let delay = delay, delay > 0,
            let minDmg = dmg_min1, let maxDmg = dmg_max1,
            minDmg > 0 || maxDmg > 0
        else { return nil }

        let avgDamage = (minDmg + maxDmg) / 2.0
        let speedInSeconds = Double(delay) / 1000.0
        return avgDamage / speedInSeconds
    }

    var spellEffects: [SpellEffect] {
        var effects: [SpellEffect] = []
        let spellSlots = [
            (
                spellid_1, spelltrigger_1, spellcharges_1, spellcooldown_1, spellppmrate_1,
                spellcategory_1, spellcategorycooldown_1
            ),
            (
                spellid_2, spelltrigger_2, spellcharges_2, spellcooldown_2, spellppmrate_2,
                spellcategory_2, spellcategorycooldown_2
            ),
            (
                spellid_3, spelltrigger_3, spellcharges_3, spellcooldown_3, spellppmrate_3,
                spellcategory_3, spellcategorycooldown_3
            ),
            (
                spellid_4, spelltrigger_4, spellcharges_4, spellcooldown_4, spellppmrate_4,
                spellcategory_4, spellcategorycooldown_4
            ),
            (
                spellid_5, spelltrigger_5, spellcharges_5, spellcooldown_5, spellppmrate_5,
                spellcategory_5, spellcategorycooldown_5
            ),
        ]

        for (id, trigger, charges, cooldown, ppm, cat, catCD) in spellSlots {
            if let spellId = id, spellId > 0 {
                var procChance: Double?
                if let ppmRate = ppm, ppmRate > 0, let weaponDelay = self.delay, weaponDelay > 0,
                    trigger == 2
                {
                    let weaponSpeedSeconds = Double(weaponDelay) / 1000.0
                    procChance = (ppmRate * weaponSpeedSeconds / 60.0) * 100.0
                }

                effects.append(
                    SpellEffect(
                        spellId: spellId,
                        trigger: trigger,
                        charges: charges,
                        cooldown: cooldown,
                        ppmRate: ppm,
                        procChance: procChance,
                        category: cat,
                        categoryCooldown: catCD
                    ))
            }
        }
        return effects
    }

    /// Filtered spell effects intended for user-facing display.
    /// Rules:
    /// - Always include Use (0) and On Equip (1) effects.
    /// - Include Chance on Hit (2) only if we have metadata (to avoid noisy internal procs) OR a PPM value.
    /// - Exclude unknown triggers unless they have metadata.
    /// - De-duplicate by spellId preserving first occurrence.
    var displayedSpellEffects: [SpellEffect] {
        var seen: Set<Int> = []
        return spellEffects.filter { effect in
            guard !seen.contains(effect.spellId) else { return false }
            seen.insert(effect.spellId)
            let trig = effect.trigger ?? 0
            switch trig {
            case 0, 1:  // Use / On Equip
                return true
            case 2:  // Chance on Hit
                // Show only if we can enrich (meta) or if it has an actual ppm hint
                return effect.meta != nil || (effect.ppmRate ?? 0) > 0
            case 3, 4, 5:  // Soulstone / Use (No Delay) / On Learn
                return effect.meta != nil
            default:
                return effect.meta != nil
            }
        }
    }

    /// Spell effects that were filtered out as likely internal / noise.
    var internalSpellEffects: [SpellEffect] {
        let displayedSet = Set(displayedSpellEffects.map { $0.spellId })
        return spellEffects.filter { !displayedSet.contains($0.spellId) }
    }

    var primarySpellEffectDescription: String? {
        guard let effect = spellEffects.first else { return nil }

        var description = "\(effect.triggerDescription)"

        if let charges = effect.charges, charges != 0 {
            description += " (\(abs(charges)) Charges)"
        }

        if let cooldown = effect.cooldown, cooldown > 0 {
            let seconds = cooldown / 1000
            if seconds >= 60 {
                description += " (\(seconds / 60)m CD)"
            } else {
                description += " (\(seconds)s CD)"
            }
        }
        return description
    }

    var isWeapon: Bool {
        guard let itemClass = `class` else { return false }
        return itemClass == 2  // Weapon class
    }

    var hasArmor: Bool {
        guard let armorValue = armor else { return false }
        return armorValue > 0
    }

    var armorString: String? {
        guard let armor = armor, armor > 0 else { return nil }
        return "\(armor) Armor"
    }

    var weaponDamageString: String? {
        guard let minDmg = dmg_min1, let maxDmg = dmg_max1,
            minDmg > 0 || maxDmg > 0
        else { return nil }

        if minDmg == maxDmg {
            return String(format: "%.0f Damage", minDmg)
        } else {
            return String(format: "%.0f - %.0f Damage", minDmg, maxDmg)
        }
    }

    // MARK: - MEGA Damage Aggregation
    // Collect ALL damage types (up to 5) with their school for comprehensive display.
    struct DamageTypeBundle: Hashable {
        let min: Double
        let max: Double
        let school: Int
    }

    var allDamageTypes: [DamageTypeBundle] {
        let slots: [(Double?, Double?, Int?)] = [
            (dmg_min1, dmg_max1, dmg_type1),
            (dmg_min2, dmg_max2, dmg_type2),
            (dmg_min3, dmg_max3, dmg_type3),
            (dmg_min4, dmg_max4, dmg_type4),
            (dmg_min5, dmg_max5, dmg_type5),
        ]
        return slots.compactMap { (minOpt, maxOpt, typeOpt) in
            guard let min = minOpt, let max = maxOpt, min > 0 || max > 0 else { return nil }
            return DamageTypeBundle(min: min, max: max, school: typeOpt ?? 0)
        }
    }

    // Primary (first) damage line with school name if elemental.
    var primaryDamageString: String? {
        guard let first = allDamageTypes.first else { return nil }
        let schoolName = damageTypeName(for: first.school)
        if first.min == first.max {
            return String(
                format: "%@%@%.0f %@%@Damage",
                schoolName.isEmpty ? "" : "",
                schoolName.isEmpty ? "" : "",
                first.min,
                schoolName,
                schoolName.isEmpty ? "" : " "
            )
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
        } else {
            return String(
                format: "%.0f - %.0f %@%@Damage",
                first.min, first.max,
                schoolName,
                schoolName.isEmpty ? "" : " "
            )
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
        }
    }

    // Additional elemental / secondary damage lines.
    var secondaryDamageStrings: [String] {
        guard allDamageTypes.count > 1 else { return [] }
        return allDamageTypes.dropFirst().map { dmg in
            let schoolName = damageTypeName(for: dmg.school)
            if dmg.min == dmg.max {
                return String(
                    format: "+%.0f %@Damage", dmg.min, schoolName + (schoolName.isEmpty ? "" : " ")
                )
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
            } else {
                return String(
                    format: "+%.0f-%.0f %@Damage", dmg.min, dmg.max,
                    schoolName + (schoolName.isEmpty ? "" : " ")
                )
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
            }
        }
    }

    // Total DPS across all damage types (physical + elemental) using weapon speed.
    var totalDPS: Double? {
        guard let delay = delay, delay > 0, !allDamageTypes.isEmpty else { return nil }
        let totalMin = allDamageTypes.reduce(0) { $0 + $1.min }
        let totalMax = allDamageTypes.reduce(0) { $0 + $1.max }
        guard totalMin > 0 || totalMax > 0 else { return nil }
        let avg = (totalMin + totalMax) / 2.0
        return avg / (Double(delay) / 1000.0)
    }

    var weaponSpeed: String? {
        guard let delay = delay, delay > 0 else { return nil }
        let speedInSeconds = Double(delay) / 1000.0
        return String(format: "%.2f sec", speedInSeconds)
    }

    var dpsString: String? {
        guard let minDmg = dmg_min1,
            let maxDmg = dmg_max1,
            let delay = delay,
            delay > 0
        else { return nil }

        let avgDamage = (minDmg + maxDmg) / 2.0
        let speed = Double(delay) / 1000.0
        let dps = avgDamage / speed

        return String(format: "%.1f DPS", dps)
    }

    var itemTypeName: String {
        guard let itemClass = `class`, let subclass = subclass else { return "Unknown" }

        switch itemClass {
        case 2:  // Weapons
            switch subclass {
            case 0: return "One-Handed Axe"
            case 1: return "Two-Handed Axe"
            case 2: return "Bow"
            case 3: return "Gun"
            case 4: return "One-Handed Mace"
            case 5: return "Two-Handed Mace"
            case 6: return "Polearm"
            case 7: return "One-Handed Sword"
            case 8: return "Two-Handed Sword"
            case 10: return "Staff"
            case 13: return "Fist Weapon"
            case 14: return "Miscellaneous"
            case 15: return "Dagger"
            case 16: return "Thrown"
            case 17: return "Spear"
            case 18: return "Crossbow"
            case 19: return "Wand"
            case 20: return "Fishing Pole"
            default: return "Weapon"
            }
        case 4:  // Armor
            switch subclass {
            case 0: return "Miscellaneous"
            case 1: return "Cloth"
            case 2: return "Leather"
            case 3: return "Mail"
            case 4: return "Plate"
            case 6: return "Shield"
            default: return "Armor"
            }
        default:
            return "Item"
        }
    }

    var formattedStats: [String] {
        var stats: [String] = []

        let statTypes = [
            (stat_type1, stat_value1), (stat_type2, stat_value2),
            (stat_type3, stat_value3), (stat_type4, stat_value4),
            (stat_type5, stat_value5), (stat_type6, stat_value6),
            (stat_type7, stat_value7), (stat_type8, stat_value8),
            (stat_type9, stat_value9), (stat_type10, stat_value10),
        ]

        for (type, value) in statTypes {
            guard let statType = type, let statValue = value, statValue != 0 else { continue }
            if statValue > 0 {
                // Special wording for regen stats
                if statType == 43 {  // Mana regen (mp5)
                    stats.append("+\(statValue) Mana per 5 sec")
                    continue
                } else if statType == 46 {  // Health regen
                    stats.append("+\(statValue) Health per 5 sec")
                    continue
                }
                if let statName = statName(for: statType) {
                    stats.append("+\(statValue) \(statName)")
                }
            } else if statValue < 0 {  // Negative stats (e.g., cursed items) show with minus
                if let statName = statName(for: statType) {
                    stats.append("\(statValue) \(statName)")
                }
            }
        }

        return stats
    }

    /// Returns all non-zero resistances as a formatted array
    var formattedResistances: [String] {
        var resistances: [String] = []

        if let holy = holy_res, holy > 0 {
            resistances.append("+\(holy) Holy Resistance")
        }
        if let fire = fire_res, fire > 0 {
            resistances.append("+\(fire) Fire Resistance")
        }
        if let nature = nature_res, nature > 0 {
            resistances.append("+\(nature) Nature Resistance")
        }
        if let frost = frost_res, frost > 0 {
            resistances.append("+\(frost) Frost Resistance")
        }
        if let shadow = shadow_res, shadow > 0 {
            resistances.append("+\(shadow) Shadow Resistance")
        }
        if let arcane = arcane_res, arcane > 0 {
            resistances.append("+\(arcane) Arcane Resistance")
        }

        return resistances
    }

    /// Returns primary special ability if any
    var primarySpellEffect: String? {
        guard let spellId = spellid_1, spellId > 0 else { return nil }

        var description = "Special Ability: Spell \(spellId)"

        if let trigger = spelltrigger_1 {
            switch trigger {
            case 0: description += " (Use)"
            case 1: description += " (Equip)"
            case 2: description += " (Chance on Hit)"
            case 3: description += " (Soulstone)"
            case 4: description += " (Use - No Delay)"
            default: description += " (Unknown Trigger)"
            }
        }

        if let charges = spellcharges_1, charges > 0 {
            description += " - \(charges) Charges"
        }

        if let cooldown = spellcooldown_1, cooldown > 0 {
            let cooldownSeconds = cooldown / 1000
            if cooldownSeconds >= 60 {
                description += " - \(cooldownSeconds / 60)min cooldown"
            } else {
                description += " - \(cooldownSeconds)sec cooldown"
            }
        }

        return description
    }

    /// Returns all spell effects
    var allSpellEffects: [String] {
        var effects: [String] = []

        let spellSlots = [
            (spellid_1, spelltrigger_1, spellcharges_1, spellcooldown_1),
            (spellid_2, spelltrigger_2, spellcharges_2, spellcooldown_2),
            (spellid_3, spelltrigger_3, spellcharges_3, spellcooldown_3),
            (spellid_4, spelltrigger_4, spellcharges_4, spellcooldown_4),
            (spellid_5, spelltrigger_5, spellcharges_5, spellcooldown_5),
        ]

        for (spellId, trigger, charges, cooldown) in spellSlots {
            guard let id = spellId, id > 0 else { continue }

            var description = "Spell \(id)"

            if let trig = trigger {
                switch trig {
                case 0: description += " (Use)"
                case 1: description += " (Equip)"
                case 2: description += " (Chance on Hit)"
                case 3: description += " (Soulstone)"
                case 4: description += " (Use - No Delay)"
                default: description += " (Unknown Trigger)"
                }
            }

            if let ch = charges, ch > 0 {
                description += " - \(ch) Charges"
            }

            if let cd = cooldown, cd > 0 {
                let cooldownSeconds = cd / 1000
                if cooldownSeconds >= 60 {
                    description += " - \(cooldownSeconds / 60)min cooldown"
                } else {
                    description += " - \(cooldownSeconds)sec cooldown"
                }
            }

            effects.append(description)
        }

        return effects
    }

    // Detailed spell effect objects with extra derived info (PPM -> proc chance approximation).
    struct DetailedSpellEffect: Hashable, Identifiable {
        let id = UUID()
        let spellId: Int
        let triggerName: String
        let charges: Int?
        let cooldownMS: Int?
        let ppm: Double?
        let procChance: Double?  // derived for chance-on-hit PPM based effects
    }

    var detailedSpellEffects: [DetailedSpellEffect] {
        guard hasSpellEffects else { return [] }
        var list: [DetailedSpellEffect] = []
        let slots: [(Int?, Int?, Int?, Int?, Double?)] = [
            (spellid_1, spelltrigger_1, spellcharges_1, spellcooldown_1, spellppmrate_1),
            (spellid_2, spelltrigger_2, spellcharges_2, spellcooldown_2, spellppmrate_2),
            (spellid_3, spelltrigger_3, spellcharges_3, spellcooldown_3, spellppmrate_3),
            (spellid_4, spelltrigger_4, spellcharges_4, spellcooldown_4, spellppmrate_4),
            (spellid_5, spelltrigger_5, spellcharges_5, spellcooldown_5, spellppmrate_5),
        ]
        for (sid, trig, ch, cd, ppm) in slots {
            guard let s = sid, s > 0 else { continue }
            let trigName: String
            switch trig ?? -1 {
            case 0: trigName = "Use"
            case 1: trigName = "On Equip"
            case 2: trigName = "Chance on Hit"
            case 3: trigName = "Soulstone"
            case 4: trigName = "Use (No Delay)"
            default: trigName = "Unknown"
            }
            var procChance: Double?
            if (trig ?? -1) == 2, let ppm = ppm, ppm > 0, let wd = delay, wd > 0 {  // chance on hit
                let speedSec = Double(wd) / 1000.0
                procChance = (ppm * speedSec / 60.0) * 100.0
            }
            list.append(
                DetailedSpellEffect(
                    spellId: s,
                    triggerName: trigName,
                    charges: ch,
                    cooldownMS: cd,
                    ppm: ppm,
                    procChance: procChance
                ))
        }
        return list
    }

    /// Does this item have any spell effects?
    var hasSpellEffects: Bool {
        return [spellid_1, spellid_2, spellid_3, spellid_4, spellid_5]
            .compactMap { $0 }
            .contains { $0 > 0 }
    }

    /// Returns secondary damage types (elemental damage)
    var secondaryDamageTypes: [String] {
        var damages: [String] = []

        let damageSlots = [
            (dmg_min2, dmg_max2, dmg_type2),
            (dmg_min3, dmg_max3, dmg_type3),
            (dmg_min4, dmg_max4, dmg_type4),
            (dmg_min5, dmg_max5, dmg_type5),
        ]

        for (minDmg, maxDmg, type) in damageSlots {
            if let min = minDmg, let max = maxDmg, let dmgType = type, min > 0 || max > 0 {
                let typeName = damageTypeName(for: dmgType)
                if min == max {
                    damages.append("+\(Int(min)) \(typeName) Damage")
                } else {
                    damages.append("+\(Int(min))-\(Int(max)) \(typeName) Damage")
                }
            }
        }

        return damages
    }

    /// Item binding description
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

    /// Is this item part of a set?
    var isSetItem: Bool {
        return (set_id ?? 0) > 0
    }

    /// Does this item start a quest?
    var startsQuest: Bool {
        return (start_quest ?? 0) > 0
    }

    /// Is this a readable item?
    var isReadable: Bool {
        return (page_text ?? 0) > 0
    }

    var setName: String? {
        guard let setId = set_id else { return nil }
        return itemSetName(for: setId)
    }

    private func itemSetName(for setId: Int) -> String? {
        // This is a simplified mapping. A real app might load this from a separate table.
        let setNames: [Int: String] = [
            1: "The Gladiator", 41: "Dal'Rend's Arms", 65: "The Postmaster",
            81: "Spirit of Eskhandar", 121: "Valor", 122: "Magister's",
            123: "Devout", 124: "Dreadmist", 141: "Wildheart",
            142: "Beaststalker's", 143: "Lightforge", 144: "Shadowcraft",
            161: "Arcanist", 162: "Felheart", 163: "Cenarion",
            164: "Giantstalker", 165: "Earthfury", 166: "Might",
            167: "Lawbringer", 168: "Nightslayer", 181: "Necropile",
            182: "Cadaverous", 183: "Bloodmail", 184: "Deathbone",
            185: "Volcanic", 186: "Ironweave", 201: "Prophecy",
            202: "Nemesis", 203: "Stormrage", 204: "Dragonstalker's",
            205: "Ten Storms", 206: "Judgement", 207: "Bloodfang",
            208: "Wrath", 210: "Netherwind", 211: "Transcendence",
            212: "Bonescythe", 213: "Thunderfury", 214: "Redemption",
            215: "Plagueheart", 216: "The Five Thunders",
        ]
        return setNames[setId]
    }

    private func damageTypeName(for type: Int) -> String {
        switch type {
        case 0: return ""
        case 1: return "Holy"
        case 2: return "Fire"
        case 3: return "Nature"
        case 4: return "Frost"
        case 5: return "Shadow"
        case 6: return "Arcane"
        default: return "Magic"
        }
    }

    private func statName(for type: Int) -> String? {
        switch type {
        case 3: return "Agility"
        case 4: return "Strength"
        case 5: return "Intellect"
        case 6: return "Spirit"
        case 7: return "Stamina"
        case 12: return "Defense"
        case 13: return "Dodge"
        case 14: return "Parry"
        case 15: return "Block"
        case 16: return "Hit"
        case 17: return "Crit"
        case 18: return "Hit (Ranged)"
        case 19: return "Crit (Ranged)"
        case 20: return "Hit (Spell)"
        case 21: return "Crit (Spell)"
        case 31: return "Hit"
        case 32: return "Crit"
        case 35: return "Resilience"
        case 36: return "Haste"
        case 37: return "Expertise"
        case 38: return "Attack Power"
        case 39: return "Ranged Attack Power"
        case 43: return "Mana per 5"
        case 44: return "Armor Penetration"
        case 45: return "Spell Power"
        case 46: return "Health per 5"
        case 47: return "Spell Penetration"
        case 48: return "Block Value"
        default: return nil
        }
    }

    // Reflection-based dump of all stored fields (literal everything) for UI disclosure.
    var rawFieldPairs: [(String, String)] {
        var result: [(String, String)] = []
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let label = child.label else { continue }
            // Skip computed id (duplicate of entry)
            if label == "id" { continue }
            if let str = stringifyRawValue(child.value) {
                result.append((label, str))
            }
        }
        // Stable sort by field name
        result.sort { $0.0 < $1.0 }
        return result
    }

    private func stringifyRawValue(_ value: Any) -> String? {
        // Unwrap optionals
        let mirrored = Mirror(reflecting: value)
        if mirrored.displayStyle == .optional {
            if let first = mirrored.children.first {
                return stringifyRawValue(first.value)
            } else {
                return nil
            }
        }
        if let v = value as? String { return v }
        if let v = value as? CustomStringConvertible { return v.description }
        return String(describing: value)
    }
}
