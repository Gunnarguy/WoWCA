// Data/Models/ItemMegaEnhanced.swift
import Foundation
import GRDB

struct ItemMegaEnhanced: Codable, FetchableRecord, Identifiable, Equatable, Hashable {
    // MARK: - Basic Properties
    var entry: Int64
    var name: String
    var description: String?
    var quality: Int
    var `class`: Int?
    var subclass: Int?
    var patch: Int?

    // MARK: - Display & UI
    var display_id: Int?
    var inventory_type: Int?
    var flags: Int?

    // MARK: - Economy
    var buy_count: Int?
    var buy_price: Int?
    var sell_price: Int?

    // MARK: - Level & Requirements
    var item_level: Int?
    var required_level: Int?
    var required_skill: Int?
    var required_skill_rank: Int?
    var required_spell: Int?
    var required_honor_rank: Int?
    var required_city_rank: Int?
    var required_reputation_faction: Int?
    var required_reputation_rank: Int?

    // MARK: - Restrictions
    var allowable_class: Int?
    var allowable_race: Int?

    // MARK: - Item Properties
    var max_count: Int?
    var stackable: Int?
    var container_slots: Int?
    var bonding: Int?
    var material: Int?
    var sheath: Int?

    // MARK: - ALL 10 Stat Slots!
    var stat_type1: Int?, stat_value1: Int?
    var stat_type2: Int?, stat_value2: Int?
    var stat_type3: Int?, stat_value3: Int?
    var stat_type4: Int?, stat_value4: Int?
    var stat_type5: Int?, stat_value5: Int?
    var stat_type6: Int?, stat_value6: Int?
    var stat_type7: Int?, stat_value7: Int?
    var stat_type8: Int?, stat_value8: Int?
    var stat_type9: Int?, stat_value9: Int?
    var stat_type10: Int?, stat_value10: Int?

    // MARK: - Weapon Properties
    var delay: Int?
    var range_mod: Double?
    var ammo_type: Int?

    // MARK: - ALL 5 Damage Types!
    var dmg_min1: Double?, dmg_max1: Double?, dmg_type1: Int?
    var dmg_min2: Double?, dmg_max2: Double?, dmg_type2: Int?
    var dmg_min3: Double?, dmg_max3: Double?, dmg_type3: Int?
    var dmg_min4: Double?, dmg_max4: Double?, dmg_type4: Int?
    var dmg_min5: Double?, dmg_max5: Double?, dmg_type5: Int?

    // MARK: - Defense
    var block: Int?
    var armor: Int?

    // MARK: - ALL Resistances!
    var holy_res: Int?
    var fire_res: Int?
    var nature_res: Int?
    var frost_res: Int?
    var shadow_res: Int?
    var arcane_res: Int?

    // MARK: - ALL 5 Spell Slots!
    var spellid_1: Int?, spelltrigger_1: Int?, spellcharges_1: Int?
    var spellppmrate_1: Double?, spellcooldown_1: Int?, spellcategory_1: Int?,
        spellcategorycooldown_1: Int?

    var spellid_2: Int?, spelltrigger_2: Int?, spellcharges_2: Int?
    var spellppmrate_2: Double?, spellcooldown_2: Int?, spellcategory_2: Int?,
        spellcategorycooldown_2: Int?

    var spellid_3: Int?, spelltrigger_3: Int?, spellcharges_3: Int?
    var spellppmrate_3: Double?, spellcooldown_3: Int?, spellcategory_3: Int?,
        spellcategorycooldown_3: Int?

    var spellid_4: Int?, spelltrigger_4: Int?, spellcharges_4: Int?
    var spellppmrate_4: Double?, spellcooldown_4: Int?, spellcategory_4: Int?,
        spellcategorycooldown_4: Int?

    var spellid_5: Int?, spelltrigger_5: Int?, spellcharges_5: Int?
    var spellppmrate_5: Double?, spellcooldown_5: Int?, spellcategory_5: Int?,
        spellcategorycooldown_5: Int?

    // MARK: - Special Properties
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

    // MARK: - MEGA Computed Properties

    /// Returns all active spell effects
    var spellEffects: [SpellEffect] {
        var effects: [SpellEffect] = []

        let spellSlots = [
            (spellid_1, spelltrigger_1, spellcharges_1, spellppmrate_1, spellcooldown_1),
            (spellid_2, spelltrigger_2, spellcharges_2, spellppmrate_2, spellcooldown_2),
            (spellid_3, spelltrigger_3, spellcharges_3, spellppmrate_3, spellcooldown_3),
            (spellid_4, spelltrigger_4, spellcharges_4, spellppmrate_4, spellcooldown_4),
            (spellid_5, spelltrigger_5, spellcharges_5, spellppmrate_5, spellcooldown_5),
        ]

        for (spellId, trigger, charges, ppmRate, cooldown) in spellSlots {
            if let id = spellId, id > 0 {
                effects.append(
                    SpellEffect(
                        spellId: id,
                        trigger: SpellTrigger(rawValue: trigger ?? 0) ?? .none,
                        charges: charges ?? 0,
                        procRate: ppmRate ?? 0.0,
                        cooldown: cooldown ?? -1
                    ))
            }
        }

        return effects
    }

    /// Returns all damage types for weapons
    var allDamageTypes: [DamageType] {
        var damages: [DamageType] = []

        let damageSlots = [
            (dmg_min1, dmg_max1, dmg_type1),
            (dmg_min2, dmg_max2, dmg_type2),
            (dmg_min3, dmg_max3, dmg_type3),
            (dmg_min4, dmg_max4, dmg_type4),
            (dmg_min5, dmg_max5, dmg_type5),
        ]

        for (minDmg, maxDmg, type) in damageSlots {
            if let min = minDmg, let max = maxDmg, let dmgType = type, min > 0 || max > 0 {
                damages.append(
                    DamageType(
                        minDamage: min,
                        maxDamage: max,
                        type: DamageSchool(rawValue: dmgType) ?? .physical
                    ))
            }
        }

        return damages
    }

    /// Returns ALL 10 stats as formatted strings
    var allFormattedStats: [String] {
        var stats: [String] = []

        let statSlots = [
            (stat_type1, stat_value1), (stat_type2, stat_value2),
            (stat_type3, stat_value3), (stat_type4, stat_value4),
            (stat_type5, stat_value5), (stat_type6, stat_value6),
            (stat_type7, stat_value7), (stat_type8, stat_value8),
            (stat_type9, stat_value9), (stat_type10, stat_value10),
        ]

        for (type, value) in statSlots {
            if let statType = type, let statValue = value, statValue > 0 {
                if let statName = statName(for: statType) {
                    stats.append("+\(statValue) \(statName)")
                }
            }
        }

        return stats
    }

    /// Returns ALL resistances
    var allResistances: [String] {
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

    /// Item binding type
    var bindingType: BindingType {
        return BindingType(rawValue: bonding ?? 0) ?? .none
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

    /// Primary weapon damage string (main damage type)
    var primaryDamageString: String? {
        let primary = allDamageTypes.first
        guard let dmg = primary else { return nil }

        if dmg.minDamage == dmg.maxDamage {
            return String(format: "%.0f %@ Damage", dmg.minDamage, dmg.type.displayName)
        } else {
            return String(
                format: "%.0f - %.0f %@ Damage", dmg.minDamage, dmg.maxDamage, dmg.type.displayName)
        }
    }

    /// Secondary damage types (elemental damage, etc.)
    var secondaryDamageStrings: [String] {
        return Array(allDamageTypes.dropFirst()).map { dmg in
            if dmg.minDamage == dmg.maxDamage {
                return String(format: "+%.0f %@ Damage", dmg.minDamage, dmg.type.displayName)
            } else {
                return String(
                    format: "+%.0f-%.0f %@ Damage", dmg.minDamage, dmg.maxDamage,
                    dmg.type.displayName)
            }
        }
    }

    /// Total DPS including all damage types
    var totalDPS: Double? {
        guard let delay = delay, delay > 0 else { return nil }

        let totalMinDamage = allDamageTypes.reduce(0) { $0 + $1.minDamage }
        let totalMaxDamage = allDamageTypes.reduce(0) { $0 + $1.maxDamage }

        guard totalMinDamage > 0 || totalMaxDamage > 0 else { return nil }

        let avgDamage = (totalMinDamage + totalMaxDamage) / 2.0
        let speedInSeconds = Double(delay) / 1000.0
        return avgDamage / speedInSeconds
    }

    // MARK: - Helper Functions

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
        case 31: return "Hit Rating"
        case 32: return "Crit Rating"
        case 35: return "Resilience"
        case 36: return "Haste"
        case 37: return "Expertise"
        case 38: return "Attack Power"
        case 39: return "Ranged Attack Power"
        case 43: return "Mana Regen"
        case 44: return "Armor Penetration"
        case 45: return "Spell Power"
        case 46: return "Health Regen"
        case 47: return "Spell Penetration"
        case 48: return "Block Value"
        default: return nil
        }
    }
}

// MARK: - Supporting Enums and Structs

struct SpellEffect {
    let spellId: Int
    let trigger: SpellTrigger
    let charges: Int
    let procRate: Double
    let cooldown: Int

    var formattedDescription: String {
        var description = "Spell \(spellId)"

        switch trigger {
        case .none: description += " (No Trigger)"
        case .onUse: description += " (Use)"
        case .onEquip: description += " (Equip)"
        case .chanceOnHit:
            description += " (Proc on Hit"
            if procRate > 0 {
                description += ", \(String(format: "%.1f", procRate)) PPM"
            }
            description += ")"
        case .soulstone: description += " (Soulstone)"
        case .onUseNoDelay: description += " (Use - No Delay)"
        }

        if charges > 0 {
            description += " - \(charges) Charges"
        }

        if cooldown > 0 {
            let cooldownSeconds = cooldown / 1000
            if cooldownSeconds >= 60 {
                description += " - \(cooldownSeconds / 60)min cooldown"
            } else {
                description += " - \(cooldownSeconds)sec cooldown"
            }
        }

        return description
    }
}

enum SpellTrigger: Int {
    case none = 0
    case onUse = 1
    case onEquip = 2
    case chanceOnHit = 3
    case soulstone = 4
    case onUseNoDelay = 5
}

struct DamageType {
    let minDamage: Double
    let maxDamage: Double
    let type: DamageSchool
}

enum DamageSchool: Int {
    case physical = 0
    case holy = 1
    case fire = 2
    case nature = 3
    case frost = 4
    case shadow = 5
    case arcane = 6

    var displayName: String {
        switch self {
        case .physical: return ""
        case .holy: return "Holy"
        case .fire: return "Fire"
        case .nature: return "Nature"
        case .frost: return "Frost"
        case .shadow: return "Shadow"
        case .arcane: return "Arcane"
        }
    }

    var color: String {
        switch self {
        case .physical: return "primary"
        case .holy: return "yellow"
        case .fire: return "red"
        case .nature: return "green"
        case .frost: return "cyan"
        case .shadow: return "purple"
        case .arcane: return "pink"
        }
    }
}

enum BindingType: Int {
    case none = 0
    case bindOnPickup = 1
    case bindOnEquip = 2
    case bindOnUse = 3
    case questItem = 4

    var displayName: String {
        switch self {
        case .none: return ""
        case .bindOnPickup: return "Binds when picked up"
        case .bindOnEquip: return "Binds when equipped"
        case .bindOnUse: return "Binds when used"
        case .questItem: return "Quest Item"
        }
    }
}
