//
//  Spell.swift
//  WoWCA
//
//  Created by Gunnar Hostetler on 8/14/25.
//

import Foundation

#if canImport(GRDB)
    import GRDB
#endif

struct Spell: Codable, Identifiable, Equatable, Hashable {
    var id: Int
    var build: Int?
    var name1: String?
    var description1: String?
    var school: Int?
    var category: Int?
    var castingTimeIndex: Int?
    var dispel: Int?
    var mechanic: Int?
    var attributes: Int?
    var attributesEx: Int?
    var attributesEx2: Int?
    var attributesEx3: Int?
    var attributesEx4: Int?
    var stances: Int?
    var stancesNot: Int?
    var targets: Int?
    var targetCreatureType: Int?
    var requiresShapeShift: Int?
    var procFlags: Int?
    var procChance: Int?
    var procCharges: Int?
    var maxLevel: Int?
    var baseLevel: Int?
    var spellLevel: Int?
    var durationIndex: Int?
    var powerType: Int?
    var manaCost: Int?
    var manaCostPerLevel: Int?
    var manaPerSecond: Int?
    var manaPerSecondPerLevel: Int?
    var rangeIndex: Int?
    var speed: Double?
    var modalNextSpell: Int?
    var stackAmount: Int?
    var totem1: Int?
    var totem2: Int?
    var reagent1: Int?
    var reagent2: Int?
    var reagent3: Int?
    var reagent4: Int?
    var reagent5: Int?
    var reagent6: Int?
    var reagent7: Int?
    var reagent8: Int?
    var reagentCount1: Int?
    var reagentCount2: Int?
    var reagentCount3: Int?
    var reagentCount4: Int?
    var reagentCount5: Int?
    var reagentCount6: Int?
    var reagentCount7: Int?
    var reagentCount8: Int?
    var equippedItemClass: Int?
    var equippedItemSubClassMask: Int?
    var equippedItemInventoryTypeMask: Int?
    var effect1: Int?
    var effect2: Int?
    var effect3: Int?
    var effectDieSides1: Int?
    var effectDieSides2: Int?
    var effectDieSides3: Int?
    var effectBaseDice1: Double?
    var effectBaseDice2: Double?
    var effectBaseDice3: Double?
    var effectDicePerLevel1: Double?
    var effectDicePerLevel2: Double?
    var effectDicePerLevel3: Double?
    var effectRealPointsPerLevel1: Double?
    var effectRealPointsPerLevel2: Double?
    var effectRealPointsPerLevel3: Double?
    var effectBasePoints1: Int?
    var effectBasePoints2: Int?
    var effectBasePoints3: Int?
    var effectMechanic1: Int?
    var effectMechanic2: Int?
    var effectMechanic3: Int?
    var effectImplicitTargetA1: Int?
    var effectImplicitTargetA2: Int?
    var effectImplicitTargetA3: Int?
    var effectImplicitTargetB1: Int?
    var effectImplicitTargetB2: Int?
    var effectImplicitTargetB3: Int?
    var effectRadiusIndex1: Int?
    var effectRadiusIndex2: Int?
    var effectRadiusIndex3: Int?
    var effectApplyAuraName1: Int?
    var effectApplyAuraName2: Int?
    var effectApplyAuraName3: Int?
    var effectAmplitude1: Int?
    var effectAmplitude2: Int?
    var effectAmplitude3: Int?
    var effectMultipleValue1: Double?
    var effectMultipleValue2: Double?
    var effectMultipleValue3: Double?
    var effectChainTarget1: Int?
    var effectChainTarget2: Int?
    var effectChainTarget3: Int?
    var effectItemType1: Int?
    var effectItemType2: Int?
    var effectItemType3: Int?
    var effectMiscValue1: Int?
    var effectMiscValue2: Int?
    var effectMiscValue3: Int?
    var effectTriggerSpell1: Int?
    var effectTriggerSpell2: Int?
    var effectTriggerSpell3: Int?
    var effectPointsPerComboPoint1: Double?
    var effectPointsPerComboPoint2: Double?
    var effectPointsPerComboPoint3: Double?
    var spellVisual1: Int?
    var spellVisual2: Int?
    var spellIconId: Int?
    var activeIconId: Int?
    var spellPriority: Int?
    var name2: String?
    var name3: String?
    var name4: String?
    var name5: String?
    var name6: String?
    var name7: String?
    var name8: String?
    var name9: String?
    var name10: String?
    var name11: String?
    var name12: String?
    var name13: String?
    var name14: String?
    var name15: String?
    var name16: String?
    var description2: String?
    var description3: String?
    var description4: String?
    var description5: String?
    var description6: String?
    var description7: String?
    var description8: String?
    var description9: String?
    var description10: String?
    var description11: String?
    var description12: String?
    var description13: String?
    var description14: String?
    var description15: String?
    var description16: String?
    var recoveryTime: Int?
    var categoryRecoveryTime: Int?
    var interruptFlags: Int?
    var auraInterruptFlags: Int?
    var channelInterruptFlags: Int?
    var procTypeMask: Int?
    var procEx: Int?
    var dmgClass: Int?
    var preventionType: Int?
    var stanceBarOrder: Int?
    var dmgMultiplier1: Double?
    var dmgMultiplier2: Double?
    var dmgMultiplier3: Double?
    var minFactionId: Int?
    var minReputation: Int?
    var requiredFactionId: Int?
    var requiredFactionRep: Int?

    var spellBonuses: [String] {
        var bonuses: [String] = []

        // Check for spell damage (aura 13) and healing (aura 135) combinations
        var spellDamageValue: Int? = nil
        var healingValue: Int? = nil

        for i in 1...3 {
            var auraName: Int?
            var basePoints: Int?

            switch i {
            case 1:
                auraName = effectApplyAuraName1
                basePoints = effectBasePoints1
            case 2:
                auraName = effectApplyAuraName2
                basePoints = effectBasePoints2
            case 3:
                auraName = effectApplyAuraName3
                basePoints = effectBasePoints3
            default:
                break
            }

            if let aura = auraName, let points = basePoints {
                let value = points + 1  // Base points are stored as value - 1

                switch aura {
                case 13:
                    spellDamageValue = value
                case 135:
                    // Check if this is a standalone healing bonus or part of spell damage
                    if spellDamageValue == nil {
                        healingValue = value
                    }
                case 108:
                    healingValue = value
                default:
                    break
                }
            }
        }

        // Add the bonuses to the array
        if let spellDamage = spellDamageValue {
            if let healing = healingValue, spellDamage == healing {
                // Both spell damage and healing with same value
                bonuses.append("+\(spellDamage) Spell Damage and Healing")
            } else {
                bonuses.append("+\(spellDamage) Spell Damage")
            }
        }

        if let healing = healingValue, spellDamageValue == nil {
            // Standalone healing bonus
            bonuses.append("+\(healing) Healing Power")
        }

        return bonuses
    }

    nonisolated static var databaseTableName: String { "spell_template_ultimate_nerd" }

    // Parse spell description and replace placeholder variables
    func parsedDescription() -> String {
        guard let description = description1, !description.isEmpty else {
            return "No description available"
        }

        var parsed = description

        // Replace $s1, $s2, $s3 with calculated effect values
        if let basePoints1 = effectBasePoints1 {
            let value1 = basePoints1 + 1  // Base points are stored as value - 1
            parsed = parsed.replacingOccurrences(of: "$s1", with: "\(value1)")
        }

        if let basePoints2 = effectBasePoints2 {
            let value2 = basePoints2 + 1
            parsed = parsed.replacingOccurrences(of: "$s2", with: "\(value2)")
        }

        if let basePoints3 = effectBasePoints3 {
            let value3 = basePoints3 + 1
            parsed = parsed.replacingOccurrences(of: "$s3", with: "\(value3)")
        }

        // Replace $o1, $o2, $o3 with over-time damage (usually same as base points)
        if let basePoints1 = effectBasePoints1 {
            let value1 = basePoints1 + 1
            parsed = parsed.replacingOccurrences(of: "$o1", with: "\(value1)")
        }

        if let basePoints2 = effectBasePoints2 {
            let value2 = basePoints2 + 1
            parsed = parsed.replacingOccurrences(of: "$o2", with: "\(value2)")
        }

        if let basePoints3 = effectBasePoints3 {
            let value3 = basePoints3 + 1
            parsed = parsed.replacingOccurrences(of: "$o3", with: "\(value3)")
        }

        // Replace $d with actual duration using duration index lookup
        if let durationText = durationText() {
            parsed = parsed.replacingOccurrences(of: "$d", with: durationText)
        } else {
            parsed = parsed.replacingOccurrences(of: "$d", with: "[duration]")
        }

        // Handle references to other spells like $6788d (duration of spell 6788)
        let spellDurationPattern = #"\$(\d+)d"#
        let spellDurationRegex = try! NSRegularExpression(pattern: spellDurationPattern)
        let spellDurationRange = NSRange(location: 0, length: parsed.utf16.count)
        let spellDurationMatches = spellDurationRegex.matches(in: parsed, range: spellDurationRange)

        for match in spellDurationMatches.reversed() {
            let matchRange = match.range(at: 1)  // Capture group 1 (the spell ID)
            if let swiftRange = Range(matchRange, in: parsed) {
                let spellId = Int(String(parsed[swiftRange])) ?? 0
                let replacement = lookupSpellDuration(spellId: spellId)
                let fullMatchRange = match.range
                if let fullSwiftRange = Range(fullMatchRange, in: parsed) {
                    parsed.replaceSubrange(fullSwiftRange, with: replacement)
                }
            }
        }

        // Handle cross-spell references like $17809s1
        let crossSpellPattern = #"\$(\d+)s(\d+)"#
        let crossSpellRegex = try! NSRegularExpression(pattern: crossSpellPattern)
        let crossSpellRange = NSRange(location: 0, length: parsed.utf16.count)
        let crossSpellMatches = crossSpellRegex.matches(in: parsed, range: crossSpellRange)

        for match in crossSpellMatches.reversed() {
            let spellIdRange = match.range(at: 1)
            let effectIndexRange = match.range(at: 2)

            if let spellIdSwiftRange = Range(spellIdRange, in: parsed),
                let effectIndexSwiftRange = Range(effectIndexRange, in: parsed)
            {
                let spellId = Int(String(parsed[spellIdSwiftRange])) ?? 0
                let effectIndex = Int(String(parsed[effectIndexSwiftRange])) ?? 0
                let replacement = lookupSpellEffectValue(spellId: spellId, effectIndex: effectIndex)
                let fullMatchRange = match.range
                if let fullSwiftRange = Range(fullMatchRange, in: parsed) {
                    parsed.replaceSubrange(fullSwiftRange, with: replacement)
                }
            }
        }

        // Handle $x1, $x2, $x3 patterns (target counts, chain targets, etc.)
        // These usually come from effectChainTarget or maxAffectedTargets
        for i in 1...3 {
            let pattern = "$x\(i)"
            if parsed.contains(pattern) {
                let replacement = getTargetCount(effectIndex: i)
                parsed = parsed.replacingOccurrences(of: pattern, with: replacement)
            }
        }

        // Handle $m1, $m2, $m3 patterns (misc values, resistance amounts, etc.)
        for i in 1...3 {
            let pattern = "$m\(i)"
            if parsed.contains(pattern) {
                let replacement = getMiscValue(effectIndex: i)
                parsed = parsed.replacingOccurrences(of: pattern, with: replacement)
            }
        }

        // Handle pluralization like $lpoint:points;
        let pluralPattern = #"\$l([^:]+):([^;]+);"#
        parsed = parsed.replacingOccurrences(
            of: pluralPattern,
            with: "$2",  // Use plural form
            options: .regularExpression)

        // Replace remaining $ patterns with generic placeholders
        parsed = parsed.replacingOccurrences(
            of: #"\$[a-zA-Z0-9]+"#,
            with: "X",
            options: .regularExpression)

        return parsed
    }

    // Calculate actual damage range for damage effects
    func damageRange(effectIndex: Int) -> String? {
        var basePoints: Int?
        var dieSides: Int?
        var baseDice: Double?
        var effectType: Int?

        switch effectIndex {
        case 1:
            basePoints = effectBasePoints1
            dieSides = effectDieSides1
            baseDice = effectBaseDice1
            effectType = effect1
        case 2:
            basePoints = effectBasePoints2
            dieSides = effectDieSides2
            baseDice = effectBaseDice2
            effectType = effect2
        case 3:
            basePoints = effectBasePoints3
            dieSides = effectDieSides3
            baseDice = effectBaseDice3
            effectType = effect3
        default:
            return nil
        }

        guard let base = basePoints, let type = effectType else { return nil }

        // Only show damage for actual damage effect types
        let damageEffectTypes: Set<Int> = [1, 2, 4, 31, 44]  // School damage, instant damage, dummy damage, weapon damage, normalized weapon damage
        guard damageEffectTypes.contains(type) else { return nil }

        let actualBase = base + 1  // Base points are stored as value - 1

        // Only show damage if it's a positive value
        if let sides = dieSides, sides > 0, let dice = baseDice, dice > 0, actualBase > 0 {
            let minDamage = actualBase + Int(dice)
            let maxDamage = actualBase + Int(dice) * sides
            return "\(minDamage)-\(maxDamage)"
        } else if actualBase > 0 {
            return "\(actualBase)"
        }

        return nil
    }

    // Helper methods for spell parsing
    private func getTargetCount(effectIndex: Int) -> String {
        // Try to get from chain targets or misc values, fallback to reasonable defaults
        switch effectIndex {
        case 1:
            if let chainTargets = effectChainTarget1, chainTargets > 0 {
                return "\(chainTargets)"
            }
            if let miscValue = effectMiscValue1, miscValue > 0 {
                return "\(miscValue)"
            }
        case 2:
            if let chainTargets = effectChainTarget2, chainTargets > 0 {
                return "\(chainTargets)"
            }
            if let miscValue = effectMiscValue2, miscValue > 0 {
                return "\(miscValue)"
            }
        case 3:
            if let chainTargets = effectChainTarget3, chainTargets > 0 {
                return "\(chainTargets)"
            }
            if let miscValue = effectMiscValue3, miscValue > 0 {
                return "\(miscValue)"
            }
        default:
            break
        }

        // Common defaults for well-known spells
        if id == 21992 {  // Thunderfury
            return "4"  // Affects 4 targets
        }

        return "X"  // Fallback
    }

    private func getMiscValue(effectIndex: Int) -> String {
        switch effectIndex {
        case 1:
            if let miscValue = effectMiscValue1, miscValue != 0 {
                return "\(miscValue)"
            }
        case 2:
            if let miscValue = effectMiscValue2, miscValue != 0 {
                return "\(miscValue)"
            }
        case 3:
            if let miscValue = effectMiscValue3, miscValue != 0 {
                return "\(miscValue)"
            }
        default:
            break
        }
        return "X"  // Fallback
    }

    // Duration lookup based on common WoW Classic duration indices
    func durationText() -> String? {
        guard let index = durationIndex, index > 0 else { return nil }

        // Common WoW Classic duration mappings based on duration index
        switch index {
        case 1: return "10 sec"  // Short buffs/debuffs
        case 2: return "12 sec"  // Medium buffs
        case 3: return "18 sec"  // Longer buffs
        case 4: return "21 sec"  // Extended buffs
        case 5: return "27 sec"  // Long buffs
        case 6: return "30 sec"  // Standard buffs
        case 7: return "45 sec"  // Extended buffs
        case 8: return "1 min"  // Medium duration
        case 9: return "2 min"  // Long duration
        case 10: return "3 min"  // Extended duration
        case 15: return "5 min"  // Long term buffs
        case 18: return "8 sec"  // Short debuffs
        case 21: return "until cancelled"  // Permanent until removed
        case 22: return "45 sec"  // Extended debuffs
        case 23: return "1 hour"  // Very long buffs
        case 25: return "15 sec"  // Medium debuffs
        case 26: return "3 sec"  // Very short effects
        case 27: return "6 sec"  // Short stuns/effects
        case 28: return "5 sec"  // Short effects
        case 29: return "12 sec"  // Thunderfury slow effect
        case 30: return "30 min"  // Extended buffs
        case 31: return "8 sec"  // Damage over time
        default:
            // For unknown indices, try to give a reasonable default
            if index < 10 {
                return "\(index * 3) sec"
            } else if index < 30 {
                return "\(index) sec"
            } else {
                return "[\(index) duration]"
            }
        }
    }

    // Lookup duration for other spells using database access
    private func lookupSpellDuration(spellId: Int) -> String {
        // Try to get duration from database
        if let duration = Spell.lookupSpellDurationFromDB(spellId: spellId) {
            return duration
        }

        // Fallback to common spell duration mappings
        switch spellId {
        case 6788: return "15 sec"  // Weakened Soul
        case 1706: return "3 sec"  // Levitate
        case 27648: return "12 sec"  // Thunderfury slow effect
        default: return "[\(spellId) duration]"
        }
    }

    // Lookup effect values from other spells using database access
    private func lookupSpellEffectValue(spellId: Int, effectIndex: Int) -> String {
        // Try to get effect value from database
        if let value = Spell.lookupSpellEffectFromDB(spellId: spellId, effectIndex: effectIndex) {
            return value
        }

        // Fallback to common spell effect mappings
        switch spellId {
        case 17809:  // Flame Buffet (common enchant reference)
            switch effectIndex {
            case 1: return "40"  // Fire damage
            default: return "[\(spellId)s\(effectIndex)]"
            }
        case 27648:  // Thunderfury slow effect
            switch effectIndex {
            case 1: return "20"  // Slow percentage
            default: return "[\(spellId)s\(effectIndex)]"
            }
        default: return "[\(spellId)s\(effectIndex)]"
        }
    }

    // Static database lookup functions
    static func lookupSpellDurationFromDB(spellId: Int) -> String? {
        #if canImport(GRDB)
            guard let queue = DatabaseService.shared.dbQueue else { return nil }

            do {
                return try queue.read { db in
                    if let durationIndex = try Int.fetchOne(
                        db,
                        sql:
                            "SELECT durationIndex FROM spell_template_ultimate_nerd WHERE entry = ?",
                        arguments: [spellId])
                    {
                        // Create a temporary spell to use the duration mapping
                        let tempSpell = Spell(id: spellId, durationIndex: durationIndex)
                        return tempSpell.durationText()
                    }
                    return nil
                }
            } catch {
                print("Error looking up spell duration for \(spellId): \(error)")
                return nil
            }
        #else
            return nil
        #endif
    }

    static func lookupSpellEffectFromDB(spellId: Int, effectIndex: Int) -> String? {
        #if canImport(GRDB)
            guard let queue = DatabaseService.shared.dbQueue else { return nil }

            do {
                return try queue.read { db in
                    let column = "effectBasePoints\(effectIndex)"
                    if let basePoints = try Int.fetchOne(
                        db,
                        sql: "SELECT \(column) FROM spell_template_ultimate_nerd WHERE entry = ?",
                        arguments: [spellId])
                    {
                        let actualValue = basePoints + 1  // Base points are stored as value - 1
                        return "\(actualValue)"
                    }
                    return nil
                }
            } catch {
                print("Error looking up spell effect for \(spellId)s\(effectIndex): \(error)")
                return nil
            }
        #else
            return nil
        #endif
    }
}

extension Spell {
    enum CodingKeys: String, CodingKey {
        case id = "entry"  // Map id field to entry column
        case build, name1, description1, school, category, castingTimeIndex, dispel, mechanic
        case attributes, attributesEx, attributesEx2, attributesEx3, attributesEx4
        case stances, stancesNot, targets, targetCreatureType, requiresShapeShift
        case procFlags, procChance, procCharges, maxLevel, baseLevel, spellLevel
        case durationIndex, powerType, manaCost, manaCostPerLevel, manaPerSecond
        case manaPerSecondPerLevel, rangeIndex, speed, modalNextSpell, stackAmount
        case totem1, totem2, reagent1, reagent2, reagent3, reagent4, reagent5, reagent6
        case reagent7, reagent8, reagentCount1, reagentCount2, reagentCount3, reagentCount4
        case reagentCount5, reagentCount6, reagentCount7, reagentCount8, equippedItemClass
        case equippedItemSubClassMask, equippedItemInventoryTypeMask, effect1, effect2, effect3
        case effectDieSides1, effectDieSides2, effectDieSides3, effectBaseDice1, effectBaseDice2
        case effectBaseDice3, effectDicePerLevel1, effectDicePerLevel2, effectDicePerLevel3
        case effectRealPointsPerLevel1, effectRealPointsPerLevel2, effectRealPointsPerLevel3
        case effectBasePoints1, effectBasePoints2, effectBasePoints3, effectMechanic1
        case effectMechanic2, effectMechanic3, effectImplicitTargetA1, effectImplicitTargetA2
        case effectImplicitTargetA3, effectImplicitTargetB1, effectImplicitTargetB2
        case effectImplicitTargetB3, effectRadiusIndex1, effectRadiusIndex2, effectRadiusIndex3
        case effectApplyAuraName1, effectApplyAuraName2, effectApplyAuraName3, effectAmplitude1
        case effectAmplitude2, effectAmplitude3, effectMultipleValue1, effectMultipleValue2
        case effectMultipleValue3, effectChainTarget1, effectChainTarget2, effectChainTarget3
        case effectItemType1, effectItemType2, effectItemType3, effectMiscValue1, effectMiscValue2
        case effectMiscValue3, effectTriggerSpell1, effectTriggerSpell2, effectTriggerSpell3
        case effectPointsPerComboPoint1, effectPointsPerComboPoint2, effectPointsPerComboPoint3
        case spellVisual1, spellVisual2, spellIconId, activeIconId, spellPriority
        case name2, name3, name4, name5, name6, name7, name8, name9, name10, name11, name12
        case name13, name14, name15, name16, description2, description3, description4
        case description5, description6, description7, description8, description9, description10
        case description11, description12, description13, description14, description15
        case description16, recoveryTime, categoryRecoveryTime, interruptFlags, auraInterruptFlags
        case channelInterruptFlags, procTypeMask, procEx, dmgClass, preventionType, stanceBarOrder
        case dmgMultiplier1, dmgMultiplier2, dmgMultiplier3, minFactionId, minReputation
        case requiredFactionId, requiredFactionRep
    }
}

#if canImport(GRDB)
    extension Spell: FetchableRecord, PersistableRecord {}
#endif
