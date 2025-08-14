// UI/ItemDetailViewEnhanced.swift
import SwiftUI

struct ItemDetailViewEnhanced: View {
    let item: Item

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Item Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(qualityColor(for: item.quality))

                        Spacer()

                        Text(item.qualityName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(qualityColor(for: item.quality).opacity(0.2))
                            .foregroundStyle(qualityColor(for: item.quality))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    HStack {
                        Text(item.itemTypeName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if let itemLevel = item.item_level {
                            Text("Item Level \(itemLevel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
        VStack(alignment: .leading, spacing: 8) {
            Label("Special Abilities", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                // All spell effects
                let spellEffects = item.allSpellEffects
                if !spellEffects.isEmpty {
                    ForEach(spellEffects, id: \.self) { effect in
                        Text(effect)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                if let bindingDesc = item.bindingDescription {
                    Text(bindingDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }

                if item.isSetItem {
                    Text("Part of a set (ID: \(item.set_id ?? 0))")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if item.startsQuest {
                    Text("This item begins a quest")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if item.isReadable {
                    Text("Right click to read")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
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
}

#Preview {
    NavigationStack {
        ItemDetailViewEnhanced(
            item: Item(
                entry: 871,
                name: "Flurry Axe",
                quality: 4,
                class: 2,
                subclass: 0,
                inventory_type: 13,
                item_level: 47,
                required_level: 42,
                stat_type1: nil,
                stat_value1: nil,
                stat_type2: nil,
                stat_value2: nil,
                stat_type3: nil,
                stat_value3: nil,
                stat_type4: nil,
                stat_value4: nil,
                delay: 1500,
                dmg_min1: 37,
                dmg_max1: 69,
                dmg_type1: 0,
                armor: nil,
                fire_res: nil,
                nature_res: nil,
                frost_res: nil,
                shadow_res: nil,
                allowable_class: -1,
                buy_price: 148139,
                sell_price: 29627
            ))
    }
}
