// UI/ItemRowView.swift
import SwiftUI
import os.log

struct ItemRowView: View {
    let item: Item

    // Logger for row view events
    private let logger = Logger(subsystem: "com.wowca.app", category: "ItemRow")

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
        .onAppear {
            logger.info("👁️ ItemRowView appeared for item [\(item.entry)] \(item.name)")
            print("👁️ Row appeared: [\(item.entry)] \(item.name) (Quality: \(item.quality))")
        }
        .onTapGesture {
            logger.info("👆 ItemRowView tapped for item [\(item.entry)] \(item.name)")
            print("👆 Row tapped: [\(item.entry)] \(item.name)")
        }
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
        ItemRowView(
            item: Item(
                entry: 1,
                name: "Example Item",
                description: nil,
                quality: 3,
                class: 4,
                subclass: 0,
                patch: 1,
                display_id: 12345,
                inventory_type: 5,
                flags: 0,
                buy_count: 1,
                buy_price: 100,
                sell_price: 20,
                item_level: 30,
                required_level: 25,
                required_skill: nil,
                required_skill_rank: nil,
                required_spell: nil,
                required_honor_rank: nil,
                required_city_rank: nil,
                required_reputation_faction: nil,
                required_reputation_rank: nil,
                max_count: 1,
                stackable: 1,
                container_slots: 0,
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
                delay: nil, range_mod: nil, ammo_type: nil,
                dmg_min1: nil, dmg_max1: nil, dmg_type1: nil,
                dmg_min2: nil, dmg_max2: nil, dmg_type2: nil,
                armor: nil, holy_res: nil, fire_res: nil, nature_res: nil,
                frost_res: nil, shadow_res: nil, arcane_res: nil,
                spellid_1: nil, spelltrigger_1: nil, spellcharges_1: nil,
                spellcooldown_1: nil, spellcategory_1: nil, spellcategorycooldown_1: nil,
                spellid_2: nil, spelltrigger_2: nil, spellcharges_2: nil,
                spellcooldown_2: nil, spellcategory_2: nil, spellcategorycooldown_2: nil,
                spellid_3: nil, spelltrigger_3: nil, spellcharges_3: nil,
                spellcooldown_3: nil, spellcategory_3: nil, spellcategorycooldown_3: nil,
                spellid_4: nil, spelltrigger_4: nil, spellcharges_4: nil,
                spellcooldown_4: nil, spellcategory_4: nil, spellcategorycooldown_4: nil,
                spellid_5: nil, spelltrigger_5: nil, spellcharges_5: nil,
                spellcooldown_5: nil, spellcategory_5: nil, spellcategorycooldown_5: nil,
                page_text: nil, page_language: nil, page_material: nil,
                start_quest: nil, lock_id: nil, random_property: nil, set_id: nil,
                max_durability: 120,
                area_bound: nil, map_bound: nil, duration: nil, bag_family: nil,
                disenchant_id: nil, food_type: nil, min_money_loot: nil, max_money_loot: nil,
                extra_flags: nil, other_team_entry: nil
            )
        )

        ItemRowView(
            item: Item(
                entry: 123,
                name: "Plate Chestpiece of the Eagle",
                description: nil,
                quality: 2,
                class: 4,
                subclass: 4,
                patch: 1,
                display_id: 456,
                inventory_type: 5,
                flags: 0,
                buy_count: 1,
                buy_price: 100,
                sell_price: 20,
                item_level: 30,
                required_level: 25,
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
                bonding: 1,
                material: 1,
                sheath: 1,
                stat_type1: 5, stat_value1: 10,
                stat_type2: 6, stat_value2: 5,
                stat_type3: nil, stat_value3: nil,
                stat_type4: nil, stat_value4: nil,
                stat_type5: nil, stat_value5: nil,
                stat_type6: nil, stat_value6: nil,
                stat_type7: nil, stat_value7: nil,
                stat_type8: nil, stat_value8: nil,
                stat_type9: nil, stat_value9: nil,
                stat_type10: nil, stat_value10: nil,
                delay: nil,
                range_mod: nil,
                ammo_type: nil,
                dmg_min1: nil, dmg_max1: nil, dmg_type1: nil,
                dmg_min2: nil, dmg_max2: nil, dmg_type2: nil,
                dmg_min3: nil, dmg_max3: nil, dmg_type3: nil,
                dmg_min4: nil, dmg_max4: nil, dmg_type4: nil,
                dmg_min5: nil, dmg_max5: nil, dmg_type5: nil,
                block: 0,
                armor: 250,
                holy_res: 0, fire_res: 0, nature_res: 0, frost_res: 0, shadow_res: 0, arcane_res: 0,
                spellid_1: nil, spelltrigger_1: nil, spellcharges_1: nil, spellppmrate_1: nil,
                spellcooldown_1: nil, spellcategory_1: nil, spellcategorycooldown_1: nil,
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
                max_durability: 120,
                area_bound: nil, map_bound: nil, duration: nil, bag_family: nil,
                disenchant_id: nil, food_type: nil, min_money_loot: nil, max_money_loot: nil,
                extra_flags: nil, other_team_entry: nil
            )
        )
    }
}
