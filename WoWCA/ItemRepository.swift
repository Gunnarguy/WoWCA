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
            print("🏗️ ItemRepository created with database queue")
        }

        /// Perform a search across items table and FTS table.
        /// - Parameter rawQuery: user-entered text (may contain whitespace / numbers)
        /// - Returns: Up to `limit` matching items.
        func search(rawQuery: String, limit: Int = 50) throws -> [Item] {
            logger.info("🔍 search() called with query: '\(rawQuery)', limit: \(limit)")
            print("🔍 Repository search: '\(rawQuery)' (limit: \(limit))")

            let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                logger.info("📭 Empty query after trimming, returning empty results")
                print("📭 Empty trimmed query, returning []")
                return []
            }

            return try dbQueue.read { db in
                print("🗄️ Starting database read transaction...")

                // Check if query is numeric for direct ID lookup
                if let numeric = Int(trimmed) {
                    logger.info("🔢 Numeric query detected: \(numeric), performing ID lookup")
                    print("🔢 Numeric query: \(numeric) - doing ID lookup")

                    let items = try Item.filter(key: numeric).limit(1).fetchAll(db)
                    logger.info("✅ ID lookup returned \(items.count) items")
                    print("✅ ID lookup result: \(items.count) items")
                    return items
                }

                // Build FTS query with token prefixes
                logger.info("🔤 Text query detected, building FTS query...")
                print("🔤 Text query - building FTS search...")

                let tokens = trimmed.split(whereSeparator: { $0.isWhitespace })
                let ftsTokens = tokens.map { "\($0)*" }
                let ftsQuery = ftsTokens.joined(separator: " ")

                logger.info("🔍 FTS tokens: \(tokens) -> \(ftsTokens)")
                logger.info("🔍 Final FTS query: '\(ftsQuery)'")
                print("🔍 FTS tokens: \(tokens.count) -> '\(ftsQuery)'")

                let sql = """
                    SELECT i.* FROM items i
                    JOIN items_fts f ON i.entry = f.rowid
                    WHERE items_fts MATCH ?
                    ORDER BY rank
                    LIMIT ?
                    """

                logger.info("📝 Executing SQL query...")
                print("📝 Executing FTS SQL query...")
                print("🔍 SQL: \(sql)")
                print("🔍 Args: ['\(ftsQuery)', \(limit)]")

                let queryStart = Date()
                let items = try Item.fetchAll(db, sql: sql, arguments: [ftsQuery, limit])
                let queryDuration = Date().timeIntervalSince(queryStart)

                logger.info("⏱️ SQL query completed in \(String(format: "%.3f", queryDuration))s")
                logger.info("📊 FTS search returned \(items.count) items")
                print("⏱️ SQL query duration: \(String(format: "%.3f", queryDuration))s")
                print("📊 FTS search result: \(items.count) items")

                // Log first few results for debugging
                if !items.isEmpty {
                    print("🔍 First few results:")
                    for (index, item) in items.prefix(3).enumerated() {
                        print("  \(index + 1). [\(item.entry)] \(item.name)")
                    }
                    if items.count > 3 {
                        print("  ... and \(items.count - 3) more")
                    }
                }

                return items
            }
        }

        /// Enrich items with spell rows if they have spell effect references.
        func enrichWithSpells(items: [Item]) -> [Item] {
            logger.info("🪄 enrichWithSpells() called with \(items.count) items")
            print("🪄 Enriching \(items.count) items with spell data...")

            guard !items.isEmpty else {
                logger.info("📭 No items to enrich, returning empty array")
                print("📭 No items to enrich")
                return items
            }

            var enriched: [Item] = []
            enriched.reserveCapacity(items.count)
            var totalSpellsLoaded = 0

            for (index, var item) in items.enumerated() {
                print("🪄 Processing item \(index + 1)/\(items.count): [\(item.entry)] \(item.name)")

                // Compute spell IDs directly to avoid relying on any global actor isolation.
                let spellIds: [Int] = [
                    item.spellid_1, item.spellid_2, item.spellid_3, item.spellid_4, item.spellid_5,
                ].compactMap { $0 }.filter { $0 != 0 }

                if !spellIds.isEmpty {
                    logger.info("🔮 Item [\(item.entry)] has spell IDs: \(spellIds)")
                    print("🔮 Item has \(spellIds.count) spell IDs: \(spellIds)")

                    do {
                        let spells: [Spell] = try dbQueue.read({ db in
                            print("🗄️ Querying spells table for IDs: \(spellIds)")
                            let spells = try Spell.filter(spellIds.contains(Column("id"))).fetchAll(
                                db)
                            print("✅ Loaded \(spells.count) spells from database")
                            return spells
                        })

                        if !spells.isEmpty {
                            item.spells = spells
                            totalSpellsLoaded += spells.count
                            logger.info("✅ Attached \(spells.count) spells to item [\(item.entry)]")
                            print("✅ Attached \(spells.count) spells to item [\(item.entry)]")

                            // Log spell details
                            for spell in spells {
                                print("  🔮 Spell [\(spell.id)]: \(spell.name1 ?? "Unknown")")
                            }
                        } else {
                            logger.info(
                                "⚠️ No spells found for item [\(item.entry)] spell IDs: \(spellIds)")
                            print("⚠️ No spells found for IDs: \(spellIds)")
                        }
                    } catch {
                        logger.error(
                            "❌ Failed to load spells for item [\(item.entry)]: \(error.localizedDescription)"
                        )
                        print("❌ Spell loading error for item [\(item.entry)]: \(error)")
                    }
                } else {
                    print("🚫 Item [\(item.entry)] has no spell IDs")
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
        func enrichWithSpells(items: [Item]) -> [Item] { items }
    }
#endif
