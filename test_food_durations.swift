// Test food duration parsing specifically
import Foundation

// Mock spell data for food items
struct MockFoodSpell {
    let description1: String?
    let durationIndex: Int?
    let effectBasePoints1: Int?

    func durationText() -> String? {
        guard let index = durationIndex, index > 0 else { return nil }

        switch index {
        case 85: return "18 sec"  // Food eating time (low level)
        case 86: return "21 sec"  // Food eating time (medium level)
        case 105: return "24 sec"  // Food eating time (higher level)
        case 106: return "27 sec"  // Food eating time (high level)
        case 205: return "30 sec"  // Special food eating time
        case 347: return "15 min"  // Well-fed buff duration
        default: return "[\(index) duration]"
        }
    }

    func parsedDescription() -> String {
        guard let description = description1, !description.isEmpty else {
            return "No description available"
        }

        var parsed = description

        // Replace effect values
        if let basePoints1 = effectBasePoints1 {
            let value1 = basePoints1 + 1
            parsed = parsed.replacingOccurrences(of: "$s1", with: "\(value1)")
        }

        // Replace duration
        if let durationText = durationText() {
            parsed = parsed.replacingOccurrences(of: "$d", with: durationText)
        } else {
            parsed = parsed.replacingOccurrences(of: "$d", with: "[duration]")
        }

        // Handle well-fed buff references
        parsed = parsed.replacingOccurrences(of: "$19705d", with: "15 min")
        parsed = parsed.replacingOccurrences(of: "$19706d", with: "15 min")
        parsed = parsed.replacingOccurrences(of: "$19708d", with: "15 min")

        return parsed
    }
}

let foodSpells = [
    MockFoodSpell(
        description1: "Restores $s1 health over $d. Must remain seated while eating.",
        durationIndex: 85,
        effectBasePoints1: 61),
    MockFoodSpell(
        description1:
            "Restores $s1 health over $d. Must remain seated while eating. If you spend at least 10 seconds eating you will become well fed and gain stamina for $19705d.",
        durationIndex: 86,
        effectBasePoints1: 243),
    MockFoodSpell(
        description1: "Restores $s1 mana over $d. Must remain seated while drinking.",
        durationIndex: 106,
        effectBasePoints1: 436),
    MockFoodSpell(
        description1: "Well Fed - Stamina increased.",
        durationIndex: 347,
        effectBasePoints1: 4),
]

print("Testing food duration parsing:")
print()

for (index, spell) in foodSpells.enumerated() {
    print("Food Test \(index + 1):")
    print("Original: \(spell.description1 ?? "nil")")
    print("Duration Index: \(spell.durationIndex ?? 0)")
    print("Parsed:   \(spell.parsedDescription())")
    print()
}
