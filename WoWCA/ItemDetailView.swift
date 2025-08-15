// UI/ItemDetailView.swift
import SwiftUI

struct ItemDetailView: View {
    let item: Item

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

                // Spell Effects Section (Prominent Display)
                if hasSpellEffects() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✨ Spell Effects")
                            .font(.headline)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            if item.spellid_1 ?? 0 > 0 {
                                HStack {
                                    Text("🔮 Spell 1:")
                                        .font(.subheadline)
                                        .bold()
                                    Text("ID \(item.spellid_1!)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    if item.spelltrigger_1 ?? 0 > 0 {
                                        Text("(Trigger: \(item.spelltrigger_1!))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            if item.spellid_2 ?? 0 > 0 {
                                HStack {
                                    Text("🔮 Spell 2:")
                                        .font(.subheadline)
                                        .bold()
                                    Text("ID \(item.spellid_2!)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    if item.spelltrigger_2 ?? 0 > 0 {
                                        Text("(Trigger: \(item.spelltrigger_2!))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            if item.spellid_3 ?? 0 > 0 {
                                HStack {
                                    Text("🔮 Spell 3:")
                                        .font(.subheadline)
                                        .bold()
                                    Text("ID \(item.spellid_3!)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    if item.spelltrigger_3 ?? 0 > 0 {
                                        Text("(Trigger: \(item.spelltrigger_3!))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            if item.spellid_4 ?? 0 > 0 {
                                HStack {
                                    Text("🔮 Spell 4:")
                                        .font(.subheadline)
                                        .bold()
                                    Text("ID \(item.spellid_4!)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    if item.spelltrigger_4 ?? 0 > 0 {
                                        Text("(Trigger: \(item.spelltrigger_4!))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            if item.spellid_5 ?? 0 > 0 {
                                HStack {
                                    Text("🔮 Spell 5:")
                                        .font(.subheadline)
                                        .bold()
                                    Text("ID \(item.spellid_5!)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    if item.spelltrigger_5 ?? 0 > 0 {
                                        Text("(Trigger: \(item.spelltrigger_5!))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
                if !item.formattedStats.isEmpty {
                    statsSection
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
                if !item.spells.isEmpty {
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

    // Helper functions

    @ViewBuilder
    private var specialAbilitiesSection: some View {
        if let bindingDesc = item.bindingDescription {
            Text(bindingDesc)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }

        if !item.spells.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.spells, id: \.self) { spell in
                    if let description = spell.description1, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var ultimateNerdStatsSection: some View {
        DisclosureGroup("Ultimate Nerd Stats") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(item.spells) { spell in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(spell.name1 ?? "Spell \(spell.id)")
                            .font(.headline)
                        Group {
                            NerdStat(label: "Spell ID", value: String(spell.id))
                            NerdStat(label: "Build", value: spell.build)
                            NerdStat(label: "School", value: spell.school)
                            NerdStat(
                                label: "Proc Flags",
                                value: spell.procFlags.map { "0x" + String($0, radix: 16) })
                            NerdStat(label: "Proc Chance", value: spell.procChance.map { "\($0)%" })
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.top, 4)
        }
        .font(.headline)
        .foregroundStyle(Color.cyan)
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

    @ViewBuilder
    private var allDatabaseFieldsSection: some View {
        DisclosureGroup("All Database Fields (Ultimate Nerd Mode)") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(minimum: 120), alignment: .leading),
                    GridItem(.flexible(minimum: 100), alignment: .leading),
                ], alignment: .leading, spacing: 8
            ) {

                // Basic Info
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

                // Purchasing
                DatabaseField("Buy Count", value: item.buy_count)
                DatabaseField("Buy Price", value: item.buy_price)
                DatabaseField("Sell Price", value: item.sell_price)

                // Level & Requirements
                DatabaseField("Item Level", value: item.item_level)
                DatabaseField("Required Level", value: item.required_level)
                DatabaseField("Required Skill", value: item.required_skill)
                DatabaseField("Required Skill Rank", value: item.required_skill_rank)
                DatabaseField("Required Spell", value: item.required_spell)
                DatabaseField("Required Honor Rank", value: item.required_honor_rank)
                DatabaseField("Required City Rank", value: item.required_city_rank)
                DatabaseField("Required Rep Faction", value: item.required_reputation_faction)
                DatabaseField("Required Rep Rank", value: item.required_reputation_rank)

                // Restrictions
                DatabaseField("Allowable Class", value: item.allowable_class)
                DatabaseField("Allowable Race", value: item.allowable_race)
                DatabaseField("Max Count", value: item.max_count)
                DatabaseField("Stackable", value: item.stackable)
                DatabaseField("Container Slots", value: item.container_slots)
                DatabaseField("Bonding", value: item.bonding)
                DatabaseField("Material", value: item.material)
                DatabaseField("Sheath", value: item.sheath)

                // Stats 1-10
                if let stat1 = item.stat_type1, let val1 = item.stat_value1 {
                    DatabaseField("Stat Type 1", value: stat1)
                    DatabaseField("Stat Value 1", value: val1)
                }
                if let stat2 = item.stat_type2, let val2 = item.stat_value2 {
                    DatabaseField("Stat Type 2", value: stat2)
                    DatabaseField("Stat Value 2", value: val2)
                }
                if let stat3 = item.stat_type3, let val3 = item.stat_value3 {
                    DatabaseField("Stat Type 3", value: stat3)
                    DatabaseField("Stat Value 3", value: val3)
                }
                if let stat4 = item.stat_type4, let val4 = item.stat_value4 {
                    DatabaseField("Stat Type 4", value: stat4)
                    DatabaseField("Stat Value 4", value: val4)
                }
                if let stat5 = item.stat_type5, let val5 = item.stat_value5 {
                    DatabaseField("Stat Type 5", value: stat5)
                    DatabaseField("Stat Value 5", value: val5)
                }
                if let stat6 = item.stat_type6, let val6 = item.stat_value6 {
                    DatabaseField("Stat Type 6", value: stat6)
                    DatabaseField("Stat Value 6", value: val6)
                }
                if let stat7 = item.stat_type7, let val7 = item.stat_value7 {
                    DatabaseField("Stat Type 7", value: stat7)
                    DatabaseField("Stat Value 7", value: val7)
                }
                if let stat8 = item.stat_type8, let val8 = item.stat_value8 {
                    DatabaseField("Stat Type 8", value: stat8)
                    DatabaseField("Stat Value 8", value: val8)
                }
                if let stat9 = item.stat_type9, let val9 = item.stat_value9 {
                    DatabaseField("Stat Type 9", value: stat9)
                    DatabaseField("Stat Value 9", value: val9)
                }
                if let stat10 = item.stat_type10, let val10 = item.stat_value10 {
                    DatabaseField("Stat Type 10", value: stat10)
                    DatabaseField("Stat Value 10", value: val10)
                }

                // Weapon Stats
                DatabaseField("Delay", value: item.delay)
                DatabaseField("Range Mod", value: item.range_mod)
                DatabaseField("Ammo Type", value: item.ammo_type)

                // Damage 1-5
                if let dmgMin = item.dmg_min1, let dmgMax = item.dmg_max1 {
                    DatabaseField("Damage 1 Min", value: dmgMin)
                    DatabaseField("Damage 1 Max", value: dmgMax)
                    DatabaseField("Damage 1 Type", value: item.dmg_type1)
                }
                if let dmgMin = item.dmg_min2, let dmgMax = item.dmg_max2 {
                    DatabaseField("Damage 2 Min", value: dmgMin)
                    DatabaseField("Damage 2 Max", value: dmgMax)
                    DatabaseField("Damage 2 Type", value: item.dmg_type2)
                }
                if let dmgMin = item.dmg_min3, let dmgMax = item.dmg_max3 {
                    DatabaseField("Damage 3 Min", value: dmgMin)
                    DatabaseField("Damage 3 Max", value: dmgMax)
                    DatabaseField("Damage 3 Type", value: item.dmg_type3)
                }
                if let dmgMin = item.dmg_min4, let dmgMax = item.dmg_max4 {
                    DatabaseField("Damage 4 Min", value: dmgMin)
                    DatabaseField("Damage 4 Max", value: dmgMax)
                    DatabaseField("Damage 4 Type", value: item.dmg_type4)
                }
                if let dmgMin = item.dmg_min5, let dmgMax = item.dmg_max5 {
                    DatabaseField("Damage 5 Min", value: dmgMin)
                    DatabaseField("Damage 5 Max", value: dmgMax)
                    DatabaseField("Damage 5 Type", value: item.dmg_type5)
                }

                // Defense
                DatabaseField("Block", value: item.block)
                DatabaseField("Armor", value: item.armor)
                DatabaseField("Holy Resistance", value: item.holy_res)
                DatabaseField("Fire Resistance", value: item.fire_res)
                DatabaseField("Nature Resistance", value: item.nature_res)
                DatabaseField("Frost Resistance", value: item.frost_res)
                DatabaseField("Shadow Resistance", value: item.shadow_res)
                DatabaseField("Arcane Resistance", value: item.arcane_res)

                // 🎯 SPELL EFFECTS 1-5 (The missing important stuff!)
                DatabaseField("Spell ID 1", value: item.spellid_1)
                DatabaseField("Spell Trigger 1", value: item.spelltrigger_1)
                DatabaseField("Spell Charges 1", value: item.spellcharges_1)
                DatabaseField("Spell PPM Rate 1", value: item.spellppmrate_1)
                DatabaseField("Spell Cooldown 1", value: item.spellcooldown_1)
                DatabaseField("Spell Category 1", value: item.spellcategory_1)
                DatabaseField("Spell Cat Cooldown 1", value: item.spellcategorycooldown_1)

                DatabaseField("Spell ID 2", value: item.spellid_2)
                DatabaseField("Spell Trigger 2", value: item.spelltrigger_2)
                DatabaseField("Spell Charges 2", value: item.spellcharges_2)
                DatabaseField("Spell PPM Rate 2", value: item.spellppmrate_2)
                DatabaseField("Spell Cooldown 2", value: item.spellcooldown_2)
                DatabaseField("Spell Category 2", value: item.spellcategory_2)
                DatabaseField("Spell Cat Cooldown 2", value: item.spellcategorycooldown_2)

                DatabaseField("Spell ID 3", value: item.spellid_3)
                DatabaseField("Spell Trigger 3", value: item.spelltrigger_3)
                DatabaseField("Spell Charges 3", value: item.spellcharges_3)
                DatabaseField("Spell PPM Rate 3", value: item.spellppmrate_3)
                DatabaseField("Spell Cooldown 3", value: item.spellcooldown_3)
                DatabaseField("Spell Category 3", value: item.spellcategory_3)
                DatabaseField("Spell Cat Cooldown 3", value: item.spellcategorycooldown_3)

                DatabaseField("Spell ID 4", value: item.spellid_4)
                DatabaseField("Spell Trigger 4", value: item.spelltrigger_4)
                DatabaseField("Spell Charges 4", value: item.spellcharges_4)
                DatabaseField("Spell PPM Rate 4", value: item.spellppmrate_4)
                DatabaseField("Spell Cooldown 4", value: item.spellcooldown_4)
                DatabaseField("Spell Category 4", value: item.spellcategory_4)
                DatabaseField("Spell Cat Cooldown 4", value: item.spellcategorycooldown_4)

                DatabaseField("Spell ID 5", value: item.spellid_5)
                DatabaseField("Spell Trigger 5", value: item.spelltrigger_5)
                DatabaseField("Spell Charges 5", value: item.spellcharges_5)
                DatabaseField("Spell PPM Rate 5", value: item.spellppmrate_5)
                DatabaseField("Spell Cooldown 5", value: item.spellcooldown_5)
                DatabaseField("Spell Category 5", value: item.spellcategory_5)
                DatabaseField("Spell Cat Cooldown 5", value: item.spellcategorycooldown_5)

                // Misc/Quest/Set Info
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
            .padding(.top, 8)
        }
        .font(.headline)
        .foregroundStyle(Color.purple)
    }

    // Helper function to check if item has any spell effects
    private func hasSpellEffects() -> Bool {
        return (item.spellid_1 ?? 0) > 0 || (item.spellid_2 ?? 0) > 0 || (item.spellid_3 ?? 0) > 0
            || (item.spellid_4 ?? 0) > 0 || (item.spellid_5 ?? 0) > 0
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
