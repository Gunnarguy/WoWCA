// Data/Search/ItemSearchViewModel.swift
import Foundation
import GRDB
import Observation

@Observable
final class ItemSearchViewModel {
    // Publicly bindable state (not actor-isolated; we marshal mutations onto main actor manually)
    var query: String = ""
    private(set) var results: [Item] = []
    private(set) var isSearching = false

    private let dbQueue: DatabaseQueue
    private var searchTask: Task<Void, Never>?

    init(dbQueue: DatabaseQueue) { self.dbQueue = dbQueue }

    // Debounced type-to-search
    func updateQuery(_ q: String) {
        query = q
        searchTask?.cancel()
        // Optimistic immediate UI change
        isSearching = true
        // Debounce
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)  // 150 ms
            guard let self else { return }
            await self.performSearch()
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await MainActor.run {
                self.results = []
                self.isSearching = false
            }
            return
        }

        let limit = 50
        do {
            var fetched: [Item] = try await dbQueue.read { db in
                if let itemId = Int(trimmed) {
                    print("🔍 Searching by ID: \(itemId)")
                    return try Item.filter(key: itemId).limit(1).fetchAll(db)
                } else {
                    let ftsQuery = trimmed.split(separator: " ").map { "\($0)*" }.joined(
                        separator: " ")
                    print("🔍 FTS Query: '\(ftsQuery)' for search: '\(trimmed)'")
                    let sql = """
                        SELECT i.* FROM items i
                        JOIN items_fts f ON i.entry = f.rowid
                        WHERE items_fts MATCH ?
                        ORDER BY rank
                        LIMIT ?
                        """
                    let results = try Item.fetchAll(db, sql: sql, arguments: [ftsQuery, limit])
                    print("🔍 Found \(results.count) results")
                    return results
                }
            }

            if !fetched.isEmpty {
                fetched = await withTaskGroup(of: Item.self) { group in
                    for item in fetched {
                        group.addTask { [weak self] in
                            guard let self else { return item }
                            var mutableItem = item
                            let spellIds = await mutableItem.allSpellEffects.map { $0.spellId }
                            if !spellIds.isEmpty {
                                if let spells: [Spell] = try? await self.dbQueue.read({ db in
                                    try Spell.filter(spellIds.contains(Column("entry"))).fetchAll(
                                        db)
                                }) {
                                    mutableItem.spells = spells
                                }
                            }
                            return mutableItem
                        }
                    }
                    var collected: [Item] = []
                    for await updated in group { collected.append(updated) }
                    let order = fetched.map { $0.entry }
                    collected.sort { lhs, rhs in
                        (order.firstIndex(of: lhs.entry) ?? 0)
                            < (order.firstIndex(of: rhs.entry) ?? 0)
                    }
                    return collected
                }
            }

            await MainActor.run {
                self.results = fetched
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.results = []
                self.isSearching = false
            }
            print("Search failed: \(error)")
        }
    }
}
