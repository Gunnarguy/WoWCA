import GRDB
// UI/ItemDetailView.swift
import SwiftUI

struct ItemDetailView: View {
    let item: Item
    @State private var spellBonuses: [String] = []
    @State private var isLoadingSpellBonuses = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Item name and level
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title)
                        .bold()

                    if item.required_level ?? 0 > 0 {
                        Text("Level \(item.required_level ?? 0)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Spell Effects Section (Prominent Display) – now shows names & descriptions for ALL attached spells
                if hasSpellEffects() {
                    spellEffectsSection
                }

                Divider()

                // Weapon Stats Section
                if item.isWeapon {
                    weaponStatsSection
                    Divider()
                }

                // Armor Section
                if item.hasArmor {
                    armorSection
                    Divider()
                }

                // Stats Section
                if !item.formattedStats.isEmpty || !spellBonuses.isEmpty {
                    statsSection
                    Divider()
                }

                // Spell Bonus Section
                if !spellBonuses.isEmpty {
                    spellBonusSection
                    Divider()
                }

                // Special Abilities Section
                if item.hasSpellEffects || item.bindingDescription != nil || item.isSetItem
                    || item.startsQuest || item.isReadable
                {
                    specialAbilitiesSection
                    Divider()
                }

                // ULTIMATE NERD MODE section
                if item.hasSpellEffects || !loadedSpells.isEmpty {
                    ultimateNerdStatsSection
                    Divider()
                }

                // Secondary Damage Types
                if !item.secondaryDamageTypes.isEmpty {
                    secondaryDamageSection
                    Divider()
                }

                // Resistances Section
                if !item.formattedResistances.isEmpty {
                    resistancesSection
                    Divider()
                }

                // Requirements Section
                requirementsSection

                // Pricing Section
                if item.buy_price != nil || item.sell_price != nil {
                    Divider()
                    pricingSection
                }

                // Advanced Properties Section
                if hasAdvancedProperties() {
                    Divider()
                    advancedPropertiesSection
                }

                // All Database Fields Section
                Divider()
                allDatabaseFieldsSection

                // Technical Info
                Divider()
                technicalInfoSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var spellBonusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spell Bonuses", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(spellBonuses, id: \.self) { bonus in
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(bonus)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.leading)
        }
    }

    private func loadSpellBonuses() async {
        guard !isLoadingSpellBonuses && spellBonuses.isEmpty else { return }

        isLoadingSpellBonuses = true
        let bonuses = await item.loadSpells()
        await MainActor.run {
            self.spellBonuses = bonuses
            self.isLoadingSpellBonuses = false
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
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(stat)
                            .fontWeight(.medium)
                    }
                }

                // Display spell bonuses in the same stats section
                ForEach(spellBonuses, id: \.self) { bonus in
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(bonus)
                            .fontWeight(.medium)
                    }
                }

                if isLoadingSpellBonuses {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                            .scaleEffect(0.8)
                        Text("Loading spell bonuses...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading)
        }
        .task {
            await loadSpellBonuses()
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

    // MARK: - Spell Loading State
    @State private var loadedSpells: [Int: Spell] = [:]
    @State private var isLoadingSpells = false
    @State private var spellLoadError: String? = nil

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
            Text("✨ Spell Effects")
                .font(.headline)
                .foregroundColor(.blue)
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
        .font(.headline)
        .foregroundStyle(Color.cyan)
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
        // This is a simplified implementation
        // In reality, you'd need to decode the bitmask
        if classFlags == -1 {
            return "All Classes"
        }
        return "Class Restricted (\(classFlags))"
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

    private func bagFamilyName(_ family: Int) -> String {
        switch family {
        case 1: return "Arrows"
        case 2: return "Bullets"
        case 3: return "Soul Shards"
        case 4: return "Leatherworking Supplies"
        case 5: return "Inscription Supplies"
        case 6: return "Herbs"
        case 7: return "Enchanting Supplies"
        case 8: return "Engineering Supplies"
        case 9: return "Keys"
        case 10: return "Gems"
        case 11: return "Mining Supplies"
        case 12: return "Soulbound Equipment"
        case 13: return "Vanity Pets"
        case 14: return "Currency"
        case 15: return "Quest Items"
        default: return "Family \(family)"
        }
    }

    private func foodTypeName(_ type: Int) -> String {
        switch type {
        case 1: return "Meat"
        case 2: return "Fish"
        case 3: return "Cheese"
        case 4: return "Bread"
        case 5: return "Fungus"
        case 6: return "Fruit"
        case 7: return "Raw Meat"
        case 8: return "Raw Fish"
        default: return "Type \(type)"
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
