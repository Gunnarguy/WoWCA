// Data/Models/Item.swift
import Foundation
import GRDB

struct Item: Codable, FetchableRecord, Identifiable, Equatable {
    var entry: Int64
    var name: String
    var quality: Int
    var `class`: Int?
    var subclass: Int?
    var inventory_type: Int?
    var item_level: Int?
    var required_level: Int?

    // Enhanced stats
    var stat_type1: Int?
    var stat_value1: Int?
    var stat_type2: Int?
    var stat_value2: Int?
    var stat_type3: Int?
    var stat_value3: Int?
    var stat_type4: Int?
    var stat_value4: Int?

    // Weapon stats
    var delay: Int?  // Attack speed in milliseconds
    var dmg_min1: Double?
    var dmg_max1: Double?
    var dmg_type1: Int?

    // Armor and resistances
    var armor: Int?
    var fire_res: Int?
    var nature_res: Int?
    var frost_res: Int?
    var shadow_res: Int?

    // Other useful info
    var allowable_class: Int?
    var buy_price: Int?
    var sell_price: Int?

    var id: Int64 { entry }
}

// MARK: - Computed Properties for Better Display

extension Item {

    /// Returns a formatted weapon speed string (e.g., "1.50 sec")
    var weaponSpeed: String? {
        guard let delay = delay, delay > 0 else { return nil }
        let speedInSeconds = Double(delay) / 1000.0
        return String(format: "%.2f sec", speedInSeconds)
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

    /// Returns a formatted weapon damage string (e.g., "37 - 69 Damage")
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

    /// Returns formatted DPS string (e.g., "35.3 DPS")
    var dpsString: String? {
        guard let dps = weaponDPS else { return nil }
        return String(format: "%.1f DPS", dps)
    }

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

    /// Returns item type name based on inventory_type
    var itemTypeName: String {
        guard let inventoryType = inventory_type else { return "Unknown" }

        switch inventoryType {
        case 0: return "Non-equipable"
        case 1: return "Head"
        case 2: return "Neck"
        case 3: return "Shoulder"
        case 4: return "Shirt"
        case 5: return "Chest"
        case 6: return "Waist"
        case 7: return "Legs"
        case 8: return "Feet"
        case 9: return "Wrists"
        case 10: return "Hands"
        case 11: return "Finger"
        case 12: return "Trinket"
        case 13: return "One-Hand"
        case 14: return "Shield"
        case 15: return "Ranged"
        case 16: return "Back"
        case 17: return "Two-Hand"
        case 18: return "Bag"
        case 20: return "Robe"
        case 21: return "Main Hand"
        case 22: return "Off Hand"
        case 23: return "Held In Off-hand"
        case 24: return "Ammo"
        case 25: return "Thrown"
        case 26: return "Ranged (right)"
        case 28: return "Relic"
        default: return "Unknown (\(inventoryType))"
        }
    }

    /// Returns all non-zero stats as a formatted array
    var formattedStats: [String] {
        var stats: [String] = []

        // Helper to add stat if non-zero
        func addStat(type: Int?, value: Int?) {
            guard let type = type, let value = value, type > 0, value != 0 else { return }

            let statName = statTypeName(type)
            let sign = value > 0 ? "+" : ""
            stats.append("\(sign)\(value) \(statName)")
        }

        // Add available stats
        addStat(type: stat_type1, value: stat_value1)
        addStat(type: stat_type2, value: stat_value2)
        addStat(type: stat_type3, value: stat_value3)
        addStat(type: stat_type4, value: stat_value4)

        return stats
    }

    /// Returns all non-zero resistances as a formatted array
    var formattedResistances: [String] {
        var resistances: [String] = []

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

        return resistances
    }

    /// Returns true if this item is a weapon
    var isWeapon: Bool {
        guard let inventoryType = inventory_type else { return false }
        return [13, 15, 17, 21, 22, 25, 26].contains(inventoryType)
    }

    /// Returns true if this item has armor
    var hasArmor: Bool {
        guard let armor = armor else { return false }
        return armor > 0
    }

    /// Returns formatted armor string if item has armor
    var armorString: String? {
        guard let armor = armor, armor > 0 else { return nil }
        return "\(armor) Armor"
    }

    /// Helper function to convert stat type ID to readable name
    private func statTypeName(_ type: Int) -> String {
        switch type {
        case 3: return "Agility"
        case 4: return "Strength"
        case 5: return "Intellect"
        case 6: return "Spirit"
        case 7: return "Stamina"
        case 12: return "Defense Rating"
        case 13: return "Dodge Rating"
        case 14: return "Parry Rating"
        case 15: return "Block Rating"
        case 16: return "Hit Rating"
        case 17: return "Crit Rating"
        case 18: return "Hit Avoidance"
        case 19: return "Crit Avoidance"
        case 20: return "Hit Taken"
        case 21: return "Crit Taken"
        case 22: return "Hit Taken Rating"
        case 23: return "Crit Taken Rating"
        case 24: return "Haste Rating"
        case 25: return "Expertise Rating"
        case 26: return "Attack Power"
        case 27: return "Ranged Attack Power"
        case 28: return "Feral Attack Power"
        case 29: return "Healing"
        case 30: return "Spell Damage"
        case 31: return "Mana Per 5"
        case 32: return "Armor Penetration"
        case 33: return "Spell Power"
        case 34: return "Health Per 5"
        case 35: return "Spell Penetration"
        case 36: return "Health Regen"
        case 37: return "Spell Damage Taken"
        case 38: return "Mana Regen"
        case 39: return "Armor Penetration Rating"
        case 40: return "Spell Haste Rating"
        case 41: return "Spell Hit Rating"
        case 42: return "Spell Crit Rating"
        case 43: return "Spell Hit Taken"
        case 44: return "Spell Crit Taken"
        case 45: return "Resilience"
        default: return "Unknown Stat (\(type))"
        }
    }
}
