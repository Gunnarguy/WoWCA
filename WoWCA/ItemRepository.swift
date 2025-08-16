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

#if canImport(GRDB)
    import GRDB

    /// Actor that serializes all synchronous GRDB `DatabaseQueue` work onto a single
    /// executor. This prevents "unsafeForcedSync" concurrency diagnostics while
    /// keeping call‑sites simple (they just `await` actor methods).
    actor ItemRepository {
        private let dbQueue: DatabaseQueue

        init(dbQueue: DatabaseQueue) {
            self.dbQueue = dbQueue
        }

        /// Perform a search across items table and FTS table.
        /// - Parameter rawQuery: user-entered text (may contain whitespace / numbers)
        /// - Returns: Up to `limit` matching items.
        func search(rawQuery: String, limit: Int = 50) throws -> [Item] {
            let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return [] }

            return try dbQueue.read { db in
                if let numeric = Int(trimmed) {  // direct ID lookup
                    return try Item.filter(key: numeric).limit(1).fetchAll(db)
                }
                // Basic token prefix search: transform tokens into 'token*'
                let ftsQuery =
                    trimmed
                    .split(whereSeparator: { $0.isWhitespace })
                    .map { "\($0)*" }
                    .joined(separator: " ")
                let sql = """
                    SELECT i.* FROM items i
                    JOIN items_fts f ON i.entry = f.rowid
                    WHERE items_fts MATCH ?
                    ORDER BY rank
                    LIMIT ?
                    """
                return try Item.fetchAll(db, sql: sql, arguments: [ftsQuery, limit])
            }
        }

        /// Enrich items with spell rows if they have spell effect references.
        func enrichWithSpells(items: [Item]) -> [Item] {
            guard !items.isEmpty else { return items }
            var enriched: [Item] = []
            enriched.reserveCapacity(items.count)
            for var item in items {
                // Compute spell IDs directly to avoid relying on any global actor isolation.
                let spellIds: [Int] = [
                    item.spellid_1, item.spellid_2, item.spellid_3, item.spellid_4, item.spellid_5,
                ].compactMap { $0 }.filter { $0 != 0 }
                if !spellIds.isEmpty {
                    if let spells: [Spell] = try? dbQueue.read({ db in
                        try Spell.filter(spellIds.contains(Column("entry"))).fetchAll(db)
                    }) {
                        item.spells = spells
                    }
                }
                enriched.append(item)
            }
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
