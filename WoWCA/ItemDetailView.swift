import GRDB
import SwiftUI
import os.log

// ItemDetailView: Organized item presentation with logical section ordering
//
// Section Order:
// 1. Header (name, quality, type)
// 2. Core Character Stats (strength, agility, intellect, etc.)
// 3. Combat & Damage Stats (weapon damage, armor, block)
// 4. Secondary Combat Stats (elemental damage, resistances)
// 5. Magical Effects & Abilities (spell effects, procs)
// 6. Physical Properties (durability)
// 7. Requirements & Restrictions
// 8. Special Item Properties (container, consumable, quest, loot, binding)
// 9. Economy & Trading (pricing)
// 10. Advanced Metadata & Developer Info
struct ItemDetailView: View {
    let item: Item
    @State private var spellBonuses: [String] = []
    @State private var isLoadingSpellBonuses = false
    @State private var loadedSpells: [Int: Spell] = [:]
    @State private var isLoadingSpells = false
    @State private var spellLoadError: String? = nil

    // Logger for detail view events
    private let logger = Logger(subsystem: "com.wowca.app", category: "ItemDetail")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                    .padding(.bottom, 4)
                    .onAppear {
                        logger.info("📰 Header section appeared for item [\(item.entry)]")
                        print("📰 Item header loaded: [\(item.entry)] \(item.name)")
                    }

                // MARK: - Core Character Stats
                // Primary stats like Strength, Agility, Intellect, Stamina, etc.
                // Show for ALL items that have stats (including consumables with buffs)
                if !item.formattedStats.isEmpty || !spellBonuses.isEmpty {
                    statsSection
                        .onAppear {
                            logger.info("📊 Stats section appeared")
                            print("📊 Showing stats section")
                        }
                    Divider()
                }

                // MARK: - Combat & Damage Stats
                // Weapon damage, armor, defensive stats
                if item.isWeapon {
                    weaponStatsSection
                        .onAppear {
                            logger.info("⚔️ Weapon stats section appeared")
                            print("⚔️ Showing weapon stats")
                        }
                    if hasWeaponExtendedInfo() {
                        weaponExtendedSection
                            .onAppear {
                                logger.info("⚔️ Extended weapon info appeared")
                                print("⚔️ Showing extended weapon info")
                            }
                    }
                    Divider()
                }
                if item.hasArmor {
                    armorSection
                        .onAppear {
                            logger.info("🛡️ Armor section appeared")
                            print("🛡️ Showing armor stats")
                        }
                    Divider()
                }
                if hasBlockInfo() {
                    blockSection
                        .onAppear {
                            logger.info("🛡️ Block info section appeared")
                            print("🛡️ Showing block stats")
                        }
                    Divider()
                }

                // MARK: - Secondary Combat Stats
                // Elemental damage types and resistances
                if !item.secondaryDamageTypes.isEmpty {
                    secondaryDamageSection
                    Divider()
                }
                if !item.formattedResistances.isEmpty {
                    resistancesSection
                    Divider()
                }

                // MARK: - Magical Effects & Abilities
                // Spell effects, procs, and special abilities (ALL item types can have these)
                if hasSpellEffects() {
                    spellEffectsSection
                    Divider()
                }
                if specialAbilitiesVisible {
                    specialAbilitiesSection
                    Divider()
                }

                // MARK: - Item Properties
                // Stackability, duration, food/ammo types, etc.
                if hasItemProperties() {
                    itemPropertiesSection
                    Divider()
                }

                // MARK: - Physical Properties
                // Durability and other physical characteristics
                if hasDurabilityInfo() {
                    durabilitySection
                    Divider()
                }  // MARK: - Requirements & Restrictions
                requirementsSection

                // MARK: - Special Item Properties
                // Container, consumable, quest, loot, and binding properties
                if hasContainerProperties() {
                    Divider()
                    containerPropertiesSection
                }
                if hasConsumableProperties() {
                    Divider()
                    consumablePropertiesSection
                }
                if hasQuestProperties() {
                    Divider()
                    questPropertiesSection
                }
                if hasLootProperties() {
                    Divider()
                    lootPropertiesSection
                }
                if hasBindingProperties() {
                    Divider()
                    bindingPropertiesSection
                }

                // MARK: - Economy & Trading
                if pricingVisible {
                    Divider()
                    pricingSection
                }

                // MARK: - Advanced Metadata
                // Display properties and advanced item metadata
                if hasAdvancedProperties() {
                    Divider()
                    advancedPropertiesSection
                }
                if hasDisplayProperties() {
                    Divider()
                    displayPropertiesSection
                }

                // MARK: - Developer & Debug Info
                // Technical information for debugging and analysis
                if nerdStatsVisible {
                    Divider()
                    ultimateNerdStatsSection
                }
                Divider()
                allDatabaseFieldsSection
                Divider()
                technicalInfoSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            logger.info("🚀 ItemDetailView task started - loading spell bonuses for [\(item.entry)]")
            print("🚀 Loading spell bonuses for item [\(item.entry)] \(item.name)")
            await loadSpellBonuses()
        }
        .onAppear {
            logger.info("👁️ ItemDetailView appeared for item [\(item.entry)] \(item.name)")
            print("👁️ ItemDetailView appeared: [\(item.entry)] \(item.name)")
            print("📋 Item details:")
            print("  🏷️ Name: \(item.name)")
            print("  🆔 Entry: \(item.entry)")
            print("  ⭐ Quality: \(item.quality)")
            print("  📊 Level: \(item.item_level ?? 0)")
            print("  💰 Buy: \(item.buy_price ?? 0) copper")
            print("  💰 Sell: \(item.sell_price ?? 0) copper")
            if item.isWeapon {
                print("  ⚔️ Weapon: \(item.dmg_min1 ?? 0)-\(item.dmg_max1 ?? 0) damage")
            }
            if item.hasArmor {
                print("  🛡️ Armor: \(item.armor ?? 0)")
            }
        }
        .onDisappear {
            logger.info("👋 ItemDetailView disappeared for item [\(item.entry)] \(item.name)")
            print("👋 ItemDetailView disappeared: [\(item.entry)] \(item.name)")
        }
    }

    private var specialAbilitiesVisible: Bool {
        item.hasSpellEffects || item.bindingDescription != nil || item.isSetItem || item.startsQuest
            || item.isReadable
    }
    private var nerdStatsVisible: Bool { item.hasSpellEffects || !loadedSpells.isEmpty }
    private var pricingVisible: Bool { item.buy_price != nil || item.sell_price != nil }

    private func hasDurabilityInfo() -> Bool {
        return item.max_durability != nil && item.max_durability! > 0
    }

    private func hasWeaponExtendedInfo() -> Bool {
        return item.range_mod != nil || item.ammo_type != nil
            || (item.delay != nil && item.delay! > 0)
    }

    private func hasBlockInfo() -> Bool {
        return item.block != nil && item.block! > 0
    }

    private func hasContainerProperties() -> Bool {
        // Only show container properties for actual containers
        return item.isContainer
            && ((item.container_slots != nil && item.container_slots! > 0)
                || (item.bag_family != nil && item.bag_family! > 0)
                || (item.max_count != nil && item.max_count! > 1))
    }

    private func hasConsumableProperties() -> Bool {
        // Only show consumable properties for actual consumables
        return item.isConsumable && (item.food_type != nil || item.duration != nil)
    }

    private func hasQuestProperties() -> Bool {
        // Show quest properties for quest items OR any item that starts a quest
        return item.isQuestItem || item.start_quest != nil || item.page_text != nil
    }

    private func hasLootProperties() -> Bool {
        return item.min_money_loot != nil || item.max_money_loot != nil
            || item.random_property != nil || item.disenchant_id != nil
    }

    private func hasBindingProperties() -> Bool {
        return item.bonding != nil || item.area_bound != nil || item.map_bound != nil
            || item.other_team_entry != nil
    }

    private func hasItemProperties() -> Bool {
        return item.hasStackSize || item.isTemporary || item.hasProjectileStats
            || (item.isConsumable && item.food_type != nil)
    }

    private func hasDisplayProperties() -> Bool {
        return item.display_id != nil || item.material != nil || item.sheath != nil
            || item.inventory_type != nil
    }

    // MARK: Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(qualityColor(for: item.quality))
                Spacer()
                if let ilvl = item.item_level, ilvl > 0 {
                    Text("iLvl \(ilvl)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            HStack {
                Text(item.qualityName)
                    .font(.subheadline)
                    .foregroundStyle(qualityColor(for: item.quality))
                    .fontWeight(.semibold)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(item.itemTypeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let req = item.required_level, req > 0 {
                    Text("• Req. Level \(req)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Spell bonus loading
    private func loadSpellBonuses() async {
        logger.info("🪄 loadSpellBonuses() called for item [\(item.entry)]")
        print("🪄 Starting spell bonus loading for [\(item.entry)] \(item.name)")

        guard spellBonuses.isEmpty && !isLoadingSpellBonuses else {
            logger.info("⚠️ Spell bonuses already loaded or loading in progress")
            print("⚠️ Spell bonuses already loaded or loading, skipping")
            return
        }

        isLoadingSpellBonuses = true
        logger.info("🔄 Set isLoadingSpellBonuses = true")
        print("🔄 Spell loading state: STARTED")

        defer {
            isLoadingSpellBonuses = false
            logger.info("🔄 Set isLoadingSpellBonuses = false")
            print("🔄 Spell loading state: FINISHED")
        }

        if !item.spells.isEmpty {  // already enriched
            logger.info("✅ Item already has \(item.spells.count) enriched spells")
            print("✅ Item already enriched with \(item.spells.count) spells")
            spellBonuses = item.formattedSpellBonuses
            logger.info("📋 Extracted \(spellBonuses.count) spell bonuses from enriched spells")
            print("📋 Extracted \(spellBonuses.count) spell bonuses")
            return
        }

        let ids = item.allSpellEffects.map { $0.spellId }
        logger.info("🔍 Found \(ids.count) spell effect IDs: \(ids)")
        print("🔍 Spell effect IDs to load: \(ids)")

        guard !ids.isEmpty, let queue = DatabaseService.shared.dbQueue else {
            logger.info("⚠️ No spell IDs to load or no database queue available")
            print("⚠️ No spell IDs or no database queue")
            return
        }

        do {
            logger.info("🗄️ Querying database for spells...")
            print("🗄️ Loading spells from database...")

            let spells: [Spell] = try await queue.read { db in
                let spells = try Spell.filter(ids.contains(Column("entry"))).fetchAll(db)
                print("🗄️ Database query returned \(spells.count) spells")
                return spells
            }

            logger.info("✅ Loaded \(spells.count) spells from database")
            print("✅ Loaded \(spells.count) spells")

            for spell in spells {
                print("  🔮 Spell [\(spell.id)]: \(spell.name1 ?? "Unknown")")
            }

            spellBonuses = spells.flatMap { $0.spellBonuses }
            logger.info("📋 Generated \(spellBonuses.count) total spell bonuses")
            print("📋 Generated \(spellBonuses.count) spell bonuses:")

            for (index, bonus) in spellBonuses.enumerated() {
                print("  \(index + 1). \(bonus)")
            }

        } catch {
            logger.error("❌ Spell bonus loading failed: \(error.localizedDescription)")
            print("❌ Spell bonus load failed: \(error)")
            print("❌ Error details: \(String(describing: error))")
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
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Stats", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.formattedStats, id: \.self) { stat in
                    statLine(icon: "plus.circle.fill", color: .green, text: stat)
                }
                ForEach(spellBonuses, id: \.self) { bonus in
                    statLine(icon: "star.circle.fill", color: .yellow, text: bonus)
                }
                if isLoadingSpellBonuses {
                    HStack {
                        ProgressView().scaleEffect(0.8)
                        Text("Loading spell bonuses...").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading)
        }
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

                // Show repair cost estimation if we have vendor price
                if let maxDur = item.max_durability, maxDur > 0,
                    let sellPrice = item.sell_price, sellPrice > 0
                {
                    let estimatedRepairCost = (sellPrice * maxDur) / 1000  // Rough estimate
                    HStack {
                        Image(systemName: "coppersign.circle")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Est. Repair Cost:")
                            .foregroundStyle(.secondary)
                        Text("\(estimatedRepairCost) copper")
                            .fontWeight(.medium)
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
                // Stack size for stackable items
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

                // Duration for temporary items
                if let durationString = item.durationString {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Duration:")
                            .foregroundStyle(.secondary)
                        Text(durationString)
                            .fontWeight(.medium)
                    }
                }

                // Food type for consumables
                if let foodType = item.food_type, foodType > 0 {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Food Type:")
                            .foregroundStyle(.secondary)
                        Text("\(foodType)")
                            .fontWeight(.medium)
                    }
                }

                // Ammo type for projectiles
                if let ammoType = item.ammo_type, ammoType > 0 {
                    HStack {
                        Image(systemName: "arrow.forward")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Ammo Type:")
                            .foregroundStyle(.secondary)
                        Text("\(ammoType)")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
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

                if let skill = item.required_skill, skill > 0, let rank = item.required_skill_rank,
                    rank > 0
                {
                    HStack {
                        Text("Requires Skill:")
                            .foregroundStyle(.secondary)
                        Text("\(skillName(skill)) (\(rank))")
                            .fontWeight(.medium)
                    }
                }

                if let faction = item.required_reputation_faction, faction > 0,
                    let rank = item.required_reputation_rank, rank > 0
                {
                    HStack {
                        Text("Requires Reputation:")
                            .foregroundStyle(.secondary)
                        Text("\(reputationRankName(rank)) with Faction \(faction)")
                            .fontWeight(.medium)
                    }
                }

                if let honorRank = item.required_honor_rank, honorRank > 0 {
                    HStack {
                        Text("Requires Honor Rank:")
                            .foregroundStyle(.secondary)
                        Text("\(honorRank)")
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
                } else if let allowableRace = item.allowable_race, allowableRace != -1 {
                    // Only show race restrictions if there are no class restrictions
                    // since class restrictions are more specific and make race restrictions redundant
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
    private var weaponExtendedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Weapon Details", systemImage: "scope")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                if let rangeModifier = item.range_mod, rangeModifier != 1.0 {
                    HStack {
                        Image(systemName: "target")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Range Modifier:")
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2fx", rangeModifier))
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

                if let delay = item.delay, delay > 0 {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Attack Delay:")
                            .foregroundStyle(.secondary)
                        Text("\(delay)ms")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
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
                        Image(systemName: "doc.text")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Page Text:")
                            .foregroundStyle(.secondary)
                        Text("Page ID \(pageText)")
                            .fontWeight(.medium)
                    }
                }

                if let pageLanguage = item.page_language, pageLanguage > 0 {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Page Language:")
                            .foregroundStyle(.secondary)
                        Text(languageName(pageLanguage))
                            .fontWeight(.medium)
                    }
                }

                if let pageMaterial = item.page_material, pageMaterial > 0 {
                    HStack {
                        Image(systemName: "paperplane")
                            .foregroundStyle(.brown)
                            .font(.caption)
                        Text("Page Material:")
                            .foregroundStyle(.secondary)
                        Text(materialName(pageMaterial))
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
                if let minMoney = item.min_money_loot, let maxMoney = item.max_money_loot {
                    HStack {
                        Image(systemName: "coppersign.circle")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text("Money Loot:")
                            .foregroundStyle(.secondary)
                        Text("\(minMoney) - \(maxMoney) copper")
                            .fontWeight(.medium)
                    }
                }

                if let randomProperty = item.random_property, randomProperty != 0 {
                    HStack {
                        Image(systemName: "dice")
                            .foregroundStyle(.purple)
                            .font(.caption)
                        Text("Random Property:")
                            .foregroundStyle(.secondary)
                        Text("ID \(randomProperty)")
                            .fontWeight(.medium)
                    }
                }

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

                if let areaBound = item.area_bound, areaBound > 0 {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Area Bound:")
                            .foregroundStyle(.secondary)
                        Text("Area ID \(areaBound)")
                            .fontWeight(.medium)
                    }
                }

                if let mapBound = item.map_bound, mapBound > 0 {
                    HStack {
                        Image(systemName: "map")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("Map Bound:")
                            .foregroundStyle(.secondary)
                        Text("Map ID \(mapBound)")
                            .fontWeight(.medium)
                    }
                }

                if let otherTeam = item.other_team_entry, otherTeam > 0 {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Other Team Entry:")
                            .foregroundStyle(.secondary)
                        Text("ID \(otherTeam)")
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

    @ViewBuilder
    private var technicalInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Technical Info", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Item ID:")
                        .foregroundStyle(.secondary)
                    Text("\(item.entry)")
                        .fontWeight(.medium)
                        .textSelection(.enabled)
                }

                if let itemClass = item.class, let subclass = item.subclass {
                    HStack {
                        Text("Class/Subclass:")
                            .foregroundStyle(.secondary)
                        Text("\(itemClass)/\(subclass)")
                            .fontWeight(.medium)
                    }
                }

                if let invType = item.inventory_type {
                    HStack {
                        Text("Slot:")
                            .foregroundStyle(.secondary)
                        Text("\(invType)")
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

    // Helper function to check if item has advanced properties
    private func hasAdvancedProperties() -> Bool {
        return (item.disenchant_id ?? 0) > 0 || (item.random_property ?? 0) != 0
            || (item.set_id ?? 0) > 0 || (item.bag_family ?? 0) > 0 || (item.food_type ?? 0) > 0
            || (item.duration ?? 0) > 0 || (item.lock_id ?? 0) > 0
    }

    // Fetch spells from DB if not already provided on the item
    private func ensureSpellsLoaded() {
        // If spells already populated externally, index and bail
        let effectIds = item.allSpellEffects.map { $0.spellId }
        if !item.spells.isEmpty && loadedSpells.isEmpty {
            loadedSpells = Dictionary(uniqueKeysWithValues: item.spells.map { ($0.id, $0) })
            return
        }
        guard !effectIds.isEmpty else { return }
        // If we already have them, skip
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
                print("📖 Loaded \(spells.count) spells for IDs: \(ids)")
                for s in spells {
                    loadedSpells[s.id] = s
                    print("📖 Spell \(s.id): \(s.name1 ?? "no name")")
                }
                isLoadingSpells = false
            } catch {
                print("❌ Spell loading error: \(error)")
                spellLoadError = error.localizedDescription
                isLoadingSpells = false
            }
        }
    }

    // MARK: - Spell Effects Section View
    @ViewBuilder
    private var spellEffectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spell Effects", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.blue)
            if isLoadingSpells {
                ProgressView().progressViewStyle(.circular)
                    .padding(.vertical, 4)
            } else if let error = spellLoadError {
                Text("Failed to load spells: \(error)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(item.allSpellEffects.enumerated()), id: \.offset) { idx, effect in
                    let spell = loadedSpells[effect.spellId]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("🔮 Spell \(idx + 1)")
                                .font(.subheadline).bold()
                            Text(
                                spell?.name1?.isEmpty == false
                                    ? (spell!.name1!) : "ID \(effect.spellId)"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            Text("[" + effect.triggerDescription + "]")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let spell = spell {
                            let parsedDesc = spell.parsedDescription()
                            if !parsedDesc.isEmpty && parsedDesc != "No description available" {
                                Text(parsedDesc)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .padding(6)
                                    .background(Color.orange.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }

                            // Show damage ranges for each effect
                            HStack(spacing: 8) {
                                ForEach(1...3, id: \.self) { effectIndex in
                                    if let damageRange = spell.damageRange(effectIndex: effectIndex)
                                    {
                                        Text("💥 \(damageRange) damage")
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.red.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }

                        // Additional spell details if we have the spell data
                        if let spell = spell {
                            HStack(spacing: 16) {
                                if let school = spell.school, school > 0 {
                                    Text("🎯 \(schoolName(school))")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                if let mana = spell.manaCost, mana > 0 {
                                    Text("🔮 \(mana) mana")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                if let level = spell.spellLevel, level > 0 {
                                    Text("📈 Level \(level)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }
                        // Supplemental nerd metrics from ITEM data
                        HStack(spacing: 12) {
                            if let charges = effect.charges, charges > 0 {
                                TagStat("Charges", "\(charges)")
                            }
                            if let ppm = effect.ppmRate, ppm > 0 {
                                TagStat("PPM", String(format: "%.1f", ppm))
                            }
                            if let cd = effect.cooldown, cd > 0 {
                                let seconds = cd / 1000
                                TagStat("Cooldown", seconds == 1 ? "1 sec" : "\(seconds) sec")
                            }
                            if let catCd = effect.categoryCooldown, catCd > 0 {
                                let seconds = catCd / 1000
                                TagStat("Cat Cooldown", seconds == 1 ? "1 sec" : "\(seconds) sec")
                            }
                            if let cat = effect.category, cat > 0 { TagStat("Category", "\(cat)") }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .task { ensureSpellsLoaded() }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onAppear { ensureSpellsLoaded() }
    }

    private func TagStat(_ label: String, _ value: String) -> some View {
        HStack(spacing: 2) {
            Text(label + ":")
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }

    private func statLine(icon: String, color: Color, text: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(text).fontWeight(.medium)
        }
    }

    // Helper functions

    @ViewBuilder
    private var specialAbilitiesSection: some View {
        if let bindingDesc = item.bindingDescription {
            Text(bindingDesc)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }

        // Note: Spell descriptions are now shown in the enhanced spellEffectsSection above
        // This section now only shows binding info and other non-spell special abilities

        if item.isSetItem {
            Text("Part of a set")
                .font(.caption)
                .foregroundStyle(.blue)
                .italic()
        }

        if item.startsQuest {
            Text("Starts a quest")
                .font(.caption)
                .foregroundStyle(.green)
                .italic()
        }

        if item.isReadable {
            Text("Right-click to read")
                .font(.caption)
                .foregroundStyle(.purple)
                .italic()
        }
    }

    @ViewBuilder
    private var ultimateNerdStatsSection: some View {
        DisclosureGroup("Ultimate Nerd Stats") {
            VStack(alignment: .leading, spacing: 12) {
                // Show all loaded spells from the item's spell effects
                ForEach(Array(item.allSpellEffects.enumerated()), id: \.offset) { idx, effect in
                    if let spell = loadedSpells[effect.spellId] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(spell.name1 ?? "Spell \(spell.id)")
                                .font(.headline)
                            Group {
                                NerdStat(label: "Spell ID", value: String(spell.id))
                                if let build = spell.build, build > 0 {
                                    NerdStat(label: "Build", value: build)
                                }
                                NerdStat(
                                    label: "School", value: spell.school.map { schoolName($0) })
                                if let level = spell.spellLevel, level > 0 {
                                    NerdStat(label: "Spell Level", value: level)
                                }
                                NerdStat(
                                    label: "Mana Cost",
                                    value: spell.manaCost.map { $0 > 0 ? "\($0) mana" : "Free" })

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
                    } else {
                        // Show placeholder if spell data hasn't loaded yet
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spell \(effect.spellId)")
                                .font(.headline)
                            Text("Loading spell data...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.top, 4)
        }
        .task { ensureSpellsLoaded() }
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

    private func formatPrice(_ price: Int) -> String {
        let gold = price / 10000
        let silver = (price % 10000) / 100
        let copper = price % 100

        var result = ""
        if gold > 0 {
            result += "\(gold)g"
        }
        if silver > 0 {
            result += (gold > 0 ? " " : "") + "\(silver)s"
        }
        if copper > 0 || result.isEmpty {
            result += (result.isEmpty ? "" : " ") + "\(copper)c"
        }

        return result
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

    // MARK: - Spell Interpretation Helpers

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

    // MARK: - Requirement Helper Methods

    private func skillName(_ skillId: Int) -> String {
        let skillNames: [Int: String] = [
            43: "Swords", 44: "Axes", 45: "Bows", 46: "Guns", 50: "Maces",
            55: "Two-Handed Swords", 56: "Staves", 95: "Defense", 118: "Dual Wield",
            129: "First Aid", 134: "Engineering", 136: "Enchanting", 137: "Affliction",
            138: "Demonology", 139: "Destruction", 140: "Fire", 141: "Frost",
            142: "Holy", 144: "Protection", 148: "Nature", 160: "Blacksmithing",
            164: "Leatherworking", 165: "Tailoring", 171: "Alchemy", 172: "Herbalism",
            173: "Mining", 176: "Survival", 182: "Herbalism", 186: "Mining",
            197: "Tailoring", 202: "Engineering", 226: "Crossbows", 227: "Wands",
            228: "Polearms", 236: "Block", 267: "Protection", 293: "Plate Mail",
            333: "Enchanting", 393: "Skinning", 413: "Mail", 414: "Leather",
            415: "Cloth", 433: "Shield", 473: "Axes", 533: "Maces", 554: "Two-Handed Maces",
            574: "Two-Handed Axes", 593: "Unarmed", 594: "Daggers", 633: "Lockpicking",
            713: "Kodo Riding", 762: "Riding", 777: "Fist Weapons",
        ]
        return skillNames[skillId] ?? "Unknown Skill \(skillId)"
    }

    private func reputationRankName(_ rank: Int) -> String {
        let rankNames: [Int: String] = [
            0: "Hated", 1: "Hostile", 2: "Unfriendly", 3: "Neutral",
            4: "Friendly", 5: "Honored", 6: "Revered", 7: "Exalted",
        ]
        return rankNames[rank] ?? "Unknown Rank \(rank)"
    }

    private func raceNames(for raceMask: Int) -> String {
        if raceMask == -1 { return "All Races" }

        let raceFlags: [Int: String] = [
            1: "Human", 2: "Orc", 4: "Dwarf", 8: "Night Elf",
            16: "Undead", 32: "Tauren", 64: "Gnome", 128: "Troll",
        ]

        var allowedRaces: [String] = []
        for (flag, name) in raceFlags {
            if raceMask & flag != 0 {
                allowedRaces.append(name)
            }
        }

        return allowedRaces.isEmpty ? "None" : allowedRaces.joined(separator: ", ")
    }

    // MARK: - Helper Functions for Name Mappings

    private func ammoTypeName(_ type: Int) -> String {
        let types: [Int: String] = [
            1: "None", 2: "Arrows", 3: "Bullets", 4: "Thrown",
        ]
        return types[type] ?? "Unknown Type \(type)"
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

    private func bindingTypeName(_ binding: Int) -> String {
        let types: [Int: String] = [
            0: "No Binding", 1: "Bind on Pickup", 2: "Bind on Equip",
            3: "Bind on Use", 4: "Quest Item",
        ]
        return types[binding] ?? "Unknown Binding \(binding)"
    }

    private func sheathTypeName(_ sheath: Int) -> String {
        let types: [Int: String] = [
            0: "None", 1: "Main Hand", 2: "Off Hand", 3: "Ranged", 4: "Shield",
        ]
        return types[sheath] ?? "Unknown Sheath \(sheath)"
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
    private var allDatabaseFieldsSection: some View {
        DisclosureGroup("All Database Fields (Ultimate Nerd Mode)") {
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
        .font(.headline)
        .foregroundStyle(Color.purple)
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

    // MARK: - Field Group Helpers

    @ViewBuilder
    private func statFields(type: Int?, value: Int?, index: Int) -> some View {
        if let type = type, let value = value, type != 0 {
            DatabaseField("Stat Type \(index)", value: type)
            DatabaseField("Stat Value \(index)", value: value)
        }
    }

    @ViewBuilder
    private func damageFields(min: Double?, max: Double?, type: Int?, index: Int) -> some View {
        // Accept Double? because underlying model uses Double for damage values
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

    // Helper function to check if item has any spell effects
    private func hasSpellEffects() -> Bool {
        if let spellID = item.spellid_1, spellID > 0 { return true }
        if let spellID = item.spellid_2, spellID > 0 { return true }
        if let spellID = item.spellid_3, spellID > 0 { return true }
        if let spellID = item.spellid_4, spellID > 0 { return true }
        if let spellID = item.spellid_5, spellID > 0 { return true }
        return false
    }

    // Helper view for displaying database fields
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
        ItemDetailView(
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
                stat_type1: nil, stat_value1: nil,
                stat_type2: nil, stat_value2: nil,
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
                armor: 0,
                holy_res: 0, fire_res: 0, nature_res: 0, frost_res: 0, shadow_res: 0, arcane_res: 0,
                spellid_1: 1, spelltrigger_1: 1, spellcharges_1: 1, spellppmrate_1: 1.0,
                spellcooldown_1: 1, spellcategory_1: 1, spellcategorycooldown_1: 1,
                spellid_2: nil, spelltrigger_2: nil, spellcharges_2: nil, spellppmrate_2: nil,
                spellcooldown_2: nil, spellcategory_2: nil, spellcategorycooldown_2: nil,
                spellid_3: nil, spelltrigger_3: nil, spellcharges_3: nil, spellppmrate_3: nil,
                spellcooldown_3: nil, spellcategory_3: nil, spellcategorycooldown_3: nil,
                spellid_4: nil, spelltrigger_4: nil, spellcharges_4: nil, spellppmrate_4: nil,
                spellcooldown_4: nil, spellcategory_4: nil, spellcategorycooldown_4: nil,
                spellid_5: nil, spelltrigger_5: nil, spellcharges_5: nil, spellppmrate_5: nil,
                spellcooldown_5: nil, spellcategory_5: nil, spellcategorycooldown_5: nil,
                page_text: nil, page_language: nil, page_material: nil,
                start_quest: nil, lock_id: nil, random_property: nil, set_id: nil,
                max_durability: 100,
                area_bound: nil, map_bound: nil, duration: nil, bag_family: nil,
                disenchant_id: nil, food_type: nil, min_money_loot: nil, max_money_loot: nil,
                extra_flags: nil, other_team_entry: nil
            )
        )
    }
}
