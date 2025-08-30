import SwiftUI
import GRDB
import os.log

struct ItemDetailViewEnhanced: View {
    let item: Item
    @State private var loadedSpells: [Int: Spell] = [:]
    @State private var isLoadingSpells = false
    @State private var spellLoadError: String? = nil
    @State private var isFavorite = false
    @State private var isFavoriteLoading = false
    
    // Environment objects for user data management
    @Environment(\.dismiss) private var dismiss
    @Environment(FavoritesManager.self) private var favoritesManager: FavoritesManager
    @Environment(RecentsManager.self) private var recentsManager: RecentsManager
    
    private let logger = Logger(subsystem: "com.wowca.app", category: "ItemDetailEnhanced")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
                .padding(.horizontal)
                .padding(.bottom, 8)

            TabView {
                overviewTab
                    .tabItem {
                        Label("Overview", systemImage: "person.text.rectangle")
                    }

                spellsTab
                    .tabItem {
                        Label("Spells", systemImage: "sparkles")
                    }

                detailsTab
                    .tabItem {
                        Label("Details", systemImage: "list.bullet.rectangle")
                    }

                developerTab
                    .tabItem {
                        Label("Dev Info", systemImage: "ladybug")
                    }
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                favoriteButton
            }
        }
        .onAppear {
            logger.info("👁️ ItemDetailViewEnhanced appeared for item [\(item.entry)] \(item.name)")
            
            // Add to recent items when viewed
            Task {
                await recentsManager.addToRecent(item: item)
                await loadFavoriteStatus()
            }
        }
        .task {
            ensureSpellsLoaded()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(qualityColor(for: item.quality))
                Spacer()
                if let ilvl = item.item_level, ilvl > 0 {
                    Text("iLvl \(ilvl)")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            HStack {
                Text(item.qualityName)
                    .font(.headline)
                    .foregroundStyle(qualityColor(for: item.quality))
                    .fontWeight(.semibold)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(item.itemTypeName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tabs
    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Core Combat Stats - Only show if item has stats
                if !item.formattedStats.isEmpty {
                    enhancedStatsSection
                    Divider()
                }
                
                // Weapon Information - Only for actual weapons with weapon stats
                if hasWeaponStats() {
                    enhancedWeaponSection
                    Divider()
                }
                
                // Defense & Survivability - Only if item has defensive properties
                if hasDefensiveStats() {
                    enhancedDefenseSection
                    Divider()
                }
                
                // Spell Effects & Bonuses - Only if item has magical properties
                if hasSpellProperties() {
                    enhancedSpellPropertiesSection
                    Divider()
                }
                
                // Container & Stack Properties - Only for containers/bags
                if hasContainerProperties() {
                    enhancedContainerSection
                    Divider()
                }
                
                // Special Properties - Only if item has special characteristics
                if hasSpecialProperties() {
                    enhancedSpecialPropertiesSection
                    Divider()
                }
                
                // Usage & Requirements - Only if item has requirements/restrictions
                if hasRequirements() {
                    enhancedRequirementsSection
                    Divider()
                }
                
                // Economic Information - Only if item has economic data
                if hasEconomicData() {
                    enhancedEconomicSection
                }
            }
            .padding()
        }
    }

    // MARK: - Enhanced Overview Sections
    
    @ViewBuilder
    private var enhancedStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Combat Statistics", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Categorize stats intelligently
            let (primaryStats, secondaryStats, resistanceStats, specialStats) = categorizeStats()
            
            if !primaryStats.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primary Attributes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    ForEach(primaryStats, id: \.self) { stat in
                        statLine(icon: "plus.circle.fill", color: .green, text: stat)
                    }
                }
                .padding(.leading)
            }
            
            if !secondaryStats.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Combat Ratings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    ForEach(secondaryStats, id: \.self) { stat in
                        statLine(icon: "target", color: .blue, text: stat)
                    }
                }
                .padding(.leading)
            }
            
            if !resistanceStats.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resistances")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    ForEach(resistanceStats, id: \.self) { stat in
                        statLine(icon: "shield.lefthalf.filled", color: .orange, text: stat)
                    }
                }
                .padding(.leading)
            }
            
            if !specialStats.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Special Properties")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    ForEach(specialStats, id: \.self) { stat in
                        statLine(icon: "sparkles", color: .purple, text: stat)
                    }
                }
                .padding(.leading)
            }
        }
    }
    
    @ViewBuilder
    private var enhancedWeaponSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Weapon Properties", systemImage: "sword.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Primary damage
                if let damageString = item.weaponDamageString {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Damage:")
                            .foregroundStyle(.secondary)
                        Text(damageString)
                            .fontWeight(.semibold)
                    }
                }
                
                // All damage types (including elemental)
                let allDamageTypes = getAllDamageTypes()
                ForEach(allDamageTypes, id: \.self) { damageType in
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(damageType)
                            .fontWeight(.medium)
                    }
                }
                
                // Weapon speed and DPS
                if let speed = item.weaponSpeed {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Speed:")
                            .foregroundStyle(.secondary)
                        Text("\(speed) sec")
                            .fontWeight(.medium)
                    }
                }
                
                if let dps = item.dpsString {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("DPS:")
                            .foregroundStyle(.secondary)
                        Text(dps)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
                
                // Range and ammo
                if let rangeMod = item.range_mod, rangeMod > 0 {
                    HStack {
                        Image(systemName: "scope")
                            .foregroundStyle(.cyan)
                            .font(.caption)
                        Text("Range:")
                            .foregroundStyle(.secondary)
                        Text("\(String(format: "%.0f", rangeMod)) yards")
                            .fontWeight(.medium)
                    }
                }
                
                if let ammoType = item.ammo_type, ammoType > 0 {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Ammo Type:")
                            .foregroundStyle(.secondary)
                        Text(ammoTypeName(ammoType))
                            .fontWeight(.medium)
                    }
                }
                
                // Weapon skill bonus
                if hasWeaponSkillBonus() {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Weapon Skill Bonus")
                            .fontWeight(.medium)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var enhancedDefenseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Defense & Survivability", systemImage: "shield.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Armor
                if let armor = item.armor, armor > 0 {
                    HStack {
                        Image(systemName: "shield")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Text("Armor:")
                            .foregroundStyle(.secondary)
                        Text("\(armor)")
                            .fontWeight(.semibold)
                    }
                }
                
                // Block value
                if let block = item.block, block > 0 {
                    HStack {
                        Image(systemName: "shield.righthalf.filled")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Block Value:")
                            .foregroundStyle(.secondary)
                        Text("\(block)")
                            .fontWeight(.semibold)
                    }
                }
                
                // All resistances with proper categorization
                let resistances = getAllResistances()
                ForEach(resistances, id: \.self) { resistance in
                    HStack {
                        Image(systemName: "sparkles.rectangle.stack")
                            .foregroundStyle(resistanceColor(for: resistance))
                            .font(.caption)
                        Text(resistance)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var enhancedSpellPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Magical Properties", systemImage: "sparkles.rectangle.stack.fill")
                .font(.headline)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 8) {
                // Spell bonuses from computed properties
                ForEach(item.formattedSpellBonuses, id: \.self) { bonus in
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text(bonus)
                            .fontWeight(.medium)
                            .foregroundStyle(.purple)
                    }
                }
                
                // Spell effects summary
                if !item.allSpellEffects.isEmpty {
                    Text("✨ \(item.allSpellEffects.count) spell effect\(item.allSpellEffects.count == 1 ? "" : "s") (see Spells tab)")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .italic()
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var enhancedContainerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Container Properties", systemImage: "archivebox.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Container slots
                if let slots = item.container_slots, slots > 0 {
                    HStack {
                        Image(systemName: "grid.circle")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Container Slots:")
                            .foregroundStyle(.secondary)
                        Text("\(slots)")
                            .fontWeight(.semibold)
                    }
                }
                
                // Stack size
                if let stackString = item.stackSizeString {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(stackString)
                            .fontWeight(.medium)
                    }
                }
                
                // Max count
                if let maxCount = item.max_count, maxCount > 1 {
                    HStack {
                        Image(systemName: "number.square")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Max Count:")
                            .foregroundStyle(.secondary)
                        Text("\(maxCount)")
                            .fontWeight(.medium)
                    }
                }
                
                // Bag family
                if let bagFamily = item.bag_family, bagFamily > 0 {
                    HStack {
                        Image(systemName: "tag.circle")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Bag Type:")
                            .foregroundStyle(.secondary)
                        Text(bagFamilyName(bagFamily))
                            .fontWeight(.medium)
                    }
                }
                
                // Buy count (stacking for vendors)
                if let buyCount = item.buy_count, buyCount > 1 {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Vendor Stack:")
                            .foregroundStyle(.secondary)
                        Text("\(buyCount)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var enhancedRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Requirements & Restrictions", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Level requirements
                if let reqLevel = item.required_level, reqLevel > 0 {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Level \(reqLevel)")
                            .fontWeight(.semibold)
                    }
                }
                
                // Class restrictions
                if let allowableClass = item.allowable_class, allowableClass != -1 {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(classNames(for: allowableClass))
                            .fontWeight(.medium)
                    }
                }
                
                // Race restrictions
                if let allowableRace = item.allowable_race, allowableRace != -1 {
                    HStack {
                        Image(systemName: "globe.badge.chevron.backward")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(raceNames(for: allowableRace))
                            .fontWeight(.medium)
                    }
                }
                
                // Skill requirements
                if let skill = item.required_skill, skill > 0 {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Requires:")
                            .foregroundStyle(.secondary)
                        Text(skillName(skill))
                            .fontWeight(.medium)
                        if let skillRank = item.required_skill_rank, skillRank > 0 {
                            Text("(\(skillRank))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Spell requirement
                if let spell = item.required_spell, spell > 0 {
                    HStack {
                        Image(systemName: "sparkles.square.filled.on.square")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Requires Spell:")
                            .foregroundStyle(.secondary)
                        Text("ID \(spell)")
                            .fontWeight(.medium)
                    }
                }
                
                // Honor/PvP requirements
                if let honorRank = item.required_honor_rank, honorRank > 0 {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Honor Rank:")
                            .foregroundStyle(.secondary)
                        Text(honorRankName(honorRank))
                            .fontWeight(.medium)
                    }
                }
                
                // City rank
                if let cityRank = item.required_city_rank, cityRank > 0 {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(.cyan)
                            .font(.caption)
                        Text("City Rank:")
                            .foregroundStyle(.secondary)
                        Text("\(cityRank)")
                            .fontWeight(.medium)
                    }
                }
                
                // Reputation requirements
                if let repFaction = item.required_reputation_faction, repFaction > 0 {
                    HStack {
                        Image(systemName: "person.2.badge.gearshape")
                            .foregroundStyle(.indigo)
                            .font(.caption)
                        Text("Faction:")
                            .foregroundStyle(.secondary)
                        Text("ID \(repFaction)")
                            .fontWeight(.medium)
                        if let repRank = item.required_reputation_rank, repRank > 0 {
                            Text("(\(reputationRankName(repRank)))")
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var enhancedSpecialPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Special Properties", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if item.isTemporary {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Temporary Item")
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }
                }
                
                if let duration = item.duration, duration > 0 {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Duration:")
                            .foregroundStyle(.secondary)
                        Text(formatDuration(duration))
                            .fontWeight(.medium)
                    }
                }
                
                if hasProjectileStats() {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Projectile Type: Ammunition")
                            .fontWeight(.medium)
                    }
                }
                
                if let foodType = item.food_type, foodType > 0 {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Food Type:")
                            .foregroundStyle(.secondary)
                        Text(foodTypeName(foodType))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var enhancedEconomicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Economic Information", systemImage: "centsign.circle.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if let buyPrice = item.buy_price, buyPrice > 0 {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Buy Price:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(buyPrice))
                            .fontWeight(.medium)
                    }
                }
                
                if let sellPrice = item.sell_price, sellPrice > 0 {
                    HStack {
                        Image(systemName: "cart.badge.minus")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Sell Price:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(sellPrice))
                            .fontWeight(.medium)
                    }
                }
                
                if let buyCount = item.buy_count, buyCount > 1 {
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Buy Count:")
                            .foregroundStyle(.secondary)
                        Text("\(buyCount)")
                            .fontWeight(.medium)
                    }
                }
                
                if let stackable = item.stackable, stackable > 1 {
                    HStack {
                        Image(systemName: "square.stack")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Stack Size:")
                            .foregroundStyle(.secondary)
                        Text("\(stackable)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    private func formatPrice(_ price: Int) -> String {
        let gold = price / 10000
        let silver = (price % 10000) / 100
        let copper = price % 100
        
        var result = ""
        if gold > 0 {
            result += "\(gold)g"
        }
        if silver > 0 {
            if !result.isEmpty { result += " " }
            result += "\(silver)s"
        }
        if copper > 0 || result.isEmpty {
            if !result.isEmpty { result += " " }
            result += "\(copper)c"
        }
        return result
    }
    
    // MARK: - Enhanced Helper Functions
    
    private func categorizeStats() -> ([String], [String], [String], [String]) {
        var primaryStats: [String] = []
        var secondaryStats: [String] = []
        var resistanceStats: [String] = []
        var specialStats: [String] = []
        
        let allStats = [
            (item.stat_type1, item.stat_value1), (item.stat_type2, item.stat_value2),
            (item.stat_type3, item.stat_value3), (item.stat_type4, item.stat_value4),
            (item.stat_type5, item.stat_value5), (item.stat_type6, item.stat_value6),
            (item.stat_type7, item.stat_value7), (item.stat_type8, item.stat_value8),
            (item.stat_type9, item.stat_value9), (item.stat_type10, item.stat_value10)
        ]
        
        for (type, value) in allStats {
            guard let type = type, let value = value, value != 0 else { continue }
            
            let statText = "+\(value) \(statTypeName(type))"
            
            // Categorize intelligently
            switch type {
            case 1, 2, 3, 4, 5, 6, 7: // Health, Mana, Agility, Strength, Intellect, Spirit, Stamina
                primaryStats.append(statText)
            case 12...31: // Defense through Spell Penetration (combat ratings)
                secondaryStats.append(statText)
            case 32...43: // Attack Power through Mastery Rating
                secondaryStats.append(statText)
            case 45...50: // Resistances
                resistanceStats.append(statText)
            default:
                specialStats.append(statText)
            }
        }
        
        return (primaryStats, secondaryStats, resistanceStats, specialStats)
    }
    
    private func getAllDamageTypes() -> [String] {
        var damages: [String] = []
        let allDamages = [
            (item.dmg_min2, item.dmg_max2, item.dmg_type2),
            (item.dmg_min3, item.dmg_max3, item.dmg_type3),
            (item.dmg_min4, item.dmg_max4, item.dmg_type4),
            (item.dmg_min5, item.dmg_max5, item.dmg_type5)
        ]
        
        for (minDmg, maxDmg, type) in allDamages {
            if let minDmg = minDmg, let maxDmg = maxDmg, let type = type, (minDmg > 0 || maxDmg > 0) {
                let typeName = damageTypeName(for: type)
                damages.append("+\(Int(minDmg))-\(Int(maxDmg)) \(typeName)")
            }
        }
        return damages
    }
    
    private func getAllResistances() -> [String] {
        var resistances: [String] = []
        if let holy = item.holy_res, holy > 0 { resistances.append("+\(holy) Holy Resistance") }
        if let fire = item.fire_res, fire > 0 { resistances.append("+\(fire) Fire Resistance") }
        if let nature = item.nature_res, nature > 0 { resistances.append("+\(nature) Nature Resistance") }
        if let frost = item.frost_res, frost > 0 { resistances.append("+\(frost) Frost Resistance") }
        if let shadow = item.shadow_res, shadow > 0 { resistances.append("+\(shadow) Shadow Resistance") }
        if let arcane = item.arcane_res, arcane > 0 { resistances.append("+\(arcane) Arcane Resistance") }
        return resistances
    }
    
    private func hasDefensiveStats() -> Bool {
        return item.hasArmor || (item.block ?? 0) > 0 || !getAllResistances().isEmpty
    }
    
    private func hasSpellProperties() -> Bool {
        return !item.formattedSpellBonuses.isEmpty || !item.allSpellEffects.isEmpty
    }
    
    private func hasWeaponSkillBonus() -> Bool {
        // Check if any stats are weapon skill related
        let allStats = [
            item.stat_type1, item.stat_type2, item.stat_type3, item.stat_type4, item.stat_type5,
            item.stat_type6, item.stat_type7, item.stat_type8, item.stat_type9, item.stat_type10
        ]
        return allStats.contains(8) // Weapon Skill stat type
    }
    
    private func resistanceColor(for resistance: String) -> Color {
        if resistance.contains("Holy") { return .yellow }
        if resistance.contains("Fire") { return .red }
        if resistance.contains("Nature") { return .green }
        if resistance.contains("Frost") { return .cyan }
        if resistance.contains("Shadow") { return .purple }
        if resistance.contains("Arcane") { return .blue }
        return .orange
    }
    
    private func statTypeName(_ type: Int) -> String {
        let statMap: [Int: String] = [
            1: "Health", 2: "Mana", 3: "Agility", 4: "Strength", 5: "Intellect", 6: "Spirit", 7: "Stamina",
            8: "Weapon Skill", 12: "Defense Rating", 13: "Dodge Rating", 14: "Parry Rating", 15: "Block Rating",
            16: "Hit Rating (Melee)", 17: "Hit Rating (Ranged)", 18: "Hit Rating (Spell)",
            19: "Crit Rating (Melee)", 20: "Crit Rating (Ranged)", 21: "Crit Rating (Spell)",
            22: "Hit Avoidance", 23: "Crit Avoidance", 24: "Hit Taken (Melee)", 25: "Hit Taken (Ranged)",
            26: "Hit Taken (Spell)", 27: "Crit Taken (Melee)", 28: "Crit Taken (Ranged)", 29: "Crit Taken (Spell)",
            30: "Haste Rating", 31: "Spell Penetration", 32: "Attack Power", 33: "Ranged Attack Power",
            34: "Feral Attack Power", 35: "Spell Healing", 36: "Spell Damage", 37: "Mana Regeneration",
            38: "Armor Penetration", 39: "Spell Power", 40: "Health Regen", 41: "Spell Penetration",
            42: "Block Value", 43: "Mastery Rating", 44: "Armor", 45: "Fire Resistance",
            46: "Frost Resistance", 47: "Holy Resistance", 48: "Shadow Resistance", 49: "Nature Resistance", 
            50: "Arcane Resistance"
        ]
        return statMap[type] ?? "Unknown Stat \(type)"
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

    // MARK: - Reusable Sections from ItemDetailView
    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Stats", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.formattedStats, id: \.self) { stat in
                    statLine(icon: "plus.circle.fill", color: .green, text: stat)
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var weaponStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Weapon Stats", systemImage: "sword.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let damageString = item.weaponDamageString {
                    HStack {
                        Text("Damage:")
                            .foregroundStyle(.secondary)
                        Text(damageString)
                            .fontWeight(.medium)
                    }
                }

                if let speed = item.weaponSpeed {
                    HStack {
                        Text("Speed:")
                            .foregroundStyle(.secondary)
                        Text(speed)
                            .fontWeight(.medium)
                    }
                }

                if let dps = item.dpsString {
                    HStack {
                        Text("DPS:")
                            .foregroundStyle(.secondary)
                        Text(dps)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }

                if let rangeMod = item.range_mod, rangeMod > 0 {
                    HStack {
                        Text("Range:")
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f yards", rangeMod))
                            .fontWeight(.medium)
                    }
                }

                if let ammoType = item.ammo_type, ammoType > 0 {
                    HStack {
                        Text("Ammo:")
                            .foregroundStyle(.secondary)
                        Text(ammoTypeName(ammoType))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var armorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Defense", systemImage: "shield.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            if let armorString = item.armorString {
                HStack {
                    Image(systemName: "shield")
                        .foregroundStyle(.secondary)
                    Text(armorString)
                        .fontWeight(.medium)
                }
                .padding(.leading)
            }
        }
    }

    @ViewBuilder
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Requirements", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let reqLevel = item.required_level, reqLevel > 0 {
                    HStack {
                        Text("Requires Level:")
                            .foregroundStyle(.secondary)
                        Text("\(reqLevel)")
                            .fontWeight(.medium)
                    }
                }

                if let skill = item.required_skill, skill > 0 {
                    HStack {
                        Text("Requires Skill:")
                            .foregroundStyle(.secondary)
                        Text(skillName(skill))
                            .fontWeight(.medium)
                    }
                }

                if let skillRank = item.required_skill_rank, skillRank > 0 {
                    HStack {
                        Text("Skill Level:")
                            .foregroundStyle(.secondary)
                        Text("\(skillRank)")
                            .fontWeight(.medium)
                    }
                }

                if let spell = item.required_spell, spell > 0 {
                    HStack {
                        Text("Requires Spell:")
                            .foregroundStyle(.secondary)
                        Text("Spell ID \(spell)")
                            .fontWeight(.medium)
                    }
                }

                if let honorRank = item.required_honor_rank, honorRank > 0 {
                    HStack {
                        Text("Honor Rank:")
                            .foregroundStyle(.secondary)
                        Text(honorRankName(honorRank))
                            .fontWeight(.medium)
                    }
                }

                if let cityRank = item.required_city_rank, cityRank > 0 {
                    HStack {
                        Text("City Rank:")
                            .foregroundStyle(.secondary)
                        Text("\(cityRank)")
                            .fontWeight(.medium)
                    }
                }

                if let repFaction = item.required_reputation_faction, repFaction > 0 {
                    HStack {
                        Text("Reputation:")
                            .foregroundStyle(.secondary)
                        Text("Faction \(repFaction)")
                            .fontWeight(.medium)
                    }
                }

                if let repRank = item.required_reputation_rank, repRank > 0 {
                    HStack {
                        Text("Rep Level:")
                            .foregroundStyle(.secondary)
                        Text(reputationRankName(repRank))
                            .fontWeight(.medium)
                    }
                }

                if let allowableClass = item.allowable_class, allowableClass != -1 {
                    HStack {
                        Text("Classes:")
                            .foregroundStyle(.secondary)
                        Text(classNames(for: allowableClass))
                            .fontWeight(.medium)
                    }
                }

                if let allowableRace = item.allowable_race, allowableRace != -1 {
                    HStack {
                        Text("Races:")
                            .foregroundStyle(.secondary)
                        Text(raceNames(for: allowableRace))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var spellBonusesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spell Bonuses", systemImage: "sparkles.rectangle.stack.fill")
                .font(.headline)
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.formattedSpellBonuses, id: \.self) { bonus in
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text(bonus)
                            .fontWeight(.medium)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var specialPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Special Properties", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                if let binding = item.bindingDescription {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(binding)
                            .fontWeight(.medium)
                    }
                }

                if let duration = item.durationString {
                    HStack {
                        Image(systemName: "timer.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Duration: \(duration)")
                            .fontWeight(.medium)
                    }
                }

                if item.isSetItem {
                    HStack {
                        Image(systemName: "rectangle.3.group.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Part of an item set")
                            .fontWeight(.medium)
                    }
                }

                if item.startsQuest {
                    HStack {
                        Image(systemName: "scroll.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Starts a quest")
                            .fontWeight(.medium)
                    }
                }

                if item.isReadable {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Readable")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    private func hasSpecialProperties() -> Bool {
        return item.bindingDescription != nil || item.durationString != nil || 
               item.isSetItem || item.startsQuest || item.isReadable
    }

    private var spellsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingSpells {
                    ProgressView("Loading Spells...")
                } else if let spellLoadError = spellLoadError {
                    Text("Error loading spells: \(spellLoadError)")
                        .foregroundColor(.red)
                } else if hasSpellEffects() {
                    
                    // Spell Effects Overview
                    spellEffectsOverviewSection
                    Divider()
                    
                    // Detailed spell breakdown
                    ForEach(Array(item.allSpellEffects.enumerated()), id: \.offset) { idx, effect in
                        if let spell = loadedSpells[effect.spellId] {
                            comprehensiveSpellSection(spell: spell, effect: effect, index: idx + 1)
                            if idx < item.allSpellEffects.count - 1 {
                                Divider()
                            }
                        } else {
                            Text("Could not load spell data for spell ID: \(effect.spellId)")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    Text("This item has no spell effects.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var spellEffectsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Spell Effects Overview", systemImage: "sparkles.tv")
                .font(.headline)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("This item has \(item.allSpellEffects.count) spell effect\(item.allSpellEffects.count == 1 ? "" : "s"):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(Array(item.allSpellEffects.enumerated()), id: \.offset) { idx, effect in
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.purple)
                            .font(.caption2)
                        Text("Spell \(idx + 1):")
                            .fontWeight(.medium)
                        Text("ID \(effect.spellId)")
                            .fontWeight(.semibold)
                            .textSelection(.enabled)
                        Text("(\(effect.triggerDescription))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private func comprehensiveSpellSection(spell: Spell, effect: SpellEffect, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Spell Header
            HStack {
                Label("Spell \(index)", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
                Text("ID: \(spell.id)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            
            // Spell Name and Description
            VStack(alignment: .leading, spacing: 8) {
                if let name = spell.name1, !name.isEmpty {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Text(spell.parsedDescription())
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Item-Specific Properties (always shown since this is the item spell context)
            itemSpellPropertiesSection(effect: effect)
            
            // Core Spell Mechanics (only if spell has core mechanics)
            if hasSpellMechanics(spell: spell) {
                coreSpellMechanicsSection(spell: spell)
            }
            
            // Spell Effects Detail (only if spell has effects)
            if hasSpellEffectDetails(spell: spell) {
                spellEffectsDetailSection(spell: spell)
            }
            
            // Advanced Spell Properties (only if spell has advanced data)
            if hasAdvancedSpellData(spell: spell) {
                advancedSpellPropertiesSection(spell: spell)
            }
            
            // Technical Spell Data (only if spell has technical data)
            if hasSpellTechnicalData(spell: spell) {
                technicalSpellDataSection(spell: spell)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func itemSpellPropertiesSection(effect: SpellEffect) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Item Properties")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 6) {
                NerdStat(label: "Trigger", value: effect.triggerDescription)
                
                if let charges = effect.charges, charges > 0 {
                    NerdStat(label: "Charges", value: charges)
                }
                
                if let ppm = effect.ppmRate, ppm > 0 {
                    NerdStat(label: "PPM Rate", value: String(format: "%.1f", ppm))
                }
                
                if let cd = effect.cooldown, cd > 0 {
                    let seconds = cd / 1000
                    NerdStat(label: "Cooldown", value: "\(seconds) sec")
                }
                
                if let catCd = effect.categoryCooldown, catCd > 0 {
                    let seconds = catCd / 1000
                    NerdStat(label: "Category CD", value: "\(seconds) sec")
                }
                
                if let category = effect.category, category > 0 {
                    NerdStat(label: "Spell Category", value: category)
                }
            }
        }
    }
    
    @ViewBuilder
    private func coreSpellMechanicsSection(spell: Spell) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Core Mechanics")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 6) {
                if let school = spell.school {
                    NerdStat(label: "School", value: schoolName(school))
                }
                
                if let level = spell.spellLevel, level > 0 {
                    NerdStat(label: "Spell Level", value: level)
                }
                
                if let baseLevel = spell.baseLevel, baseLevel > 0 {
                    NerdStat(label: "Base Level", value: baseLevel)
                }
                
                if let maxLevel = spell.maxLevel, maxLevel > 0 {
                    NerdStat(label: "Max Level", value: maxLevel)
                }
                
                if let manaCost = spell.manaCost {
                    NerdStat(label: "Mana Cost", value: manaCost > 0 ? "\(manaCost)" : "Free")
                }
                
                if let manaCostPerLevel = spell.manaCostPerLevel, manaCostPerLevel > 0 {
                    NerdStat(label: "Mana/Level", value: manaCostPerLevel)
                }
                
                if let speed = spell.speed, speed > 0 {
                    NerdStat(label: "Cast Time", value: String(format: "%.1f sec", speed))
                }
                
                if let dmgClass = spell.dmgClass {
                    NerdStat(label: "Damage Type", value: damageClassName(dmgClass))
                }
            }
        }
    }
    
    @ViewBuilder
    private func spellEffectsDetailSection(spell: Spell) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spell Effects")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 12) {
                // Effect 1
                if let effect1 = spell.effect1, effect1 > 0 {
                    spellEffectDetail(spell: spell, effectId: effect1, basePoints: spell.effectBasePoints1, 
                                    dieSides: spell.effectDieSides1, baseDice: spell.effectBaseDice1,
                                    dicePerLevel: spell.effectDicePerLevel1, realPointsPerLevel: spell.effectRealPointsPerLevel1,
                                    mechanic: spell.effectMechanic1, triggerSpell: spell.effectTriggerSpell1,
                                    miscValue: spell.effectMiscValue1, index: 1)
                }
                
                // Effect 2
                if let effect2 = spell.effect2, effect2 > 0 {
                    spellEffectDetail(spell: spell, effectId: effect2, basePoints: spell.effectBasePoints2,
                                    dieSides: spell.effectDieSides2, baseDice: spell.effectBaseDice2,
                                    dicePerLevel: spell.effectDicePerLevel2, realPointsPerLevel: spell.effectRealPointsPerLevel2,
                                    mechanic: spell.effectMechanic2, triggerSpell: spell.effectTriggerSpell2,
                                    miscValue: spell.effectMiscValue2, index: 2)
                }
                
                // Effect 3
                if let effect3 = spell.effect3, effect3 > 0 {
                    spellEffectDetail(spell: spell, effectId: effect3, basePoints: spell.effectBasePoints3,
                                    dieSides: spell.effectDieSides3, baseDice: spell.effectBaseDice3,
                                    dicePerLevel: spell.effectDicePerLevel3, realPointsPerLevel: spell.effectRealPointsPerLevel3,
                                    mechanic: spell.effectMechanic3, triggerSpell: spell.effectTriggerSpell3,
                                    miscValue: spell.effectMiscValue3, index: 3)
                }
            }
        }
    }
    
    @ViewBuilder
    private func spellEffectDetail(spell: Spell, effectId: Int, basePoints: Int?, dieSides: Int?, baseDice: Double?, 
                                 dicePerLevel: Double?, realPointsPerLevel: Double?, mechanic: Int?, 
                                 triggerSpell: Int?, miscValue: Int?, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Effect \(index): \(effectName(effectId))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
            
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 4) {
                if let basePoints = basePoints {
                    let actualValue = basePoints + 1
                    NerdStat(label: "Base Value", value: actualValue)
                }
                
                if let dieSides = dieSides, dieSides > 0 {
                    NerdStat(label: "Die Sides", value: dieSides)
                }
                
                if let baseDice = baseDice, baseDice > 0 {
                    NerdStat(label: "Base Dice", value: baseDice)
                }
                
                if let dicePerLevel = dicePerLevel, dicePerLevel > 0 {
                    NerdStat(label: "Dice/Level", value: String(format: "%.2f", dicePerLevel))
                }
                
                if let realPointsPerLevel = realPointsPerLevel, realPointsPerLevel > 0 {
                    NerdStat(label: "Points/Level", value: String(format: "%.2f", realPointsPerLevel))
                }
                
                if let mechanic = mechanic, mechanic > 0 {
                    NerdStat(label: "Mechanic", value: mechanic)
                }
                
                if let triggerSpell = triggerSpell, triggerSpell > 0 {
                    NerdStat(label: "Triggers", value: "Spell \(triggerSpell)")
                }
                
                if let miscValue = miscValue, miscValue != 0 {
                    NerdStat(label: "Misc Value", value: miscValue)
                }
            }
            
            // Show damage range if available
            if let damageRange = spell.damageRange(effectIndex: index) {
                Text("Damage Range: \(damageRange)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
            }
        }
        .padding(.leading, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    @ViewBuilder
    private func advancedSpellPropertiesSection(spell: Spell) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Advanced Properties")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
            
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 6) {
                // Proc information
                if let procChance = spell.procChance, procChance > 0 {
                    if procChance == 101 {
                        NerdStat(label: "Proc Type", value: "On Hit")
                    } else {
                        NerdStat(label: "Proc Chance", value: "\(procChance)%")
                    }
                }
                
                if let procFlags = spell.procFlags, procFlags > 0 {
                    NerdStat(label: "Proc Flags", value: "0x\(String(procFlags, radix: 16))")
                }
                
                if let procCharges = spell.procCharges, procCharges > 0 {
                    NerdStat(label: "Proc Charges", value: procCharges)
                }
                
                // Attributes and flags
                if let attributes = spell.attributes, attributes > 0 {
                    NerdStat(label: "Attributes", value: "0x\(String(attributes, radix: 16))")
                }
                
                if let attributesEx = spell.attributesEx, attributesEx > 0 {
                    NerdStat(label: "AttributesEx", value: "0x\(String(attributesEx, radix: 16))")
                }
                
                // Stances and targeting
                if let stances = spell.stances, stances > 0 {
                    NerdStat(label: "Stances", value: "0x\(String(stances, radix: 16))")
                }
                
                if let targets = spell.targets, targets > 0 {
                    NerdStat(label: "Targets", value: "0x\(String(targets, radix: 16))")
                }
                
                // Duration and range
                if let durationIndex = spell.durationIndex, durationIndex > 0 {
                    NerdStat(label: "Duration Index", value: durationIndex)
                }
                
                if let rangeIndex = spell.rangeIndex, rangeIndex > 0 {
                    NerdStat(label: "Range Index", value: rangeIndex)
                }
            }
        }
    }
    
    @ViewBuilder
    private func technicalSpellDataSection(spell: Spell) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Technical Data")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.gray)
            
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 6) {
                if let build = spell.build, build > 0 {
                    NerdStat(label: "Build", value: build)
                }
                
                if let category = spell.category, category > 0 {
                    NerdStat(label: "Category", value: category)
                }
                
                if let dispel = spell.dispel, dispel > 0 {
                    NerdStat(label: "Dispel Type", value: dispel)
                }
                
                if let mechanic = spell.mechanic, mechanic > 0 {
                    NerdStat(label: "Mechanic", value: mechanic)
                }
                
                if let spellIconId = spell.spellIconId, spellIconId > 0 {
                    NerdStat(label: "Icon ID", value: spellIconId)
                }
                
                if let activeIconId = spell.activeIconId, activeIconId > 0 {
                    NerdStat(label: "Active Icon ID", value: activeIconId)
                }
            }
        }
    }

    private func hasSpellEffects() -> Bool {
        return item.allSpellEffects.isEmpty == false
    }

    private func ensureSpellsLoaded() {
        let effectIds = item.allSpellEffects.map { $0.spellId }
        if !item.spells.isEmpty && loadedSpells.isEmpty {
            loadedSpells = Dictionary(uniqueKeysWithValues: item.spells.map { ($0.id, $0) })
            return
        }
        guard !effectIds.isEmpty else { return }
        if effectIds.allSatisfy({ loadedSpells[$0] != nil }) { return }
        isLoadingSpells = true
        spellLoadError = nil
        Task { @MainActor in
            do {
                let ids = effectIds
                guard let queue = DatabaseService.shared.dbQueue else {
                    isLoadingSpells = false
                    return
                }
                let spells: [Spell] = try await queue.read { db in
                    try Spell.filter(ids.contains(Column("entry"))).fetchAll(db)
                }
                for s in spells {
                    loadedSpells[s.id] = s
                }
                isLoadingSpells = false
            } catch {
                spellLoadError = error.localizedDescription
                isLoadingSpells = false
            }
        }
    }

    private var detailsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Item Identity & Metadata
                itemIdentitySection
                Divider()
                
                // Content & Patch Information
                if hasContentInfo() {
                    contentInformationSection
                    Divider()
                }
                
                // Economic Information (pricing, vendor data)
                if hasPricingInfo() {
                    economicInformationSection
                    Divider()
                }
                
                // Durability & Material Properties
                if hasDurabilityInfo() {
                    durabilityAndMaterialSection
                    Divider()
                }
                
                // Binding & Ownership Properties
                if hasBindingProperties() {
                    bindingAndOwnershipSection
                    Divider()
                }
                
                // Quest & Lore Properties
                if hasQuestProperties() {
                    questAndLoreSection
                    Divider()
                }
                
                // Random Properties & Enhancement
                if hasRandomProperties() {
                    randomPropertiesSection
                    Divider()
                }
                
                // Location & Access Restrictions
                if hasLocationRestrictions() {
                    locationRestrictionsSection
                    Divider()
                }
                
                // Technical & Display Properties
                if hasDisplayProperties() {
                    technicalDisplaySection
                    Divider()
                }
                
                // Advanced Item Flags
                if hasItemFlags() {
                    advancedItemFlagsSection
                    Divider()
                }
                
                // Extra System Flags
                if hasExtraFlags() {
                    extraSystemFlagsSection
                }
            }
            .padding()
        }
    }

    // MARK: - Enhanced Detail Sections
    
    @ViewBuilder
    private var itemIdentitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Item Identity", systemImage: "person.text.rectangle")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Entry ID:")
                        .foregroundStyle(.secondary)
                    Text("\(item.entry)")
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                }
                
                if let displayId = item.display_id, displayId > 0 {
                    HStack {
                        Text("Display ID:")
                            .foregroundStyle(.secondary)
                        Text("\(displayId)")
                            .fontWeight(.medium)
                            .textSelection(.enabled)
                    }
                }
                
                if let itemLevel = item.item_level, itemLevel > 0 {
                    HStack {
                        Text("Item Level:")
                            .foregroundStyle(.secondary)
                        Text("\(itemLevel)")
                            .fontWeight(.semibold)
                    }
                }
                
                if let itemClass = item.class, let subclass = item.subclass {
                    HStack {
                        Text("Type:")
                            .foregroundStyle(.secondary)
                        Text("Class \(itemClass), Subclass \(subclass)")
                            .fontWeight(.medium)
                    }
                }
                
                if let inventoryType = item.inventory_type, inventoryType > 0 {
                    HStack {
                        Text("Equipment Slot:")
                            .foregroundStyle(.secondary)
                        Text(inventoryTypeName(inventoryType))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var contentInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Content Information", systemImage: "calendar.badge.clock")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let patch = item.patch, patch > 0 {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Added in Patch:")
                            .foregroundStyle(.secondary)
                        Text(patchName(patch))
                            .fontWeight(.semibold)
                    }
                }
                
                if let description = item.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description:")
                            .foregroundStyle(.secondary)
                        Text(description)
                            .fontWeight(.medium)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var economicInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Economic Information", systemImage: "dollarsign.circle")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let buyPrice = item.buy_price, buyPrice > 0 {
                    HStack {
                        Image(systemName: "cart")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Buy Price:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(buyPrice))
                            .fontWeight(.semibold)
                    }
                }
                
                if let sellPrice = item.sell_price, sellPrice > 0 {
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Sell Price:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(sellPrice))
                            .fontWeight(.semibold)
                    }
                }
                
                if let buyCount = item.buy_count, buyCount > 1 {
                    HStack {
                        Image(systemName: "number.square")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Vendor Stack Size:")
                            .foregroundStyle(.secondary)
                        Text("\(buyCount)")
                            .fontWeight(.medium)
                    }
                }
                
                // Money loot information
                if let minMoney = item.min_money_loot, minMoney > 0 {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Min Money Drop:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(minMoney))
                            .fontWeight(.medium)
                    }
                }
                
                if let maxMoney = item.max_money_loot, maxMoney > 0 {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Max Money Drop:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(maxMoney))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var durabilityAndMaterialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Durability & Materials", systemImage: "hammer.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let maxDurability = item.max_durability, maxDurability > 0 {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Max Durability:")
                            .foregroundStyle(.secondary)
                        Text("\(maxDurability)")
                            .fontWeight(.semibold)
                    }
                }
                
                if let material = item.material, material >= 0 {
                    HStack {
                        Image(systemName: "cube")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Material:")
                            .foregroundStyle(.secondary)
                        Text(materialName(material))
                            .fontWeight(.medium)
                    }
                }
                
                if let sheath = item.sheath, sheath > 0 {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Text("Sheath Type:")
                            .foregroundStyle(.secondary)
                        Text(sheathTypeName(sheath))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var bindingAndOwnershipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Binding & Ownership", systemImage: "link")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let binding = item.bonding, binding > 0 {
                    HStack {
                        Image(systemName: "link.circle")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Binding:")
                            .foregroundStyle(.secondary)
                        Text(bindingTypeName(binding))
                            .fontWeight(.semibold)
                    }
                }
                
                if let otherTeam = item.other_team_entry, otherTeam > 1 {
                    HStack {
                        Image(systemName: "person.2.circle")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Faction Variant:")
                            .foregroundStyle(.secondary)
                        Text("Item \(otherTeam)")
                            .fontWeight(.medium)
                    }
                }
                
                if let duration = item.duration, duration > 0 {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Duration:")
                            .foregroundStyle(.secondary)
                        Text(item.durationString ?? "\(duration) seconds")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var questAndLoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quest & Lore", systemImage: "scroll")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let questId = item.start_quest, questId > 0 {
                    HStack {
                        Image(systemName: "scroll.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Starts Quest:")
                            .foregroundStyle(.secondary)
                        Text("Quest ID \(questId)")
                            .fontWeight(.semibold)
                    }
                }
                
                if let pageText = item.page_text, pageText > 0 {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Readable Text:")
                            .foregroundStyle(.secondary)
                        Text("Text ID \(pageText)")
                            .fontWeight(.medium)
                    }
                }
                
                if let pageLang = item.page_language, pageLang > 0 {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Text Language:")
                            .foregroundStyle(.secondary)
                        Text(languageName(pageLang))
                            .fontWeight(.medium)
                    }
                }
                
                if let pageMat = item.page_material, pageMat > 0 {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Page Material:")
                            .foregroundStyle(.secondary)
                        Text(materialName(pageMat))
                            .fontWeight(.medium)
                    }
                }
                
                if let lockId = item.lock_id, lockId > 0 {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Text("Lock Picking:")
                            .foregroundStyle(.secondary)
                        Text("Lock ID \(lockId)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var randomPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Random Properties & Enhancement", systemImage: "dice")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let randomProp = item.random_property, randomProp != 0 {
                    HStack {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Random Properties:")
                            .foregroundStyle(.secondary)
                        Text("ID \(randomProp)")
                            .fontWeight(.semibold)
                    }
                }
                
                if let setId = item.set_id, setId > 0 {
                    HStack {
                        Image(systemName: "rectangle.3.group.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Item Set:")
                            .foregroundStyle(.secondary)
                        Text("Set ID \(setId)")
                            .fontWeight(.semibold)
                    }
                }
                
                if let disenchantId = item.disenchant_id, disenchantId > 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Disenchantable:")
                            .foregroundStyle(.secondary)
                        Text("Template ID \(disenchantId)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var technicalDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Technical & Display Properties", systemImage: "gear")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                if let displayId = item.display_id, displayId > 0 {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Display Model:")
                            .foregroundStyle(.secondary)
                        Text("ID \(displayId)")
                            .fontWeight(.medium)
                    }
                }
                
                if let inventoryType = item.inventory_type, inventoryType > 0 {
                    HStack {
                        Image(systemName: "square.grid.3x3")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Inventory Slot:")
                            .foregroundStyle(.secondary)
                        Text("\(inventoryType) (\(inventoryTypeName(inventoryType)))")
                            .fontWeight(.medium)
                    }
                }
                
                if let foodType = item.food_type, foodType > 0 {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Food Category:")
                            .foregroundStyle(.secondary)
                        Text(foodTypeName(foodType))
                            .fontWeight(.medium)
                    }
                }
                
                if let bagFamily = item.bag_family, bagFamily > 0 {
                    HStack {
                        Image(systemName: "bag")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Bag Family:")
                            .foregroundStyle(.secondary)
                        Text(bagFamilyName(bagFamily))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var advancedItemFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Item Flags", systemImage: "flag.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 6) {
                if let flags = item.flags, flags > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Flags Value:")
                                .foregroundStyle(.secondary)
                            Text("0x\(String(flags, radix: 16).uppercased())")
                                .fontWeight(.medium)
                                .textSelection(.enabled)
                        }
                        
                        ForEach(itemFlagsDescription(flags), id: \.self) { flagDesc in
                            HStack {
                                Image(systemName: "flag.circle")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(flagDesc)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                } else {
                    Text("No special flags set")
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(.leading)
        }
    }
    
    @ViewBuilder
    private var extraSystemFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Extra System Flags", systemImage: "gear.badge")
                .font(.headline)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 6) {
                if let extraFlags = item.extra_flags, extraFlags > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Extra Flags:")
                                .foregroundStyle(.secondary)
                            Text("0x\(String(extraFlags, radix: 16).uppercased())")
                                .fontWeight(.medium)
                                .textSelection(.enabled)
                        }
                        
                        Text("Advanced system behavior flags")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                } else {
                    Text("No extra system flags")
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding(.leading)
        }
    }
    
    // MARK: - Enhanced Detail Helper Functions
    
    private func hasContentInfo() -> Bool {
        return item.patch != nil || (item.description != nil && !item.description!.isEmpty)
    }
    
    private func hasPricingInfo() -> Bool {
        return item.buy_price != nil || item.sell_price != nil || item.min_money_loot != nil || item.max_money_loot != nil
    }
    
    private func hasRandomProperties() -> Bool {
        return (item.random_property ?? 0) != 0 || (item.set_id ?? 0) > 0 || (item.disenchant_id ?? 0) > 0
    }
    
    private func hasExtraFlags() -> Bool {
        return item.extra_flags != nil && item.extra_flags! > 0
    }
    
    private func patchName(_ patch: Int) -> String {
        let patches: [Int: String] = [
            0: "1.0.0 (Launch)",
            1: "1.1.0",
            2: "1.2.0", 
            3: "1.3.0",
            4: "1.4.0",
            5: "1.5.0",
            6: "1.6.0",
            7: "1.7.0",
            8: "1.8.0",
            9: "1.9.0",
            10: "1.10.0",
            11: "1.11.0",
            12: "1.12.0"
        ]
        return patches[patch] ?? "Patch \(patch)"
    }
    @ViewBuilder
    private var durabilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Durability", systemImage: "hammer.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let maxDurability = item.max_durability, maxDurability > 0 {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Max Durability:")
                            .foregroundStyle(.secondary)
                        Text("\(maxDurability)")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var itemPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Item Properties", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let stackString = item.stackSizeString {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Stack Size:")
                            .foregroundStyle(.secondary)
                        Text(stackString)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var bindingPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Binding & Location", systemImage: "link")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let binding = item.bonding, binding > 0 {
                    HStack {
                        Image(systemName: "link.circle")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Binding:")
                            .foregroundStyle(.secondary)
                        Text(bindingTypeName(binding))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var questPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Quest Properties", systemImage: "questionmark.diamond.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let questId = item.start_quest, questId > 0 {
                    HStack {
                        Image(systemName: "scroll")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Starts Quest:")
                            .foregroundStyle(.secondary)
                        Text("Quest ID \(questId)")
                            .fontWeight(.medium)
                    }
                }

                if let pageText = item.page_text, pageText > 0 {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Page Text:")
                            .foregroundStyle(.secondary)
                        Text("Text ID \(pageText)")
                            .fontWeight(.medium)
                    }
                }

                if let pageLang = item.page_language, pageLang > 0 {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Page Language:")
                            .foregroundStyle(.secondary)
                        Text(languageName(pageLang))
                            .fontWeight(.medium)
                    }
                }

                if let pageMat = item.page_material, pageMat > 0 {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Page Material:")
                            .foregroundStyle(.secondary)
                        Text(materialName(pageMat))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var lootPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loot Properties", systemImage: "gift.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let disenchantId = item.disenchant_id, disenchantId > 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.cyan)
                            .font(.caption)
                        Text("Disenchant ID:")
                            .foregroundStyle(.secondary)
                        Text("\(disenchantId)")
                            .fontWeight(.medium)
                    }
                }

                if let randomProp = item.random_property, randomProp != 0 {
                    HStack {
                        Image(systemName: "dice")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Random Properties:")
                            .foregroundStyle(.secondary)
                        Text("ID \(randomProp)")
                            .fontWeight(.medium)
                    }
                }

                if let minMoney = item.min_money_loot, minMoney > 0 {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Min Money:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(minMoney))
                            .fontWeight(.medium)
                    }
                }

                if let maxMoney = item.max_money_loot, maxMoney > 0 {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Max Money:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(maxMoney))
                            .fontWeight(.medium)
                    }
                }

                if let lockId = item.lock_id, lockId > 0 {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Text("Lock ID:")
                            .foregroundStyle(.secondary)
                        Text("\(lockId)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pricing", systemImage: "centsign.circle.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let buyPrice = item.buy_price, buyPrice > 0 {
                    HStack {
                        Text("Buy Price:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(buyPrice))
                            .fontWeight(.medium)
                    }
                }

                if let sellPrice = item.sell_price, sellPrice > 0 {
                    HStack {
                        Text("Sell Price:")
                            .foregroundStyle(.secondary)
                        Text(formatPrice(sellPrice))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    private func hasDurabilityInfo() -> Bool {
        return item.max_durability != nil && item.max_durability! > 0
    }

    private func hasItemProperties() -> Bool {
        return item.hasStackSize || item.isTemporary || item.hasProjectileStats
            || (item.isConsumable && item.food_type != nil)
    }

    private func hasBindingProperties() -> Bool {
        return item.bonding != nil || item.area_bound != nil || item.map_bound != nil
            || item.other_team_entry != nil
    }

    private func hasQuestProperties() -> Bool {
        return item.isQuestItem || item.start_quest != nil || item.page_text != nil
    }

    private func hasLootProperties() -> Bool {
        return item.min_money_loot != nil || item.max_money_loot != nil
            || item.random_property != nil || item.disenchant_id != nil
    }

    private var pricingVisible: Bool {
        return item.buy_price != nil || item.sell_price != nil
    }

    private func bindingTypeName(_ binding: Int) -> String {
        let types: [Int: String] = [
            0: "No Binding", 1: "Bind on Pickup", 2: "Bind on Equip",
            3: "Bind on Use", 4: "Quest Item",
        ]
        return types[binding] ?? "Unknown Binding \(binding)"
    }

    private func hasContainerProperties() -> Bool {
        return item.isContainer
            && ((item.container_slots != nil && item.container_slots! > 0)
                || (item.bag_family != nil && item.bag_family! > 0)
                || (item.max_count != nil && item.max_count! > 1))
    }

    private func hasConsumableProperties() -> Bool {
        return item.isConsumable && (item.food_type != nil || item.duration != nil)
    }

    private func hasDisplayProperties() -> Bool {
        return item.display_id != nil || item.material != nil || item.sheath != nil
            || item.inventory_type != nil
    }

    private func hasItemFlags() -> Bool {
        return item.flags != nil && item.flags! > 0
    }

    private func hasLocationRestrictions() -> Bool {
        return item.area_bound != nil || item.map_bound != nil || item.other_team_entry != nil
    }

    private func hasAdvancedProperties() -> Bool {
        return (item.disenchant_id ?? 0) > 0 || (item.random_property ?? 0) != 0
            || (item.set_id ?? 0) > 0 || (item.bag_family ?? 0) > 0 || (item.food_type ?? 0) > 0
            || (item.duration ?? 0) > 0 || (item.lock_id ?? 0) > 0
    }

    private func bagFamilyName(_ family: Int) -> String {
        let families: [Int: String] = [
            0: "Normal", 1: "Arrows", 2: "Bullets", 3: "Soul Shards",
            4: "Leatherworking Supplies", 5: "Inscription Supplies", 6: "Herbs",
            7: "Enchanting Supplies", 8: "Engineering Supplies", 9: "Keys",
            10: "Gems", 11: "Mining Supplies", 12: "Soulbound Equipment",
            13: "Vanity Pets", 14: "Currency", 15: "Quest Items",
        ]
        return families[family] ?? "Unknown Family \(family)"
    }

    private func foodTypeName(_ type: Int) -> String {
        let types: [Int: String] = [
            0: "Generic", 1: "Meat", 2: "Fish", 3: "Cheese", 4: "Bread",
            5: "Fungus", 6: "Fruit", 7: "Raw Meat", 8: "Raw Fish",
        ]
        return types[type] ?? "Unknown Food Type \(type)"
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minutes"
        } else {
            let hours = seconds / 3600
            let remainingMinutes = (seconds % 3600) / 60
            if remainingMinutes == 0 {
                return "\(hours) hours"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }

    private func languageName(_ language: Int) -> String {
        let languages: [Int: String] = [
            0: "Universal", 1: "Orcish", 2: "Darnassian", 3: "Taurahe",
            6: "Dwarvish", 7: "Common", 8: "Demonic", 9: "Titan",
            10: "Thalassian", 11: "Draconic", 12: "Kalimag", 13: "Gnomish",
            14: "Troll", 33: "Gutterspeak", 35: "Draenei", 36: "Zombie",
            37: "Gnomish Binary", 38: "Goblin Binary",
        ]
        return languages[language] ?? "Unknown Language \(language)"
    }

    private func materialName(_ material: Int) -> String {
        let materials: [Int: String] = [
            -1: "Consumables", 0: "Not Defined", 1: "Metal", 2: "Wood",
            3: "Liquid", 4: "Jewelry", 5: "Chain", 6: "Plate", 7: "Cloth",
            8: "Leather",
        ]
        return materials[material] ?? "Unknown Material \(material)"
    }

    private func sheathTypeName(_ sheath: Int) -> String {
        let types: [Int: String] = [
            0: "None", 1: "Main Hand", 2: "Off Hand", 3: "Ranged", 4: "Shield",
        ]
        return types[sheath] ?? "Unknown Sheath \(sheath)"
    }
    
    // MARK: - Advanced Conditional Logic
    
    private func hasSecondaryStats() -> Bool {
        let allStats = [
            (item.stat_type1, item.stat_value1), (item.stat_type2, item.stat_value2),
            (item.stat_type3, item.stat_value3), (item.stat_type4, item.stat_value4),
            (item.stat_type5, item.stat_value5), (item.stat_type6, item.stat_value6),
            (item.stat_type7, item.stat_value7), (item.stat_type8, item.stat_value8),
            (item.stat_type9, item.stat_value9), (item.stat_type10, item.stat_value10)
        ]
        return allStats.contains { type, value in
            guard let t = type, let v = value, v != 0 else { return false }
            // Secondary stats: crit, haste, hit, etc. (typically 14+)
            return t >= 14 && t <= 50
        }
    }
    
    private func hasPrimaryStats() -> Bool {
        let allStats = [
            (item.stat_type1, item.stat_value1), (item.stat_type2, item.stat_value2),
            (item.stat_type3, item.stat_value3), (item.stat_type4, item.stat_value4),
            (item.stat_type5, item.stat_value5), (item.stat_type6, item.stat_value6),
            (item.stat_type7, item.stat_value7), (item.stat_type8, item.stat_value8),
            (item.stat_type9, item.stat_value9), (item.stat_type10, item.stat_value10)
        ]
        return allStats.contains { type, value in
            guard let t = type, let v = value, v != 0 else { return false }
            // Primary stats: Strength, Agility, Stamina, Intellect, Spirit (1-7)
            return t >= 1 && t <= 7
        }
    }
    
    private func hasWeaponStats() -> Bool {
        return item.isWeapon && (
            (item.dmg_min1 != nil && item.dmg_min1! > 0) ||
            (item.delay != nil && item.delay! > 0) ||
            (item.range_mod != nil) ||
            (item.ammo_type != nil)
        )
    }
    
    private func hasMultipleDamageTypes() -> Bool {
        let damageTypes = [
            (item.dmg_min1, item.dmg_max1, item.dmg_type1),
            (item.dmg_min2, item.dmg_max2, item.dmg_type2),
            (item.dmg_min3, item.dmg_max3, item.dmg_type3),
            (item.dmg_min4, item.dmg_max4, item.dmg_type4),
            (item.dmg_min5, item.dmg_max5, item.dmg_type5)
        ]
        let validDamageTypes = damageTypes.filter { min, max, _ in
            guard let min = min, let max = max else { return false }
            return min > 0 || max > 0
        }
        return validDamageTypes.count > 1
    }
    
    private func hasRequirements() -> Bool {
        return (item.required_level ?? 0) > 1 ||
               (item.required_skill ?? 0) > 0 ||
               (item.required_skill_rank ?? 0) > 0 ||
               (item.required_spell ?? 0) > 0 ||
               (item.required_honor_rank ?? 0) > 0 ||
               (item.required_city_rank ?? 0) > 0 ||
               (item.required_reputation_faction ?? 0) > 0 ||
               (item.allowable_class != nil && item.allowable_class! != -1) ||
               (item.allowable_race != nil && item.allowable_race! != -1)
    }
    
    private func hasEconomicData() -> Bool {
        return (item.buy_price ?? 0) > 0 ||
               (item.sell_price ?? 0) > 0 ||
               (item.buy_count ?? 1) > 1 ||
               (item.stackable ?? 1) > 1
    }
    
    private func hasSpellMechanics(spell: Spell) -> Bool {
        return (spell.castingTimeIndex ?? 0) > 0 ||
               (spell.recoveryTime ?? 0) > 0 ||
               (spell.categoryRecoveryTime ?? 0) > 0 ||
               (spell.interruptFlags ?? 0) > 0 ||
               (spell.procChance ?? 0) > 0 ||
               (spell.manaCost ?? 0) > 0 ||
               (spell.dmgClass ?? 0) > 0
    }
    
    private func hasProjectileStats() -> Bool {
        return item.isProjectile && (item.ammo_type != nil)
    }
    
    private func hasSpellEffectDetails(spell: Spell) -> Bool {
        return (spell.effect1 ?? 0) > 0 ||
               (spell.effect2 ?? 0) > 0 ||
               (spell.effect3 ?? 0) > 0
    }
    
    private func hasAdvancedSpellData(spell: Spell) -> Bool {
        return (spell.attributes ?? 0) > 0 ||
               (spell.attributesEx ?? 0) > 0 ||
               (spell.stances ?? 0) > 0 ||
               (spell.targets ?? 0) > 0 ||
               (spell.procFlags ?? 0) > 0
    }
    
    private func hasSpellTechnicalData(spell: Spell) -> Bool {
        return (spell.spellIconId ?? 0) > 0 ||
               (spell.activeIconId ?? 0) > 0 ||
               (spell.spellVisual1 ?? 0) > 0 ||
               (spell.spellVisual2 ?? 0) > 0
    }
    
    private func getPrimaryStats() -> [(String, String)] {
        let allStats = [
            (item.stat_type1, item.stat_value1), (item.stat_type2, item.stat_value2),
            (item.stat_type3, item.stat_value3), (item.stat_type4, item.stat_value4),
            (item.stat_type5, item.stat_value5), (item.stat_type6, item.stat_value6),
            (item.stat_type7, item.stat_value7), (item.stat_type8, item.stat_value8),
            (item.stat_type9, item.stat_value9), (item.stat_type10, item.stat_value10)
        ]
        
        return allStats.compactMap { type, value in
            guard let t = type, let v = value, v != 0, t >= 1 && t <= 7 else { return nil }
            return (statTypeName(t), "+\(v)")
        }
    }
    
    private func getSecondaryStats() -> [(String, String)] {
        let allStats = [
            (item.stat_type1, item.stat_value1), (item.stat_type2, item.stat_value2),
            (item.stat_type3, item.stat_value3), (item.stat_type4, item.stat_value4),
            (item.stat_type5, item.stat_value5), (item.stat_type6, item.stat_value6),
            (item.stat_type7, item.stat_value7), (item.stat_type8, item.stat_value8),
            (item.stat_type9, item.stat_value9), (item.stat_type10, item.stat_value10)
        ]
        
        return allStats.compactMap { type, value in
            guard let t = type, let v = value, v != 0, t >= 14 && t <= 50 else { return nil }
            return (statTypeName(t), "+\(v)")
        }
    }

    private func inventoryTypeName(_ type: Int) -> String {
        let types: [Int: String] = [
            0: "Non-equipable", 1: "Head", 2: "Neck", 3: "Shoulder", 4: "Shirt",
            5: "Chest", 6: "Waist", 7: "Legs", 8: "Feet", 9: "Wrists",
            10: "Hands", 11: "Finger", 12: "Trinket", 13: "One-Hand", 14: "Shield",
            15: "Ranged", 16: "Back", 17: "Two-Hand", 18: "Bag", 19: "Tabard",
            20: "Robe", 21: "Main Hand", 22: "Off Hand", 23: "Holdable",
            24: "Ammo", 25: "Thrown", 26: "Ranged Right", 28: "Relic",
        ]
        return types[type] ?? "Unknown Slot \(type)"
    }

    @ViewBuilder
    private var containerPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Container Properties", systemImage: "archivebox.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let slots = item.container_slots, slots > 0 {
                    HStack {
                        Image(systemName: "grid.circle")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Container Slots:")
                            .foregroundStyle(.secondary)
                        Text("\(slots)")
                            .fontWeight(.semibold)
                    }
                }

                if let maxCount = item.max_count, maxCount > 1 {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Max Stack:")
                            .foregroundStyle(.secondary)
                        Text("\(maxCount)")
                            .fontWeight(.semibold)
                    }
                }

                if let bagFamily = item.bag_family, bagFamily > 0 {
                    HStack {
                        Image(systemName: "tag.circle")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Bag Type:")
                            .foregroundStyle(.secondary)
                        Text(bagFamilyName(bagFamily))
                            .fontWeight(.medium)
                    }
                }

                if let stackable = item.stackable, stackable > 1 {
                    HStack {
                        Image(systemName: "square.stack")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Stackable:")
                            .foregroundStyle(.secondary)
                        Text("\(stackable)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var consumablePropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Consumable Properties", systemImage: "hourglass.tophalf.filled")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let foodType = item.food_type, foodType > 0 {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Food Type:")
                            .foregroundStyle(.secondary)
                        Text(foodTypeName(foodType))
                            .fontWeight(.medium)
                    }
                }

                if let duration = item.duration, duration > 0 {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Duration:")
                            .foregroundStyle(.secondary)
                        Text(formatDuration(duration))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var displayPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Display Properties", systemImage: "eye.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let displayId = item.display_id, displayId > 0 {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Display ID:")
                            .foregroundStyle(.secondary)
                        Text("\(displayId)")
                            .fontWeight(.medium)
                    }
                }

                if let material = item.material, material > 0 {
                    HStack {
                        Image(systemName: "cube")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Material:")
                            .foregroundStyle(.secondary)
                        Text(materialName(material))
                            .fontWeight(.medium)
                    }
                }

                if let sheath = item.sheath, sheath > 0 {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Text("Sheath Type:")
                            .foregroundStyle(.secondary)
                        Text(sheathTypeName(sheath))
                            .fontWeight(.medium)
                    }
                }

                if let inventoryType = item.inventory_type, inventoryType > 0 {
                    HStack {
                        Image(systemName: "square.grid.3x3")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Slot Type:")
                            .foregroundStyle(.secondary)
                        Text(inventoryTypeName(inventoryType))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var itemFlagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Item Flags", systemImage: "flag.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                if let flags = item.flags, flags > 0 {
                    ForEach(itemFlagsDescription(flags), id: \.self) { flagDesc in
                        HStack {
                            Image(systemName: "flag.circle")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(flagDesc)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var locationRestrictionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Location Restrictions", systemImage: "map.fill")
                .font(.headline)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 4) {
                if let areaBound = item.area_bound, areaBound > 0 {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Area Bound: Zone \(areaBound)")
                            .fontWeight(.medium)
                    }
                }

                if let mapBound = item.map_bound, mapBound > 0 {
                    HStack {
                        Image(systemName: "map.circle")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Map Bound: Map \(mapBound)")
                            .fontWeight(.medium)
                    }
                }

                if let otherTeam = item.other_team_entry, otherTeam > 0 {
                    HStack {
                        Image(systemName: "person.2.circle")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Faction Variant: Item \(otherTeam)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var advancedPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Advanced Properties", systemImage: "gear")
                .font(.headline)
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 4) {
                if let disenchantId = item.disenchant_id, disenchantId > 0 {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Disenchantable (ID: \(disenchantId))")
                            .fontWeight(.medium)
                    }
                }

                if let randomProp = item.random_property, randomProp != 0 {
                    HStack {
                        Image(systemName: "dice")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Random Properties (ID: \(randomProp))")
                            .fontWeight(.medium)
                    }
                }

                if let setId = item.set_id, setId > 0 {
                    HStack {
                        Image(systemName: "rectangle.3.group")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Item Set (ID: \(setId))")
                            .fontWeight(.medium)
                    }
                }

                if let bagFamily = item.bag_family, bagFamily > 0 {
                    HStack {
                        Image(systemName: "bag")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Bag Family: \(bagFamilyName(bagFamily))")
                            .fontWeight(.medium)
                    }
                }

                if let foodType = item.food_type, foodType > 0 {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Food Type: \(foodTypeName(foodType))")
                            .fontWeight(.medium)
                    }
                }

                if let duration = item.duration, duration > 0 {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Duration: \(duration/60) minutes")
                            .fontWeight(.medium)
                    }
                }

                if let lockId = item.lock_id, lockId > 0 {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Text("Requires Lock Picking (ID: \(lockId))")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    private var developerTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                allDatabaseFieldsSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var allDatabaseFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Database Fields (Ultimate Nerd Mode)")
                .font(.headline)
                .foregroundStyle(Color.purple)
            
            VStack(alignment: .leading, spacing: 16) {
                basicInfoGrid
                purchasingGrid
                requirementsGrid
                restrictionsGrid
                statsGrid
                weaponStatsGrid
                damageGrid
                defenseGrid
                spellEffectsGrid
                miscInfoGrid
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Database Field Grids
    @ViewBuilder
    private var basicInfoGrid: some View {
        VStack(alignment: .leading) {
            Text("Basic Info").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Entry ID", value: item.entry)
                DatabaseField("Name", value: item.name)
                DatabaseField("Description", value: item.description)
                DatabaseField("Quality", value: item.quality)
                DatabaseField("Class", value: item.class)
                DatabaseField("Subclass", value: item.subclass)
                DatabaseField("Patch", value: item.patch)
                DatabaseField("Display ID", value: item.display_id)
                DatabaseField("Inventory Type", value: item.inventory_type)
                DatabaseField("Flags", value: item.flags)
            }
        }
    }

    @ViewBuilder
    private var purchasingGrid: some View {
        VStack(alignment: .leading) {
            Text("Purchasing").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Buy Count", value: item.buy_count)
                DatabaseField("Buy Price", value: item.buy_price)
                DatabaseField("Sell Price", value: item.sell_price)
            }
        }
    }

    @ViewBuilder
    private var requirementsGrid: some View {
        VStack(alignment: .leading) {
            Text("Requirements").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Item Level", value: item.item_level)
                DatabaseField("Required Level", value: item.required_level)
                DatabaseField("Required Skill", value: item.required_skill)
                DatabaseField("Required Skill Rank", value: item.required_skill_rank)
                DatabaseField("Required Spell", value: item.required_spell)
                DatabaseField("Required Honor Rank", value: item.required_honor_rank)
                DatabaseField("Required City Rank", value: item.required_city_rank)
                DatabaseField("Required Rep Faction", value: item.required_reputation_faction)
                DatabaseField("Required Rep Rank", value: item.required_reputation_rank)
            }
        }
    }

    @ViewBuilder
    private var restrictionsGrid: some View {
        VStack(alignment: .leading) {
            Text("Restrictions").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Allowable Class", value: item.allowable_class)
                DatabaseField("Allowable Race", value: item.allowable_race)
                DatabaseField("Max Count", value: item.max_count)
                DatabaseField("Stackable", value: item.stackable)
                DatabaseField("Container Slots", value: item.container_slots)
                DatabaseField("Bonding", value: item.bonding)
                DatabaseField("Material", value: item.material)
                DatabaseField("Sheath", value: item.sheath)
            }
        }
    }

    @ViewBuilder
    private var statsGrid: some View {
        VStack(alignment: .leading) {
            Text("Stats").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                statFields(type: item.stat_type1, value: item.stat_value1, index: 1)
                statFields(type: item.stat_type2, value: item.stat_value2, index: 2)
                statFields(type: item.stat_type3, value: item.stat_value3, index: 3)
                statFields(type: item.stat_type4, value: item.stat_value4, index: 4)
                statFields(type: item.stat_type5, value: item.stat_value5, index: 5)
                statFields(type: item.stat_type6, value: item.stat_value6, index: 6)
                statFields(type: item.stat_type7, value: item.stat_value7, index: 7)
                statFields(type: item.stat_type8, value: item.stat_value8, index: 8)
                statFields(type: item.stat_type9, value: item.stat_value9, index: 9)
                statFields(type: item.stat_type10, value: item.stat_value10, index: 10)
            }
        }
    }

    @ViewBuilder
    private var weaponStatsGrid: some View {
        VStack(alignment: .leading) {
            Text("Weapon").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Delay", value: item.delay)
                DatabaseField("Range Mod", value: item.range_mod)
                DatabaseField("Ammo Type", value: item.ammo_type)
            }
        }
    }

    @ViewBuilder
    private var damageGrid: some View {
        VStack(alignment: .leading) {
            Text("Damage").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                damageFields(min: item.dmg_min1, max: item.dmg_max1, type: item.dmg_type1, index: 1)
                damageFields(min: item.dmg_min2, max: item.dmg_max2, type: item.dmg_type2, index: 2)
                damageFields(min: item.dmg_min3, max: item.dmg_max3, type: item.dmg_type3, index: 3)
                damageFields(min: item.dmg_min4, max: item.dmg_max4, type: item.dmg_type4, index: 4)
                damageFields(min: item.dmg_min5, max: item.dmg_max5, type: item.dmg_type5, index: 5)
            }
        }
    }

    @ViewBuilder
    private var defenseGrid: some View {
        VStack(alignment: .leading) {
            Text("Defense & Resistances").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Block", value: item.block)
                DatabaseField("Armor", value: item.armor)
                DatabaseField("Holy Resistance", value: item.holy_res)
                DatabaseField("Fire Resistance", value: item.fire_res)
                DatabaseField("Nature Resistance", value: item.nature_res)
                DatabaseField("Frost Resistance", value: item.frost_res)
                DatabaseField("Shadow Resistance", value: item.shadow_res)
                DatabaseField("Arcane Resistance", value: item.arcane_res)
            }
        }
    }

    @ViewBuilder
    private var spellEffectsGrid: some View {
        VStack(alignment: .leading) {
            Text("Spell Effects").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                spellEffectFields(
                    id: item.spellid_1, trigger: item.spelltrigger_1, charges: item.spellcharges_1,
                    ppm: item.spellppmrate_1, cooldown: item.spellcooldown_1,
                    category: item.spellcategory_1, catCooldown: item.spellcategorycooldown_1,
                    index: 1)
                spellEffectFields(
                    id: item.spellid_2, trigger: item.spelltrigger_2, charges: item.spellcharges_2,
                    ppm: item.spellppmrate_2, cooldown: item.spellcooldown_2,
                    category: item.spellcategory_2, catCooldown: item.spellcategorycooldown_2,
                    index: 2)
                spellEffectFields(
                    id: item.spellid_3, trigger: item.spelltrigger_3, charges: item.spellcharges_3,
                    ppm: item.spellppmrate_3, cooldown: item.spellcooldown_3,
                    category: item.spellcategory_3, catCooldown: item.spellcategorycooldown_3,
                    index: 3)
                spellEffectFields(
                    id: item.spellid_4, trigger: item.spelltrigger_4, charges: item.spellcharges_4,
                    ppm: item.spellppmrate_4, cooldown: item.spellcooldown_4,
                    category: item.spellcategory_4, catCooldown: item.spellcategorycooldown_4,
                    index: 4)
                spellEffectFields(
                    id: item.spellid_5, trigger: item.spelltrigger_5, charges: item.spellcharges_5,
                    ppm: item.spellppmrate_5, cooldown: item.spellcooldown_5,
                    category: item.spellcategory_5, catCooldown: item.spellcategorycooldown_5,
                    index: 5)
            }
        }
    }

    @ViewBuilder
    private var miscInfoGrid: some View {
        VStack(alignment: .leading) {
            Text("Misc & Quest Info").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Page Text", value: item.page_text)
                DatabaseField("Page Language", value: item.page_language)
                DatabaseField("Page Material", value: item.page_material)
                DatabaseField("Start Quest", value: item.start_quest)
                DatabaseField("Lock ID", value: item.lock_id)
                DatabaseField("Random Property", value: item.random_property)
                DatabaseField("Set ID", value: item.set_id)
                DatabaseField("Max Durability", value: item.max_durability)
                DatabaseField("Area Bound", value: item.area_bound)
                DatabaseField("Map Bound", value: item.map_bound)
                DatabaseField("Duration", value: item.duration)
                DatabaseField("Bag Family", value: item.bag_family)
                DatabaseField("Disenchant ID", value: item.disenchant_id)
                DatabaseField("Food Type", value: item.food_type)
                DatabaseField("Min Money Loot", value: item.min_money_loot)
                DatabaseField("Max Money Loot", value: item.max_money_loot)
                DatabaseField("Extra Flags", value: item.extra_flags)
                DatabaseField("Other Team Entry", value: item.other_team_entry)
            }
        }
    }

    @ViewBuilder
    private func statFields(type: Int?, value: Int?, index: Int) -> some View {
        if let type = type, let value = value, type != 0 {
            DatabaseField("Stat Type \(index)", value: type)
            DatabaseField("Stat Value \(index)", value: value)
        }
    }

    @ViewBuilder
    private func damageFields(min: Double?, max: Double?, type: Int?, index: Int) -> some View {
        if let min = min, let max = max, let type = type, min > 0 || max > 0 {
            DatabaseField("Damage \(index) Min", value: min)
            DatabaseField("Damage \(index) Max", value: max)
            DatabaseField("Damage \(index) Type", value: type)
        }
    }

    @ViewBuilder
    private func spellEffectFields(
        id: Int?, trigger: Int?, charges: Int?, ppm: Double?, cooldown: Int?, category: Int?,
        catCooldown: Int?, index: Int
    ) -> some View {
        if let id = id, id > 0 {
            DatabaseField("Spell ID \(index)", value: id)
            DatabaseField("Spell Trigger \(index)", value: trigger)
            DatabaseField("Spell Charges \(index)", value: charges)
            DatabaseField("Spell PPM Rate \(index)", value: ppm)
            DatabaseField("Spell Cooldown \(index)", value: cooldown)
            DatabaseField("Spell Category \(index)", value: category)
            DatabaseField("Spell Cat Cooldown \(index)", value: catCooldown)
        }
    }

    private var twoColumnGrid: [GridItem] {
        [
            GridItem(.flexible(minimum: 120), alignment: .leading),
            GridItem(.flexible(minimum: 100), alignment: .leading),
        ]
    }

    @ViewBuilder
    private func DatabaseField<Value>(_ label: String, value: Value?) -> some View {
        if let value = value {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(describing: value))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 2)
        }
    }

    private func qualityColor(for quality: Int) -> Color {
        switch quality {
        case 0: return .gray
        case 1: return .primary
        case 2: return .green
        case 3: return .blue
        case 4: return .purple
        case 5: return .orange
        default: return .primary
        }
    }

    private func statLine(icon: String, color: Color, text: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(text).fontWeight(.medium)
        }
    }

    private func classNames(for classFlags: Int) -> String {
        if classFlags == -1 { return "All Classes" }

        let classMap: [Int: String] = [
            1: "Warrior", 2: "Paladin", 4: "Hunter", 8: "Rogue",
            16: "Priest", 32: "Death Knight", 64: "Shaman", 128: "Mage",
            256: "Warlock", 512: "Monk", 1024: "Druid", 2048: "Demon Hunter",
        ]

        var allowedClasses: [String] = []
        for (flag, name) in classMap {
            if classFlags & flag != 0 {
                allowedClasses.append(name)
            }
        }

        return allowedClasses.isEmpty
            ? "Class Restricted (\(classFlags))" : allowedClasses.joined(separator: ", ")
    }

    private func raceNames(for raceFlags: Int) -> String {
        if raceFlags == -1 { return "All Races" }

        let raceMap: [Int: String] = [
            1: "Human", 2: "Orc", 4: "Dwarf", 8: "Night Elf",
            16: "Undead", 32: "Tauren", 64: "Gnome", 128: "Troll",
            512: "Blood Elf", 1024: "Draenei",
        ]

        var allowedRaces: [String] = []
        for (flag, name) in raceMap {
            if raceFlags & flag != 0 {
                allowedRaces.append(name)
            }
        }

        return allowedRaces.isEmpty
            ? "Race Restricted (\(raceFlags))" : allowedRaces.joined(separator: ", ")
    }

    private func ammoTypeName(_ ammoType: Int) -> String {
        switch ammoType {
        case 1: return "Arrows"
        case 2: return "Bullets" 
        case 3: return "Thrown"
        default: return "Ammo Type \(ammoType)"
        }
    }

    private func itemFlagsDescription(_ flags: Int) -> [String] {
        var descriptions: [String] = []
        
        if flags & 0x1 != 0 { descriptions.append("Soulbound") }
        if flags & 0x2 != 0 { descriptions.append("Conjured") }
        if flags & 0x4 != 0 { descriptions.append("Lootable") }
        if flags & 0x8 != 0 { descriptions.append("Heroic") }
        if flags & 0x10 != 0 { descriptions.append("Deprecated") }
        if flags & 0x20 != 0 { descriptions.append("No Destroy") }
        if flags & 0x40 != 0 { descriptions.append("Player Cast") }
        if flags & 0x80 != 0 { descriptions.append("No Equip Cooldown") }
        if flags & 0x200 != 0 { descriptions.append("Wrapper") }
        if flags & 0x400 != 0 { descriptions.append("Party Loot") }
        if flags & 0x800 != 0 { descriptions.append("Refundable") }
        if flags & 0x1000 != 0 { descriptions.append("Charter") }
        if flags & 0x8000 != 0 { descriptions.append("Readable") }
        if flags & 0x10000 != 0 { descriptions.append("PvP Reward") }
        
        if descriptions.isEmpty {
            descriptions.append("Flag Value: \(flags)")
        }
        
        return descriptions
    }

    private func skillName(_ skillId: Int) -> String {
        let skills: [Int: String] = [
            129: "First Aid", 164: "Blacksmithing", 165: "Leatherworking", 171: "Alchemy",
            182: "Herbalism", 184: "Mining", 185: "Cooking", 186: "Fishing", 
            197: "Tailoring", 202: "Engineering", 333: "Enchanting", 755: "Jewelcrafting"
        ]
        return skills[skillId] ?? "Skill \(skillId)"
    }

    private func honorRankName(_ rank: Int) -> String {
        let ranks: [Int: String] = [
            1: "Private", 2: "Corporal", 3: "Sergeant", 4: "Master Sergeant",
            5: "Sergeant Major", 6: "Knight", 7: "Knight-Lieutenant", 8: "Knight-Captain",
            9: "Knight-Champion", 10: "Lieutenant Commander", 11: "Commander", 
            12: "Marshal", 13: "Field Marshal", 14: "Grand Marshal"
        ]
        return ranks[rank] ?? "Rank \(rank)"
    }

    private func reputationRankName(_ rank: Int) -> String {
        let ranks: [Int: String] = [
            0: "Hated", 1: "Hostile", 2: "Unfriendly", 3: "Neutral",
            4: "Friendly", 5: "Honored", 6: "Revered", 7: "Exalted"
        ]
        return ranks[rank] ?? "Standing \(rank)"
    }

    @ViewBuilder
    private var resistancesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Resistances", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.formattedResistances, id: \.self) { resistance in
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(resistance)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    @ViewBuilder
    private var secondaryDamageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Elemental Damage", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.secondaryDamageTypes, id: \.self) { damageType in
                    Text(damageType)
                        .font(.body)
                        .foregroundStyle(.red)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    @ViewBuilder
    private var blockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Block", systemImage: "shield.righthalf.filled")
                .font(.headline)
                .foregroundStyle(.primary)

            if let blockValue = item.block, blockValue > 0 {
                HStack {
                    Image(systemName: "shield.righthalf.filled")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("Block Value:")
                        .foregroundStyle(.secondary)
                    Text("\(blockValue)")
                        .fontWeight(.semibold)
                }
                .padding(.leading)
            }
        }
    }

    // MARK: - Spell Detail View Builder
    @ViewBuilder
    private func spellDetailSection(spell: Spell, effect: SpellEffect) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(spell.name1 ?? "Spell \(spell.id)")
                .font(.headline)
            
            // Show parsed spell description
            Text(spell.parsedDescription())
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Group {
                NerdStat(label: "Spell ID", value: String(spell.id))
                if let build = spell.build, build > 0 {
                    NerdStat(label: "Build", value: build)
                }
                if let school = spell.school {
                    NerdStat(label: "School", value: schoolName(school))
                }
                if let level = spell.spellLevel, level > 0 {
                    NerdStat(label: "Spell Level", value: level)
                }
                if let manaCost = spell.manaCost {
                    NerdStat(label: "Mana Cost", value: manaCost > 0 ? "\(manaCost) mana" : "Free")
                }

                // Item-specific data (PPM, charges, cooldowns)
                if let charges = effect.charges, charges > 0 {
                    NerdStat(label: "Charges", value: charges)
                }
                if let ppm = effect.ppmRate, ppm > 0 {
                    NerdStat(label: "PPM Rate", value: String(format: "%.1f", ppm))
                }
                if let cd = effect.cooldown, cd > 0 {
                    let seconds = cd / 1000
                    NerdStat(
                        label: "Cooldown",
                        value: seconds == 1 ? "1 sec" : "\(seconds) sec")
                }
                if let catCd = effect.categoryCooldown, catCd > 0 {
                    let seconds = catCd / 1000
                    NerdStat(
                        label: "Category Cooldown",
                        value: seconds == 1 ? "1 sec" : "\(seconds) sec")
                }

                // Show meaningful effect information
                if let effect1 = spell.effect1, effect1 > 0 {
                    NerdStat(label: "Effect 1", value: effectName(effect1))
                    if let basePoints = spell.effectBasePoints1 {
                        let actualValue = basePoints + 1
                        NerdStat(label: "Effect 1 Value", value: actualValue)
                    }
                    if let trigger = spell.effectTriggerSpell1, trigger > 0 {
                        NerdStat(label: "Triggers Spell", value: trigger)
                    }
                }
                if let effect2 = spell.effect2, effect2 > 0 {
                    NerdStat(label: "Effect 2", value: effectName(effect2))
                    if let basePoints = spell.effectBasePoints2 {
                        let actualValue = basePoints + 1
                        NerdStat(label: "Effect 2 Value", value: actualValue)
                    }
                }
                if let effect3 = spell.effect3, effect3 > 0 {
                    NerdStat(label: "Effect 3", value: effectName(effect3))
                    if let basePoints = spell.effectBasePoints3 {
                        let actualValue = basePoints + 1
                        NerdStat(label: "Effect 3 Value", value: actualValue)
                    }
                }

                // Show damage ranges for effects
                if let damageRange1 = spell.damageRange(effectIndex: 1) {
                    NerdStat(label: "Effect 1 Damage", value: damageRange1)
                }
                if let damageRange2 = spell.damageRange(effectIndex: 2) {
                    NerdStat(label: "Effect 2 Damage", value: damageRange2)
                }
                if let damageRange3 = spell.damageRange(effectIndex: 3) {
                    NerdStat(label: "Effect 3 Damage", value: damageRange3)
                }

                // Proc information with better formatting
                if let procChance = spell.procChance,
                    procChance > 0 && procChance != 101
                {
                    NerdStat(label: "Proc Chance", value: "\(procChance)%")
                } else if let procChance = spell.procChance, procChance == 101 {
                    // 101% is a database flag meaning "has proc effect" - real % is unknown for hit-based procs
                    NerdStat(label: "Proc Type", value: "On Hit")
                }
                if let procFlags = spell.procFlags, procFlags > 0 {
                    NerdStat(
                        label: "Proc Conditions",
                        value: procFlagsDescription(procFlags))
                }

                // Combat information
                if let dmgClass = spell.dmgClass {
                    NerdStat(label: "Damage Type", value: damageClassName(dmgClass))
                }
                if let speed = spell.speed, speed > 0 {
                    NerdStat(
                        label: "Cast/Travel Time",
                        value: String(format: "%.1f sec", speed))
                }

                // Duration and range information
                if let duration = spell.durationIndex, duration > 0 {
                    NerdStat(label: "Duration Index", value: duration)
                }
                if let range = spell.rangeIndex, range > 0 {
                    NerdStat(label: "Range Index", value: range)
                }
            }
            Text(
                "💡 PPM = Procs Per Minute (real-time rate), Hit-based = % chance per hit (requires community research)"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .italic()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func schoolName(_ school: Int) -> String {
        switch school {
        case 0: return "Physical"
        case 1: return "Holy"
        case 2: return "Fire"
        case 3: return "Nature"
        case 4: return "Frost"
        case 5: return "Shadow"
        case 6: return "Arcane"
        default: return "Unknown (\(school))"
        }
    }

    private func effectName(_ effect: Int) -> String {
        switch effect {
        case 1: return "Instant Kill"
        case 2: return "School Damage"
        case 3: return "Dummy"
        case 4: return "Portal Teleport"
        case 5: return "Teleport Units"
        case 6: return "Apply Aura"
        case 7: return "Environmental Damage"
        case 8: return "Power Drain"
        case 9: return "Health Leech"
        case 10: return "Direct Heal"
        case 11: return "Bind"
        case 12: return "Portal"
        case 13: return "Ritual Base"
        case 14: return "Ritual Specialize"
        case 15: return "Ritual Activate Portal"
        case 16: return "Quest Complete"
        case 17: return "Weapon Damage No School"
        case 18: return "Resurrect"
        case 19: return "Add Extra Attacks"
        case 20: return "Dodge"
        case 21: return "Evade"
        case 22: return "Parry"
        case 23: return "Block"
        case 24: return "Create Item"
        case 25: return "Weapon"
        case 26: return "Defense"
        case 27: return "Persistent Area Aura"
        case 28: return "Summon"
        case 29: return "Leap"
        case 30: return "Energize"
        case 31: return "Weapon Percent Damage"
        case 32: return "Trigger Missile"
        case 33: return "Open Lock"
        case 34: return "Transform Item"
        case 35: return "Apply Area Aura"
        case 36: return "Learn Spell"
        case 37: return "Spell Defense"
        case 38: return "Dispel"
        case 39: return "Language"
        case 40: return "Dual Wield"
        case 41: return "Summon Wild"
        case 42: return "Summon Guardian"
        case 43: return "Teleport Graveyard"
        case 44: return "Normalized Weapon Damage"
        case 45: return "120"
        case 46: return "Send Taxi"
        case 47: return "Player Pull"
        case 48: return "Modify Threat Percent"
        case 49: return "Steal Beneficial Buff"
        case 50: return "Prospecting"
        case 51: return "Apply Area Aura Friend"
        case 52: return "Apply Area Aura Enemy"
        default: return "Effect \(effect)"
        }
    }

    private func damageClassName(_ dmgClass: Int) -> String {
        switch dmgClass {
        case 0: return "None"
        case 1: return "Magic"
        case 2: return "Melee"
        case 3: return "Ranged"
        default: return "Class \(dmgClass)"
        }
    }

    private func procFlagsDescription(_ flags: Int) -> String {
        var descriptions: [String] = []

        if flags & 0x1 != 0 { descriptions.append("Heartbeat") }
        if flags & 0x2 != 0 { descriptions.append("Kill") }
        if flags & 0x4 != 0 { descriptions.append("Melee Hit") }
        if flags & 0x8 != 0 { descriptions.append("Crit Hit") }
        if flags & 0x10 != 0 { descriptions.append("Melee Miss") }
        if flags & 0x20 != 0 { descriptions.append("Melee Dodge") }
        if flags & 0x40 != 0 { descriptions.append("Melee Parry") }
        if flags & 0x80 != 0 { descriptions.append("Take Damage") }
        if flags & 0x100 != 0 { descriptions.append("Spell Hit") }
        if flags & 0x200 != 0 { descriptions.append("Spell Crit") }
        if flags & 0x400 != 0 { descriptions.append("Spell Miss") }
        if flags & 0x800 != 0 { descriptions.append("Spell Resist") }
        if flags & 0x1000 != 0 { descriptions.append("Ranged Hit") }
        if flags & 0x2000 != 0 { descriptions.append("Ranged Crit") }
        if flags & 0x4000 != 0 { descriptions.append("Ranged Miss") }

        if descriptions.isEmpty {
            return "0x" + String(flags, radix: 16)
        }

        return descriptions.joined(separator: ", ")
    }
    
    // MARK: - Favorites Functionality
    
    private var favoriteButton: some View {
        Button(action: {
            Task {
                await toggleFavorite()
            }
        }) {
            Group {
                if isFavoriteLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .secondary)
                        .font(.title3)
                }
            }
        }
        .disabled(isFavoriteLoading)
    }
    
    private func loadFavoriteStatus() async {
        isFavoriteLoading = true
        isFavorite = await favoritesManager.isFavorite(item: item)
        isFavoriteLoading = false
        
        logger.info("🔍 Loaded favorite status for item \(item.entry): \(isFavorite)")
        print("🔍 Favorite status: [\(item.entry)] \(item.name) = \(isFavorite)")
    }
    
    private func toggleFavorite() async {
        logger.info("⭐ Toggling favorite for item [\(item.entry)] \(item.name)")
        print("⭐ Toggling favorite: \(item.name)")
        
        isFavoriteLoading = true
        await favoritesManager.toggleFavorite(item: item)
        isFavorite = await favoritesManager.isFavorite(item: item)
        isFavoriteLoading = false
        
        logger.info("✅ Favorite toggled: [\(item.entry)] \(item.name) now \(isFavorite ? "favorited" : "unfavorited")")
        print("✅ Favorite status updated: [\(item.entry)] \(item.name) = \(isFavorite)")
    }
}

struct NerdStat<T: CustomStringConvertible>: View {
    let label: String
    let value: T?

    var body: some View {
        if let value = value {
            HStack {
                Text(label + ":")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.description)
                    .font(.caption.monospaced())
                    .fontWeight(.medium)
                    .textSelection(.enabled)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailViewEnhanced(
            item: Item(
                entry: 871,
                name: "Flurry Axe",
                description: "A flurry of attacks.",
                quality: 4,
                class: 2,
                subclass: 0,
                patch: 1,
                display_id: 123,
                inventory_type: 13,
                flags: 0,
                buy_count: 1,
                buy_price: 10000,
                sell_price: 2500,
                item_level: 47,
                required_level: 42,
                required_skill: nil,
                required_skill_rank: nil,
                required_spell: nil,
                required_honor_rank: nil,
                required_city_rank: nil,
                required_reputation_faction: nil,
                required_reputation_rank: nil,
                allowable_class: -1,
                allowable_race: -1,
                max_count: 1,
                stackable: 1,
                container_slots: 0,
                bonding: 2,
                material: 1,
                sheath: 1,
                stat_type1: 5, stat_value1: 10, // Stamina
                stat_type2: 4, stat_value2: 10, // Strength
                stat_type3: nil, stat_value3: nil,
                stat_type4: nil, stat_value4: nil,
                stat_type5: nil, stat_value5: nil,
                stat_type6: nil, stat_value6: nil,
                stat_type7: nil, stat_value7: nil,
                stat_type8: nil, stat_value8: nil,
                stat_type9: nil, stat_value9: nil,
                stat_type10: nil, stat_value10: nil,
                delay: 1500,
                range_mod: nil,
                ammo_type: nil,
                dmg_min1: 37, dmg_max1: 69, dmg_type1: 0,
                dmg_min2: nil, dmg_max2: nil, dmg_type2: nil,
                dmg_min3: nil, dmg_max3: nil, dmg_type3: nil,
                dmg_min4: nil, dmg_max4: nil, dmg_type4: nil,
                dmg_min5: nil, dmg_max5: nil, dmg_type5: nil,
                block: 0,
                armor: 120,
                holy_res: 0, fire_res: 10, nature_res: 0, frost_res: 0, shadow_res: 0, arcane_res: 0,
                spellid_1: 12345, spelltrigger_1: 1, spellcharges_1: 0, spellppmrate_1: 2.0,
                spellcooldown_1: -1, spellcategory_1: 0, spellcategorycooldown_1: -1,
                spellid_2: nil, spelltrigger_2: nil, spellcharges_2: nil, spellppmrate_2: nil,
                spellcooldown_2: nil, spellcategory_2: nil, spellcategorycooldown_2: nil,
                spellid_3: nil, spelltrigger_3: nil, spellcharges_3: nil, spellppmrate_3: nil,
                spellcooldown_3: nil, spellcategory_3: nil, spellcategorycooldown_3: nil,
                spellid_4: nil, spelltrigger_4: nil, spellcharges_4: nil, spellppmrate_4: nil,
                spellcooldown_4: nil, spellcategory_4: nil, spellcategorycooldown_4: nil,
                spellid_5: nil, spelltrigger_5: nil, spellcharges_5: nil, spellppmrate_5: nil,
                spellcooldown_5: nil, spellcategory_5: nil, spellcategorycooldown_5: nil,
                page_text: nil, page_language: nil, page_material: nil,
                start_quest: 123, lock_id: nil, random_property: nil, set_id: 45,
                max_durability: 100,
                area_bound: nil, map_bound: nil, duration: nil, bag_family: nil,
                disenchant_id: 1, food_type: nil, min_money_loot: nil, max_money_loot: nil,
                extra_flags: nil, other_team_entry: nil
            )
        )
    }
}
