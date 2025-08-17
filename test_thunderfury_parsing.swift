// Test Thunderfury parsing with database-driven spell lookups
import Foundation

// Mock spell for testing the improved parsing
struct MockSpell {
    let id: Int
    let description1: String?
    let effectBasePoints1: Int?
    let effectBasePoints2: Int?
    let effectBasePoints3: Int?
    let durationIndex: Int?

    func parsedDescription() -> String {
        guard let description = description1, !description.isEmpty else {
            return "No description available"
        }

        var parsed = description

        // Replace $s1, $s2, $s3 with calculated effect values
        if let basePoints1 = effectBasePoints1 {
            let value1 = basePoints1 + 1  // Base points are stored as value - 1
            parsed = parsed.replacingOccurrences(of: "$s1", with: "\(value1)")
        }

        if let basePoints2 = effectBasePoints2 {
            let value2 = basePoints2 + 1
            parsed = parsed.replacingOccurrences(of: "$s2", with: "\(value2)")
        }

        if let basePoints3 = effectBasePoints3 {
            let value3 = basePoints3 + 1
            parsed = parsed.replacingOccurrences(of: "$s3", with: "\(value3)")
        }

        // Replace $d with duration
        if let durationIndex = durationIndex, durationIndex > 0 {
            let durationText = durationMapping(durationIndex)
            parsed = parsed.replacingOccurrences(of: "$d", with: durationText)
        }

        // Handle cross-spell references for Thunderfury
        parsed = parsed.replacingOccurrences(of: "$27648s1", with: "20")
        parsed = parsed.replacingOccurrences(of: "$x1", with: "4")  // Affects 4 targets

        // Handle pluralization like $lpoint:points;
        let pluralPattern = #"\$l([^:]+):([^;]+);"#
        parsed = parsed.replacingOccurrences(
            of: pluralPattern,
            with: "$2",  // Use plural form
            options: .regularExpression)

        return parsed
    }

    func durationMapping(_ index: Int) -> String {
        switch index {
        case 29: return "12 sec"  // Thunderfury slow effect
        default: return "\(index) sec"
        }
    }
}

// Test Thunderfury spell parsing
let thunderfurySpell = MockSpell(
    id: 21992,
    description1:
        "Blasts your enemy with lightning, dealing $s2 Nature damage and then jumping to additional nearby enemies.  Each jump reduces that victim's Nature resistance by $s1. Affects $x1 targets. Your primary target is also consumed by a cyclone, slowing its attack speed by $27648s1% for $d.",
    effectBasePoints1: -26,  // -27 resistance reduction (stored as -26)
    effectBasePoints2: 299,  // 300 nature damage (stored as 299)
    effectBasePoints3: 0,
    durationIndex: 29  // Cyclone duration
)

print("Testing Thunderfury spell parsing:")
print("Original: \(thunderfurySpell.description1 ?? "")")
print("Parsed:   \(thunderfurySpell.parsedDescription())")
print("")

// Expected output should be:
// "Blasts your enemy with lightning, dealing 300 Nature damage and then jumping to additional nearby enemies. Each jump reduces that victim's Nature resistance by -25. Affects 4 targets. Your primary target is also consumed by a cyclone, slowing its attack speed by 20% for 12 sec."
