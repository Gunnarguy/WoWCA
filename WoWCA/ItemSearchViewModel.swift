// Data/Search/ItemSearchViewModel.swift
import Foundation
import GRDB
import Observation

@Observable
final class ItemSearchViewModel {
    @MainActor var query: String = ""
    @MainActor private(set) var results: [Item] = []
    @MainActor private(set) var isSearching = false

    private let dbQueue: DatabaseQueue
    private var searchTask: Task<Void, Never>?

    init(dbQueue: DatabaseQueue) { self.dbQueue = dbQueue }

    // Debounced type-to-search
    @MainActor
    func updateQuery(_ q: String) {
        query = q
        searchTask?.cancel()
        isSearching = true
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)  // 150 ms debounce
            await self?.performSearch()
        }
    }

    @MainActor
    private func performSearch() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            isSearching = false
            return
        }
        let limit = 50
        let q = query

        do {
            let items: [Item] = try await dbQueue.read { db in
                // Check if query is a number (item ID search)
                if let itemId = Int(q.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    // Direct ID search
                    let sql = "SELECT * FROM items WHERE entry = ? LIMIT ?"
                    return try Item.fetchAll(db, sql: sql, arguments: [itemId, limit])
                } else {
                    // Use FTS5 MATCH + ranking. Prefix matching via token*.
                    let sql = """
                        SELECT i.*
                        FROM items_fts f
                        JOIN items i ON i.entry = f.entry
                        WHERE items_fts MATCH ?
                        ORDER BY rank
                        LIMIT ?
                        """
                    // Transform user input into a safe FTS5 query. Simple heuristic:
                    // split by spaces, append '*' for prefix matching.
                    let fts = q.split(separator: " ")
                        .map { "\($0)*" }
                        .joined(separator: " ")
                    return try Item.fetchAll(db, sql: sql, arguments: [fts, limit])
                }
            }
            results = items
        } catch {
            results = []
        }
        isSearching = false
    }
}
