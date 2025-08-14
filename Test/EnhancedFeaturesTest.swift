// Test/EnhancedFeaturesTest.swift
import Foundation
import GRDB

/// Simple test to verify the enhanced WoW Classic item database features
struct EnhancedFeaturesTest {
    static func runTests() async {
        print("🧪 Running Enhanced Features Tests...")

        // Test 1: Database connectivity
        await testDatabaseConnection()

        // Test 2: FTS search for Flurry Axe
        await testFlurryAxeSearch()

        // Test 3: Weapon stats computation
        await testWeaponStats()

        // Test 4: Armor items
        await testArmorItems()

        print("✅ All tests completed!")
    }

    private static func testDatabaseConnection() async {
        print("\n📦 Testing database connection...")

        do {
            let dbPath = "/Users/gunnarhostetler/Documents/GitHub/WoWCA/Resources/items.sqlite"
            let dbQueue = try DatabaseQueue(path: dbPath)

            let itemCount = try await dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items") ?? 0
            }

            print("   Found \(itemCount) items in database")
            assert(itemCount > 0, "Database should contain items")

        } catch {
            print("   ❌ Database connection failed: \(error)")
        }
    }

    private static func testFlurryAxeSearch() async {
        print("\n🔍 Testing Flurry Axe search...")

        do {
            let dbPath = "/Users/gunnarhostetler/Documents/GitHub/WoWCA/Resources/items.sqlite"
            let dbQueue = try DatabaseQueue(path: dbPath)

            // Test FTS search
            let searchResults = try await dbQueue.read { db in
                try Row.fetchAll(
                    db,
                    sql: """
                            SELECT i.entry, i.name, i.dmg_min1, i.dmg_max1, i.delay, i.quality
                            FROM items_fts f 
                            JOIN items i ON f.entry = i.entry 
                            WHERE f.name MATCH 'flurry axe'
                        """)
            }

            print("   Found \(searchResults.count) results for 'flurry axe'")

            if let flurryAxe = searchResults.first {
                let entry = flurryAxe["entry"] as! Int64
                let name = flurryAxe["name"] as! String
                let minDmg = flurryAxe["dmg_min1"] as? Double
                let maxDmg = flurryAxe["dmg_max1"] as? Double
                let delay = flurryAxe["delay"] as? Int
                let quality = flurryAxe["quality"] as! Int

                print("   Item: \(name) (ID: \(entry))")
                print("   Damage: \(minDmg ?? 0) - \(maxDmg ?? 0)")
                print("   Speed: \(Double(delay ?? 0) / 1000.0)s")
                print("   Quality: \(quality) (Epic)")

                assert(entry == 871, "Should find Flurry Axe with entry 871")
                assert(name == "Flurry Axe", "Should find correct item name")
                assert(minDmg == 37.0, "Should have correct min damage")
                assert(maxDmg == 69.0, "Should have correct max damage")
                assert(delay == 1500, "Should have correct weapon speed")
            }

        } catch {
            print("   ❌ Flurry Axe search failed: \(error)")
        }
    }

    private static func testWeaponStats() async {
        print("\n⚔️ Testing weapon stats computation...")

        // Create a mock Flurry Axe item
        let flurryAxe = Item(
            entry: 871,
            name: "Flurry Axe",
            quality: 4,
            class: 2,
            subclass: 0,
            inventory_type: 13,
            item_level: 47,
            required_level: 42,
            stat_type1: 7,
            stat_value1: 15,
            stat_type2: 3,
            stat_value2: 10,
            stat_type3: nil,
            stat_value3: nil,
            stat_type4: nil,
            stat_value4: nil,
            delay: 1500,
            dmg_min1: 37.0,
            dmg_max1: 69.0,
            dmg_type1: 0,
            armor: nil,
            fire_res: nil,
            nature_res: nil,
            frost_res: nil,
            shadow_res: nil,
            allowable_class: -1,
            buy_price: 148139,
            sell_price: 29627
        )

        print("   Item: \(flurryAxe.name)")
        print("   Is Weapon: \(flurryAxe.isWeapon)")
        print("   Quality: \(flurryAxe.qualityName) (\(flurryAxe.qualityColor))")
        print("   Type: \(flurryAxe.itemTypeName)")

        if let damageString = flurryAxe.weaponDamageString {
            print("   Damage: \(damageString)")
        }

        if let speedString = flurryAxe.weaponSpeed {
            print("   Speed: \(speedString)")
        }

        if let dpsString = flurryAxe.dpsString {
            print("   DPS: \(dpsString)")
        }

        if let dps = flurryAxe.weaponDPS {
            print("   Computed DPS: \(String(format: "%.2f", dps))")
        }

        let stats = flurryAxe.formattedStats
        print("   Stats: \(stats)")

        // Assertions
        assert(flurryAxe.isWeapon, "Should be identified as weapon")
        assert(flurryAxe.qualityName == "Epic", "Should be Epic quality")
        assert(flurryAxe.itemTypeName == "One-Handed Axe", "Should be One-Handed Axe")
        assert(!stats.isEmpty, "Should have some stats")
    }

    private static func testArmorItems() async {
        print("\n🛡️ Testing armor items...")

        do {
            let dbPath = "/Users/gunnarhostetler/Documents/GitHub/WoWCA/Resources/items.sqlite"
            let dbQueue = try DatabaseQueue(path: dbPath)

            let armorResults = try await dbQueue.read { db in
                try Row.fetchAll(
                    db,
                    sql: """
                            SELECT entry, name, armor, fire_res, shadow_res, frost_res, nature_res
                            FROM items 
                            WHERE armor > 0 
                            LIMIT 5
                        """)
            }

            print("   Found \(armorResults.count) armor items")

            for armorRow in armorResults {
                let entry = armorRow["entry"] as! Int64
                let name = armorRow["name"] as! String
                let armor = armorRow["armor"] as? Int

                print("   - \(name) (ID: \(entry)): \(armor ?? 0) armor")
            }

        } catch {
            print("   ❌ Armor test failed: \(error)")
        }
    }
}

// Extension to make Item initializable for testing
extension Item {
    init(
        entry: Int64, name: String, quality: Int, class: Int?, subclass: Int?,
        inventory_type: Int?, item_level: Int?, required_level: Int?,
        stat_type1: Int?, stat_value1: Int?, stat_type2: Int?, stat_value2: Int?,
        stat_type3: Int?, stat_value3: Int?, stat_type4: Int?, stat_value4: Int?,
        delay: Int?, dmg_min1: Double?, dmg_max1: Double?, dmg_type1: Int?,
        armor: Int?, fire_res: Int?, nature_res: Int?, frost_res: Int?, shadow_res: Int?,
        allowable_class: Int?, buy_price: Int?, sell_price: Int?
    ) {

        self.entry = entry
        self.name = name
        self.quality = quality
        self.class = `class`
        self.subclass = subclass
        self.inventory_type = inventory_type
        self.item_level = item_level
        self.required_level = required_level
        self.stat_type1 = stat_type1
        self.stat_value1 = stat_value1
        self.stat_type2 = stat_type2
        self.stat_value2 = stat_value2
        self.stat_type3 = stat_type3
        self.stat_value3 = stat_value3
        self.stat_type4 = stat_type4
        self.stat_value4 = stat_value4
        self.delay = delay
        self.dmg_min1 = dmg_min1
        self.dmg_max1 = dmg_max1
        self.dmg_type1 = dmg_type1
        self.armor = armor
        self.fire_res = fire_res
        self.nature_res = nature_res
        self.frost_res = frost_res
        self.shadow_res = shadow_res
        self.allowable_class = allowable_class
        self.buy_price = buy_price
        self.sell_price = sell_price
    }
}
