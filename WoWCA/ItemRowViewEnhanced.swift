// UI/ItemRowViewEnhanced.swift
import SwiftUI

struct ItemRowViewEnhanced: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Quality indicator
            Rectangle()
                .fill(qualityColor(for: item.quality))
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 4) {
                // Item name and level
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(qualityColor(for: item.quality))
                        .lineLimit(1)

                    Spacer()

                    if let itemLevel = item.item_level {
                        Text("iLvl \(itemLevel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                // Item type and required level
                HStack {
                    Text(item.itemTypeName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let reqLevel = item.required_level, reqLevel > 0 {
                        Text("• Req. \(reqLevel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Weapon stats (if weapon)
                if item.isWeapon {
                    weaponStatsRow
                }

                // Primary stats
                if !item.formattedStats.isEmpty {
                    statsRow
                }

                // Armor (if armor piece)
                if item.hasArmor {
                    armorRow
                }

                // Special abilities indicator
                if item.hasSpellEffects || item.isSetItem || item.startsQuest {
                    specialAbilitiesRow
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var weaponStatsRow: some View {
        HStack(spacing: 12) {
            if let damageString = item.weaponDamageString {
                Label(damageString, systemImage: "sword.fill")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            if let speed = item.weaponSpeed {
                Label(speed, systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let dps = item.dpsString {
                Label(dps, systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var statsRow: some View {
        HStack {
            ForEach(Array(item.formattedStats.prefix(3)), id: \.self) { stat in
                Text(stat)
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            if item.formattedStats.count > 3 {
                Text("+\(item.formattedStats.count - 3) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var armorRow: some View {
        if let armorString = item.armorString {
            HStack {
                Label(armorString, systemImage: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var specialAbilitiesRow: some View {
        HStack {
            Label("Special Ability", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.orange)
                .fontWeight(.medium)

            if item.isSetItem {
                Label("Set Item", systemImage: "square.stack.3d.up.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }

            if item.startsQuest {
                Label("Quest", systemImage: "questionmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }

            Spacer()
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
}

// MARK: - Preview
#Preview {
    List {
        ItemRowViewEnhanced(
            item: Item(
                entry: 871,
                name: "Flurry Axe",
                quality: 4,
                class: 2,
                subclass: 0,
                inventory_type: 13,
                item_level: 47,
                required_level: 42,
                stat_type1: 7, stat_value1: 15,
                stat_type2: 3, stat_value2: 10,
                delay: 1500,
                dmg_min1: 37, dmg_max1: 69, dmg_type1: 0,
                allowable_class: -1,
                buy_price: 148139, sell_price: 29627
            ))

        ItemRowViewEnhanced(
            item: Item(
                entry: 123,
                name: "Plate Chestpiece of the Eagle",
                quality: 2,
                class: 4,
                subclass: 4,
                inventory_type: 5,
                item_level: 25,
                required_level: 20,
                stat_type1: 7, stat_value1: 25,
                stat_type2: 5, stat_value2: 15,
                armor: 245,
                allowable_class: 1,
                buy_price: 5000, sell_price: 1000
            ))
    }
}
