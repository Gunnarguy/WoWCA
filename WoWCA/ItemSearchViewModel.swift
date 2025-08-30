// Data/Search/ItemSearchViewModel.swift
import Foundation
import GRDB
import Observation
import os.log

@Observable
@MainActor
final class ItemSearchViewModel {
    var query: String = "" {
        didSet {
            self.logger.info("🔍 Query changed from '\(oldValue)' to '\(self.query)'")
            print("🔍 Search query updated: '\(self.query)'")
        }
    }
    private(set) var results: [Item] = [] {
        didSet {
            self.logger.info("📊 Results updated: \(self.results.count) items")
            print("📊 Search results: \(self.results.count) items found")
        }
    }
    private(set) var isSearching = false {
        didSet {
            self.logger.info("🔄 Search state changed: isSearching = \(self.isSearching)")
            print("🔄 Search state: \(self.isSearching ? "SEARCHING" : "IDLE")")
        }
    }

    private let repository: ItemRepository
    private var debounceTask: Task<Void, Never>? = nil

    // Logger for search operations
    private let logger = Logger(subsystem: "com.wowca.app", category: "Search")

    init(repository: ItemRepository) {
        self.repository = repository
        logger.info("🔍 ItemSearchViewModel initialized")
        print("🔍 ItemSearchViewModel created with repository")
    }

    func updateQuery(_ new: String) {
        self.logger.info("📝 updateQuery called with: '\(new)'")
        print("📝 updateQuery: '\(new)'")

        self.query = new

        // Cancel any existing search
        if let task = self.debounceTask {
            self.logger.info("❌ Cancelling previous search task")
            print("❌ Cancelling previous search")
            task.cancel()
        }

        self.isSearching = true
        self.logger.info("⏱️ Starting debounce timer (150ms)")
        print("⏱️ Debouncing search...")

        self.debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 150_000_000)
                guard let self else {
                    print("⚠️ Self deallocated during debounce")
                    return
                }

                if Task.isCancelled {
                    print("🛑 Search task was cancelled during debounce")
                    return
                }

                print("✅ Debounce completed, executing search")
                await self.executeSearch()
            } catch {
                print("❌ Debounce task error: \(error)")
            }
        }
    }

    private func executeSearch() async {
        let current = self.query
        self.logger.info("🔍 executeSearch starting for query: '\(current)'")
        print("🔍 Executing search for: '\(current)'")

        // Handle empty query
        if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.logger.info("📭 Empty query, clearing results")
            print("📭 Empty query - clearing results")
            self.results = []
            self.isSearching = false
            return
        }

        do {
            self.logger.info("🗄️ Querying repository for items...")
            print("🗄️ Searching database...")
            let searchStart = Date()

            // Use higher limit for class searches to show more gear variety
            let searchLimit = isClassSearch(query: current) ? 200 : 50
            let rawItems = try await self.repository.search(rawQuery: current, limit: searchLimit)

            let searchDuration = Date().timeIntervalSince(searchStart)
            self.logger.info(
                "⏱️ Database search completed in \(String(format: "%.3f", searchDuration))s, found \(rawItems.count) items"
            )
            print(
                "⏱️ Database search: \(String(format: "%.3f", searchDuration))s, \(rawItems.count) raw items"
            )

            self.logger.info("🪄 Enriching items with spell data...")
            print("🪄 Enriching with spells...")
            let enrichStart = Date()

            let enriched = await self.repository.enrichWithSpells(items: rawItems)

            let enrichDuration = Date().timeIntervalSince(enrichStart)
            self.logger.info(
                "⏱️ Spell enrichment completed in \(String(format: "%.3f", enrichDuration))s")
            print("⏱️ Spell enrichment: \(String(format: "%.3f", enrichDuration))s")

            // Only update results if query hasn't changed
            if current == self.query {
                self.logger.info("✅ Query still current, updating results")
                print("✅ Updating UI with \(enriched.count) enriched items")
                self.results = enriched
            } else {
                self.logger.info("🔄 Query changed during search, discarding results")
                print("🔄 Query changed, discarding stale results")
            }
        } catch {
            self.logger.error("❌ Search failed: \(error.localizedDescription)")
            print("❌ Search error: \(error)")
            print("❌ Error details: \(String(describing: error))")

            if current == self.query {
                self.results = []
                self.logger.info("📭 Cleared results due to error")
                print("📭 Results cleared due to error")
            }
        }

        if current == self.query {
            self.isSearching = false
            self.logger.info("🏁 Search completed for query: '\(current)'")
            print("🏁 Search finished for: '\(current)'")
        }
    }
    
    // Helper function to detect if a query is a class search
    private func isClassSearch(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let classNames = ["warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"]
        return classNames.contains(trimmed)
    }
}
