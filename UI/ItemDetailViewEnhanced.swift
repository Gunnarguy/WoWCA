// Unified ItemDetailView (originally ItemDetailViewEnhanced) - UI target
import SwiftUI

struct ItemDetailView: View {
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

                // Resistances Section
                if !item.formattedResistances.isEmpty {
                    resistancesSection
                    Divider()
                }

                // Spell Effects Section (MEGA)
                // (No view implementation retained in this neutralized file.)
                    spellEffectsSection
