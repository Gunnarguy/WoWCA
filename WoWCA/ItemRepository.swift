// ItemRepository.swift
// Central actor encapsulating all database reads so we avoid performing
// synchronous GRDB work from arbitrary Swift concurrency contexts and to
// keep `ItemSearchViewModel` purely @MainActor for UI state.
//
// This eliminates the runtime warning:
// "Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context."
// by ensuring GRDB's synchronous `DatabaseQueue` is only touched inside
// this actor (a single serialized executor) instead of from detached tasks.
import Foundation
import os.log

#if canImport(GRDB)
    import GRDB

    /// Actor that serializes all synchronous GRDB `DatabaseQueue` work onto a single
    /// executor. This prevents "unsafeForcedSync" concurrency diagnostics while
    /// keeping call‑sites simple (they just `await` actor methods).
    actor ItemRepository {
        private let dbQueue: DatabaseQueue
        private let logger = Logger(subsystem: "com.wowca.app", category: "Repository")

        init(dbQueue: DatabaseQueue) {
            self.dbQueue = dbQueue
            logger.info("🏗️ ItemRepository actor initialized")
        }

        /// Perform a comprehensive search across items table, FTS table, stats, and spell descriptions.
        /// - Parameter rawQuery: user-entered text (may contain whitespace / numbers)
        /// - Returns: Up to `limit` matching items.
        func search(rawQuery: String, limit: Int = 50) throws -> [Item] {
            logger.info("🔍 search() called with query: '\(rawQuery)', limit: \(limit)")

            let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                logger.info("📭 Empty query after trimming, returning empty results")
                return []
            }

            return try dbQueue.read { db in
                // Check if query is numeric for direct ID lookup
                if let numeric = Int(trimmed) {
                    logger.info("🔢 Numeric query detected: \(numeric), performing ID lookup")

                    let items = try Item.filter(key: numeric).limit(1).fetchAll(db)
                    logger.info("✅ ID lookup returned \(items.count) items")
                    return items
                }

                // Perform comprehensive search combining multiple strategies
                logger.info("🔤 Text query detected, performing comprehensive search...")
                
                var allResults: [Item] = []
                var seenEntries: Set<Int64> = []
                
                // Strategy 1: Traditional FTS search (highest priority)
                let ftsResults = try performFTSSearch(db: db, query: trimmed, limit: limit)
                logger.info("📝 FTS search returned \(ftsResults.count) items")
                
                for item in ftsResults {
                    if seenEntries.insert(item.entry).inserted {
                        allResults.append(item)
                    }
                }
                
                // Strategy 2: Stat-based search (for queries like "spell crit", "attack power")
                if allResults.count < limit {
                    let statResults = try performStatSearch(db: db, query: trimmed, limit: limit - allResults.count)
                    logger.info("📊 Stat search returned \(statResults.count) items")
                    
                    for item in statResults {
                        if seenEntries.insert(item.entry).inserted {
                            allResults.append(item)
                        }
                    }
                }
                
                // Strategy 3: Spell description search (for queries like "extra attack", "chance on hit")
                if allResults.count < limit {
                    let spellResults = try performSpellDescriptionSearch(db: db, query: trimmed, limit: limit - allResults.count)
                    logger.info("🪄 Spell description search returned \(spellResults.count) items")
                    
                    for item in spellResults {
                        if seenEntries.insert(item.entry).inserted {
                            allResults.append(item)
                        }
                    }
                }
                
                // Strategy 4: Quality-based search (for queries like "epic", "rare", "legendary")
                if allResults.count < limit {
                    let qualityResults = try performQualitySearch(db: db, query: trimmed, limit: limit - allResults.count)
                    logger.info("💎 Quality search returned \(qualityResults.count) items")
                    
                    for item in qualityResults {
                        if seenEntries.insert(item.entry).inserted {
                            allResults.append(item)
                        }
                    }
                }
                
                // Strategy 5: Class/Equipment type search (for queries like "sword", "staff", "plate")
                if allResults.count < limit {
                    let equipmentResults = try performEquipmentTypeSearch(db: db, query: trimmed, limit: limit - allResults.count)
                    logger.info("⚔️ Equipment type search returned \(equipmentResults.count) items")
                    
                    for item in equipmentResults {
                        if seenEntries.insert(item.entry).inserted {
                            allResults.append(item)
                        }
                    }
                }

                logger.info("🏁 Comprehensive search completed: \(allResults.count) total unique items")
                
                // Log helpful search suggestions if no results found
                if allResults.isEmpty {
                    logSearchSuggestions(for: trimmed)
                }
                
                return Array(allResults.prefix(limit))
            }
        }
        
        /// Perform traditional FTS search
        private func performFTSSearch(db: Database, query: String, limit: Int) throws -> [Item] {
            let tokens = query.split(whereSeparator: { $0.isWhitespace })
            let ftsTokens = tokens.map { "\($0)*" }
            let ftsQuery = ftsTokens.joined(separator: " ")

            let sql = """
                SELECT i.* FROM items i
                JOIN items_fts f ON i.entry = f.rowid
                WHERE items_fts MATCH ?
                ORDER BY rank
                LIMIT ?
                """

            return try Item.fetchAll(db, sql: sql, arguments: [ftsQuery, limit])
        }
        
        /// Perform stat-based search for queries matching stat names
        private func performStatSearch(db: Database, query: String, limit: Int) throws -> [Item] {
            let lowercaseQuery = query.lowercased()
            
            // Map common search terms to stat types
            let statTypeMatches: [Int] = getStatTypesForQuery(lowercaseQuery)
            
            guard !statTypeMatches.isEmpty else { return [] }
            
            // Build query to find items with any of these stat types
            let statConditions = statTypeMatches.flatMap { statType in
                (1...10).map { index in
                    "stat_type\(index) = \(statType)"
                }
            }.joined(separator: " OR ")
            
            let sql = """
                SELECT * FROM items
                WHERE (\(statConditions))
                ORDER BY item_level DESC, quality DESC
                LIMIT ?
                """
            
            return try Item.fetchAll(db, sql: sql, arguments: [limit])
        }
        
        /// Perform spell description search with smart pattern matching
        private func performSpellDescriptionSearch(db: Database, query: String, limit: Int) throws -> [Item] {
            let lowercaseQuery = query.lowercased()
            
            // Smart pattern matching for common search patterns
            let searchPatterns = getSpellSearchPatterns(for: lowercaseQuery)
            
            guard !searchPatterns.isEmpty else { return [] }
            
            // Build search conditions using parameterized queries
            var conditions: [String] = []
            var arguments: [DatabaseValueConvertible] = []
            
            for pattern in searchPatterns {
                conditions.append("(LOWER(s.description1) LIKE ? OR LOWER(s.name1) LIKE ?)")
                arguments.append(pattern)
                arguments.append(pattern)
            }
            
            let whereClause = conditions.joined(separator: " OR ")
            
            let sql = """
                SELECT DISTINCT i.* FROM items i
                JOIN spell_template_ultimate_nerd s ON (
                    i.spellid_1 = s.entry OR 
                    i.spellid_2 = s.entry OR 
                    i.spellid_3 = s.entry OR 
                    i.spellid_4 = s.entry OR 
                    i.spellid_5 = s.entry
                )
                WHERE \(whereClause)
                ORDER BY i.item_level DESC, i.quality DESC
                LIMIT ?
                """
            
            arguments.append(limit)
            
            return try Item.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
        }
        
        /// Generate smart search patterns for spell descriptions
        private func getSpellSearchPatterns(for query: String) -> [String] {
            var patterns: [String] = []
            
            // Handle specific exact phrases first (most precise)
            if query.contains("chance on hit") {
                patterns.append("%chance on hit%")
                patterns.append("%chance on melee hit%")
                patterns.append("%chance on spell hit%")
                patterns.append("%chance on attack%")
                patterns.append("%chance when landing%")
                patterns.append("%chance when striking%")
                patterns.append("%chance when you strike%")
                patterns.append("%chance when hit%")
                patterns.append("%chance when you hit%")
                patterns.append("%chance when struck%")
                patterns.append("%chance to deal%")
                patterns.append("%chance of casting%")
                patterns.append("%chance to inflict%")
                patterns.append("%chance to strike%")
                patterns.append("%strike has a%chance%") // poison procs
                patterns.append("%attack a chance%") // weapon enchants
                return patterns // Return early for specific searches
            }
            
            if query.contains("extra attack") || query == "extra" {
                patterns.append("%extra attack%")
                patterns.append("%additional attack%")
                patterns.append("%grants%attack%")
                return patterns
            }
            
            // Handle broader search terms
            if query.contains("proc") {
                patterns.append("%chance on hit%")
                patterns.append("%chance on melee hit%")
                patterns.append("%chance on spell hit%")
                patterns.append("%chance when%hit%")
                patterns.append("%chance when landing%")
                patterns.append("%chance when striking%")
                patterns.append("%chance when struck%")
                patterns.append("%chance to deal%")
                patterns.append("%chance of casting%")
                patterns.append("%chance to inflict%")
                patterns.append("%chance to strike%")
                patterns.append("%strike has a%chance%")
                patterns.append("%attack a chance%")
                patterns.append("%chance of%")
                return patterns
            }
            
            if query.contains("chance") && query.contains("hit") {
                // If both words are present but not as exact phrase
                patterns.append("%chance on hit%")
                patterns.append("%chance on melee hit%")
                patterns.append("%chance to hit%") // accuracy bonuses
                return patterns
            }
            
            if query.contains("crit") || query.contains("critical") {
                patterns.append("%critical strike%")
                patterns.append("%critical hit%")
                patterns.append("%chance to get a critical%")
                return patterns
            }
            
            if query.contains("heal") {
                patterns.append("%heals%")
                patterns.append("%healing%")
                patterns.append("%restores%health%")
                return patterns
            }
            
            if query.contains("mana") {
                patterns.append("%restores%mana%")
                patterns.append("%restores % mana%")
                return patterns
            }
            
            if query.contains("damage") {
                patterns.append("%deals%damage%")
                patterns.append("% damage%")
                return patterns
            }
            
            if query.contains("fire") {
                patterns.append("%fire damage%")
                patterns.append("%flame%")
                patterns.append("%burning%")
                return patterns
            }
            
            if query.contains("frost") || query.contains("ice") || query.contains("cold") {
                patterns.append("%frost damage%")
                patterns.append("%ice%")
                patterns.append("%cold%")
                patterns.append("%freeze%")
                patterns.append("%slow%")
                return patterns
            }
            
            if query.contains("poison") {
                patterns.append("%poison damage%")
                patterns.append("%toxic%")
                patterns.append("%nature damage%")
                return patterns
            }
            
            if query.contains("stun") || query.contains("immobilize") {
                patterns.append("%stun%")
                patterns.append("%immobilize%")
                patterns.append("%paralyze%")
                patterns.append("%incapacitate%")
                return patterns
            }
            
            if query.contains("shield") || query.contains("absorb") {
                patterns.append("%absorb%")
                patterns.append("%shield%")
                patterns.append("%absorbs%damage%")
                return patterns
            }
            
            if query.contains("dot") || query.contains("over time") {
                patterns.append("%over %")
                patterns.append("%every %")
                patterns.append("%per %")
                return patterns
            }
            
            // Default: direct query search
            patterns.append("%\(query)%")
            return patterns
        }
        
        /// Perform quality-based search for queries like "epic", "rare", "legendary"
        private func performQualitySearch(db: Database, query: String, limit: Int) throws -> [Item] {
            let qualityMapping: [String: Int] = [
                "poor": 0, "gray": 0, "grey": 0,
                "common": 1, "white": 1,
                "uncommon": 2, "green": 2,
                "rare": 3, "blue": 3,
                "epic": 4, "purple": 4,
                "legendary": 5, "orange": 5,
                "artifact": 6, "gold": 6
            ]
            
            let lowercaseQuery = query.lowercased()
            for (qualityName, qualityValue) in qualityMapping {
                if lowercaseQuery.contains(qualityName) {
                    let sql = """
                        SELECT * FROM items
                        WHERE quality = ?
                        ORDER BY item_level DESC, name
                        LIMIT ?
                        """
                    return try Item.fetchAll(db, sql: sql, arguments: [qualityValue, limit])
                }
            }
            
            return []
        }
        
        /// Perform equipment type search for queries like "sword", "staff", "plate"
        private func performEquipmentTypeSearch(db: Database, query: String, limit: Int) throws -> [Item] {
            let lowercaseQuery = query.lowercased()
            
            // Equipment type mappings (class and subclass combinations)
            var conditions: [String] = []
            
            // Weapon types (class = 2)
            if lowercaseQuery.contains("sword") {
                conditions.append("(class = 2 AND (subclass = 7 OR subclass = 10))") // One-Hand Swords, Two-Hand Swords
            }
            if lowercaseQuery.contains("axe") {
                conditions.append("(class = 2 AND (subclass = 0 OR subclass = 1))") // One-Hand Axes, Two-Hand Axes
            }
            if lowercaseQuery.contains("mace") {
                conditions.append("(class = 2 AND (subclass = 4 OR subclass = 5))") // One-Hand Maces, Two-Hand Maces
            }
            if lowercaseQuery.contains("dagger") {
                conditions.append("(class = 2 AND subclass = 15)") // Daggers
            }
            if lowercaseQuery.contains("staff") || lowercaseQuery.contains("stave") {
                conditions.append("(class = 2 AND subclass = 10)") // Staves
            }
            if lowercaseQuery.contains("bow") {
                conditions.append("(class = 2 AND subclass = 2)") // Bows
            }
            if lowercaseQuery.contains("gun") {
                conditions.append("(class = 2 AND subclass = 3)") // Guns
            }
            if lowercaseQuery.contains("wand") {
                conditions.append("(class = 2 AND subclass = 19)") // Wands
            }
            
            // Armor types (class = 4)
            if lowercaseQuery.contains("cloth") {
                conditions.append("(class = 4 AND subclass = 1)") // Cloth
            }
            if lowercaseQuery.contains("leather") {
                conditions.append("(class = 4 AND subclass = 2)") // Leather
            }
            if lowercaseQuery.contains("mail") {
                conditions.append("(class = 4 AND subclass = 3)") // Mail
            }
            if lowercaseQuery.contains("plate") {
                conditions.append("(class = 4 AND subclass = 4)") // Plate
            }
            if lowercaseQuery.contains("shield") {
                conditions.append("(class = 4 AND subclass = 6)") // Shields
            }
            
            // Jewelry and accessories
            if lowercaseQuery.contains("ring") {
                conditions.append("inventory_type = 11") // Rings
            }
            if lowercaseQuery.contains("trinket") {
                conditions.append("inventory_type = 12") // Trinkets
            }
            if lowercaseQuery.contains("neck") || lowercaseQuery.contains("amulet") {
                conditions.append("inventory_type = 2") // Neck
            }
            
            guard !conditions.isEmpty else { return [] }
            
            let whereClause = conditions.joined(separator: " OR ")
            let sql = """
                SELECT * FROM items
                WHERE \(whereClause)
                ORDER BY item_level DESC, quality DESC
                LIMIT ?
                """
            
            return try Item.fetchAll(db, sql: sql, arguments: [limit])
        }
        
        /// Log helpful search suggestions when no results are found
        private func logSearchSuggestions(for query: String) {
            let lowercaseQuery = query.lowercased()
            var suggestions: [String] = []
            
            // Suggest related terms
            if lowercaseQuery.contains("crit") {
                suggestions.append("Try: 'critical strike', 'chance to get a critical'")
            }
            if lowercaseQuery.contains("spell") {
                suggestions.append("Try: 'spell damage', 'spell power', 'improves spells'")
            }
            if lowercaseQuery.contains("attack") {
                suggestions.append("Try: 'extra attack', 'additional attack', 'attack power'")
            }
            if lowercaseQuery.contains("heal") {
                suggestions.append("Try: 'healing', 'restores health', 'heals'")
            }
            if lowercaseQuery.contains("mana") {
                suggestions.append("Try: 'restores mana', 'mana regeneration'")
            }
            
            // Suggest equipment types
            suggestions.append("Equipment: 'sword', 'staff', 'plate armor', 'trinket'")
            
            // Suggest qualities
            suggestions.append("Quality: 'epic', 'rare', 'legendary'")
            
            // Suggest common effects
            suggestions.append("Effects: 'chance on hit', 'proc', 'fire damage', 'frost'")
            
            logger.info("💡 Search suggestions for '\(query)': \(suggestions.joined(separator: "; "))")
        }
        
        /// Map search query terms to relevant stat types (Classic WoW)
        private func getStatTypesForQuery(_ query: String) -> [Int] {
            var statTypes: [Int] = []
            
            // Primary Stats (Classic WoW stat types)
            if query.contains("strength") { statTypes.append(4) }
            if query.contains("agility") { statTypes.append(3) }
            if query.contains("stamina") { statTypes.append(7) }
            if query.contains("intellect") { statTypes.append(5) }
            if query.contains("spirit") { statTypes.append(6) }
            if query.contains("health") { statTypes.append(1) }
            
            // For spell-related queries, we'll rely on spell description search
            // since Classic doesn't have spell power/crit rating as item stats
            
            return Array(Set(statTypes)) // Remove duplicates
        }
        
        /// Add an item to favorites
    func addFavorite(itemId: Int64) async throws {
        logger.info("⭐ Adding item \(itemId) to favorites")
        
        try await dbQueue.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO favorites (item_id) VALUES (?)",
                arguments: [itemId]
            )
        }
        
        logger.info("✅ Item \(itemId) added to favorites")
    }
    
    /// Remove an item from favorites
    func removeFavorite(itemId: Int64) async throws {
        logger.info("⭐ Removing item \(itemId) from favorites")
        
        try await dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM favorites WHERE item_id = ?",
                arguments: [itemId]
            )
        }
        
        logger.info("✅ Item \(itemId) removed from favorites")
    }
        
    /// Check if an item is favorited
    func isFavorite(itemId: Int64) async throws -> Bool {
        logger.info("🔍 Checking if item \(itemId) is favorited")
        
        return try await dbQueue.read { db in
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM favorites WHERE item_id = ?",
                arguments: [itemId]
            ) ?? 0
            let isFav = count > 0
            self.logger.info("📊 Item \(itemId) favorite status: \(isFav)")
            return isFav
        }
    }
    
    /// Fetch all favorited items
    func fetchFavorites() async throws -> [Item] {
        logger.info("⭐ Fetching all favorite items")
        
        return try await dbQueue.read { db in
            let sql = """
                SELECT i.* FROM items i
                JOIN favorites f ON i.entry = f.item_id
                ORDER BY f.created_at DESC
                """
            
            let items = try Item.fetchAll(db, sql: sql)
            self.logger.info("📊 Fetched \(items.count) favorite items")
            return items
        }
    }
        
        /// Add an item to recent items (with automatic cleanup)
        func addToRecent(itemId: Int64) async throws {
            logger.info("🕒 Adding item \(itemId) to recent items")
            
        try await dbQueue.write { db in
            // Insert or update the recent item
            try db.execute(
                sql: "INSERT OR REPLACE INTO recent_items (item_id, accessed_at) VALUES (?, CURRENT_TIMESTAMP)",
                arguments: [itemId]
            )
            
            // Keep only the most recent 50 items
            try db.execute(sql: """
                DELETE FROM recent_items WHERE item_id NOT IN (
                    SELECT item_id FROM recent_items 
                    ORDER BY accessed_at DESC 
                    LIMIT 50
                )
            """)
        }
        
        logger.info("✅ Item \(itemId) added to recent items")
    }
        
        /// Fetch recent items
        func fetchRecentItems() async throws -> [Item] {
            logger.info("🕒 Fetching recent items")
            
            return try await dbQueue.read { db in
                let sql = """
                    SELECT i.* FROM items i
                    JOIN recent_items r ON i.entry = r.item_id
                    ORDER BY r.accessed_at DESC
                    LIMIT 50
                    """
                
                let items = try Item.fetchAll(db, sql: sql)
                self.logger.info("📊 Fetched \(items.count) recent items")
                return items
            }
        }
        
        /// Clear all recent items
        func clearRecentItems() async throws {
            logger.info("🗑️ Clearing all recent items")
            
            try await dbQueue.write { db in
                try db.execute(sql: "DELETE FROM recent_items")
            }
            
            logger.info("✅ All recent items cleared")
        }

        /// Enrich items with spell rows if they have spell effect references.
        func enrichWithSpells(items: [Item]) async -> [Item] {
            logger.info("🪄 enrichWithSpells() called with \(items.count) items")

            guard !items.isEmpty else {
                logger.info("📭 No items to enrich, returning empty array")
                return items
            }

            var enriched: [Item] = []
            enriched.reserveCapacity(items.count)
            var totalSpellsLoaded = 0

            for (index, var item) in items.enumerated() {
                #if DEBUG
                logger.debug("🪄 Processing item \(index + 1)/\(items.count): [\(item.entry)] \(item.name)")
                #endif

                // Compute spell IDs directly to avoid relying on any global actor isolation.
                let spellIds: [Int] = [
                    item.spellid_1, item.spellid_2, item.spellid_3, item.spellid_4, item.spellid_5,
                ].compactMap { $0 }.filter { $0 != 0 }

                if !spellIds.isEmpty {
                    #if DEBUG
                    logger.debug("🔮 Item [\(item.entry)] has spell IDs: \(spellIds)")
                    #endif

                    do {
                        let spells: [Spell] = try await dbQueue.read({ db in
                            let spells = try Spell.filter(spellIds.contains(Column("id"))).fetchAll(
                                db)
                            return spells
                        })

                        if !spells.isEmpty {
                            item.spells = spells
                            totalSpellsLoaded += spells.count
                            logger.info("✅ Attached \(spells.count) spells to item [\(item.entry)]")
                        } else {
                            logger.info(
                                "⚠️ No spells found for item [\(item.entry)] spell IDs: \(spellIds)")
                        }
                    } catch {
                        logger.error(
                            "❌ Failed to load spells for item [\(item.entry)]: \(error.localizedDescription)"
                        )
                    }
                }

                enriched.append(item)
            }

            logger.info(
                "🏁 Enrichment complete: \(enriched.count) items, \(totalSpellsLoaded) total spells loaded"
            )
            print(
                "🏁 Enrichment complete: \(enriched.count) items, \(totalSpellsLoaded) spells loaded"
            )

            return enriched
        }

    }

#else
    // Fallback stub so the project can still index in environments where GRDB
    // isn't present (e.g. certain tooling). The real functionality requires GRDB.
    // Provide lightweight stand‑ins so references compile.
    struct _StubItem {}
    typealias Item = _StubItem
    struct Spell {}
    actor ItemRepository {
        init(dbQueue: Any? = nil) {}
        func search(rawQuery: String, limit: Int = 50) throws -> [Item] { return [] }
        func enrichWithSpells(items: [Item]) async -> [Item] { items }
        func addFavorite(itemId: Int64) async throws {}
        func removeFavorite(itemId: Int64) async throws {}
        func isFavorite(itemId: Int64) async throws -> Bool { false }
        func fetchFavorites() async throws -> [Item] { [] }
        func addToRecent(itemId: Int64) async throws {}
        func fetchRecentItems() async throws -> [Item] { [] }
        func clearRecentItems() async throws {}
    }
#endif
