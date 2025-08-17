// Test spell parsing function
import Foundation

// Mock spell data for testing
struct MockSpell {
    let description1: String?
    let effectBasePoints1: Int?
    let effectBasePoints2: Int?
    let effectBasePoints3: Int?

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

        // Replace $o1, $o2, $o3 with over-time damage (usually same as base points)
        if let basePoints1 = effectBasePoints1 {
            let value1 = basePoints1 + 1
            parsed = parsed.replacingOccurrences(of: "$o1", with: "\(value1)")
        }

        if let basePoints2 = effectBasePoints2 {
            let value2 = basePoints2 + 1
            parsed = parsed.replacingOccurrences(of: "$o2", with: "\(value2)")
        }

        if let basePoints3 = effectBasePoints3 {
            let value3 = basePoints3 + 1
            parsed = parsed.replacingOccurrences(of: "$o3", with: "\(value3)")
        }

        // Replace $d with duration placeholder
        parsed = parsed.replacingOccurrences(of: "$d", with: "10 sec")

        // Handle references to other spells like $6788d (duration of spell 6788)
        parsed = parsed.replacingOccurrences(of: "$6788d", with: "15 sec")

        // Handle cross-spell references like $17809s1
        let crossSpellPattern = #"\$(\d+)s(\d+)"#
        parsed = parsed.replacingOccurrences(
            of: crossSpellPattern,
            with: "[spell $1 effect $2]",
            options: .regularExpression)

        // Handle pluralization like $lpoint:points;
        let pluralPattern = #"\$l([^:]+):([^;]+);"#
        parsed = parsed.replacingOccurrences(
            of: pluralPattern,
            with: "$2",  // Use plural form
            options: .regularExpression)

        return parsed
    }
}

// Test cases from the database
let testSpells = [
    MockSpell(
        description1: "Increases damage done by Fire spells and effects by up to $s1.",
        effectBasePoints1: 9, effectBasePoints2: 0, effectBasePoints3: 0),
    MockSpell(
        description1:
            "Enchants the main hand weapon with fire, granting each attack a chance to deal $17809s1 additional fire damage.",
        effectBasePoints1: -1, effectBasePoints2: 0, effectBasePoints3: 0),
    MockSpell(
        description1:
            "Backstab the target, causing $s2% weapon damage plus 15 to the target. Must be behind the target. Requires a dagger in the main hand. Awards $s3 combo $lpoint:points;.",
        effectBasePoints1: 9, effectBasePoints2: 149, effectBasePoints3: 0),
    MockSpell(
        description1: "Ice shards pelt the target area doing $o1 Frost damage over $d.",
        effectBasePoints1: 24, effectBasePoints2: 0, effectBasePoints3: 0),
]

print("Testing spell description parsing:")
for (index, spell) in testSpells.enumerated() {
    print("\nTest \(index + 1):")
    print("Original: \(spell.description1 ?? "")")
    print("Parsed:   \(spell.parsedDescription())")
}
