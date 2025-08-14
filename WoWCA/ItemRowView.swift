// UI/ItemRowView.swift
import SwiftUI

struct ItemRowView: View {
    let item: Item
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder icon - avoid shipping Blizzard art
            Image(systemName: "shippingbox.fill")
                .imageScale(.large)
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(color(for: item.quality))
                Text(subtitle(item))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func subtitle(_ it: Item) -> String {
        var bits: [String] = []
        if let ilvl = it.item_level { bits.append("ilvl \(ilvl)") }
        if let req = it.required_level { bits.append("req \(req)") }
        if let s1 = it.stat_value1, let t1 = it.stat_type1 { bits.append("+\(s1) stat\(t1)") }
        if let s2 = it.stat_value2, let t2 = it.stat_type2 { bits.append("+\(s2) stat\(t2)") }
        return bits.joined(separator: " • ")
    }

    private func color(for quality: Int) -> Color {
        switch quality {
        case 2: return .green
        case 3: return .blue
        case 4: return .purple
        case 5: return .orange
        default: return .primary
        }
    }
}
