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

    nonisolated static var databaseTableName: String { "spell_template_ultimate_nerd" }
}

#if canImport(GRDB)
    extension Spell: FetchableRecord, PersistableRecord {}
#endif
