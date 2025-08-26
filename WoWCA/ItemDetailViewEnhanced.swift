import SwiftUI
import GRDB
import os.log

struct ItemDetailViewEnhanced: View {
    let item: Item
    @State private var loadedSpells: [Int: Spell] = [:]
    @State private var isLoadingSpells = false
    @State private var spellLoadError: String? = nil
    
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
        .onAppear {
            logger.info("👁️ ItemDetailViewEnhanced appeared for item [\(item.entry)] \(item.name)")
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
                if !item.formattedStats.isEmpty {
                    statsSection
                    Divider()
                }
                if !item.formattedResistances.isEmpty {
                    resistancesSection
                    Divider()
                }
                if item.isWeapon {
                    weaponStatsSection
                    Divider()
                }
                if !item.secondaryDamageTypes.isEmpty {
                    secondaryDamageSection
                    Divider()
                }
                if item.hasArmor {
                    armorSection
                    Divider()
                }
                if item.block ?? 0 > 0 {
                    blockSection
                    Divider()
                }
                requirementsSection
            }
            .padding()
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

                if let allowableClass = item.allowable_class, allowableClass != -1 {
                    HStack {
                        Text("Classes:")
                            .foregroundStyle(.secondary)
                        Text(classNames(for: allowableClass))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
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
                    ForEach(Array(item.allSpellEffects.enumerated()), id: \.offset) { idx, effect in
                        if let spell = loadedSpells[effect.spellId] {
                            spellDetailSection(spell: spell, effect: effect)
                        } else {
                            // This case indicates a logic error - if not loading and no error, spells should be loaded.
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
                if hasDurabilityInfo() {
                    durabilitySection
                    Divider()
                }
                if hasItemProperties() {
                    itemPropertiesSection
                    Divider()
                }
                if hasBindingProperties() {
                    bindingPropertiesSection
                    Divider()
                }
                if hasQuestProperties() {
                    questPropertiesSection
                    Divider()
                }
                if hasLootProperties() {
                    lootPropertiesSection
                    Divider()
                }
                if pricingVisible {
                    pricingSection
                }
            }
            .padding()
        }
    }

    // MARK: - Detail Sections
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
        return item.hasStackSize
    }

    private func hasBindingProperties() -> Bool {
        return item.bonding != nil
    }

    private func hasQuestProperties() -> Bool {
        return item.start_quest != nil
    }

    private func hasLootProperties() -> Bool {
        return item.disenchant_id != nil
    }

    private var pricingVisible: Bool {
        return item.buy_price != nil || item.sell_price != nil
    }

    private func formatPrice(_ price: Int) -> String {
        let gold = price / 10000
        let silver = (price % 10000) / 100
        let copper = price % 100

        var result = ""
        if gold > 0 { result += "\(gold)g" }
        if silver > 0 { result += (gold > 0 ? " " : "") + "\(silver)s" }
        if copper > 0 || result.isEmpty { result += (result.isEmpty ? "" : " ") + "\(copper)c" }
        return result
    }

    private func bindingTypeName(_ binding: Int) -> String {
        let types: [Int: String] = [
            0: "No Binding", 1: "Bind on Pickup", 2: "Bind on Equip",
            3: "Bind on Use", 4: "Quest Item",
        ]
        return types[binding] ?? "Unknown Binding \(binding)"
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
            }
        }
    }

    @ViewBuilder
    private var purchasingGrid: some View {
        VStack(alignment: .leading) {
            Text("Purchasing").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
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
                DatabaseField("Required Level", value: item.required_level)
            }
        }
    }

    @ViewBuilder
    private var restrictionsGrid: some View {
        VStack(alignment: .leading) {
            Text("Restrictions").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Allowable Class", value: item.allowable_class)
            }
        }
    }

    @ViewBuilder
    private var statsGrid: some View {
        VStack(alignment: .leading) {
            Text("Stats").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                statFields(type: item.stat_type1, value: item.stat_value1, index: 1)
            }
        }
    }

    @ViewBuilder
    private var weaponStatsGrid: some View {
        VStack(alignment: .leading) {
            Text("Weapon").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Delay", value: item.delay)
            }
        }
    }

    @ViewBuilder
    private var damageGrid: some View {
        VStack(alignment: .leading) {
            Text("Damage").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                damageFields(min: item.dmg_min1, max: item.dmg_max1, type: item.dmg_type1, index: 1)
            }
        }
    }

    @ViewBuilder
    private var defenseGrid: some View {
        VStack(alignment: .leading) {
            Text("Defense & Resistances").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Armor", value: item.armor)
            }
        }
    }

    @ViewBuilder
    private var spellEffectsGrid: some View {
        VStack(alignment: .leading) {
            Text("Spell Effects").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                spellEffectFields(id: item.spellid_1, trigger: item.spelltrigger_1, charges: item.spellcharges_1, ppm: item.spellppmrate_1, cooldown: item.spellcooldown_1, category: item.spellcategory_1, catCooldown: item.spellcategorycooldown_1, index: 1)
            }
        }
    }

    @ViewBuilder
    private var miscInfoGrid: some View {
        VStack(alignment: .leading) {
            Text("Misc & Quest Info").font(.subheadline).bold()
            LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 8) {
                DatabaseField("Start Quest", value: item.start_quest)
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
    private func spellEffectFields(id: Int?, trigger: Int?, charges: Int?, ppm: Double?, cooldown: Int?, category: Int?, catCooldown: Int?, index: Int) -> some View {
        if let id = id, id > 0 {
            DatabaseField("Spell ID \(index)", value: id)
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
