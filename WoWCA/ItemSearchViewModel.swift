// Data/Search/ItemSearchViewModel.swift
import Foundation
import GRDB
import Observation

@Observable
@MainActor
final class ItemSearchViewModel {
    var query: String = ""
    private(set) var results: [Item] = []
    private(set) var isSearching = false

    private let repository: ItemRepository
    private var debounceTask: Task<Void, Never>? = nil

    init(repository: ItemRepository) { self.repository = repository }

    func updateQuery(_ new: String) {
        query = new
        debounceTask?.cancel()
        isSearching = true
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self else { return }
            await self.executeSearch()
        }
    }

    private func executeSearch() async {
        let current = query
        if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            results = []
            isSearching = false
            return
        }
        do {
            let rawItems = try await repository.search(rawQuery: current)
            let enriched = await repository.enrichWithSpells(items: rawItems)
            if current == query { results = enriched }
        } catch {
            if current == query { results = [] }
            print("Search failed: \(error)")
        }
        if current == query { isSearching = false }
    }
}
