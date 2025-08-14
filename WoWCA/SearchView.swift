// UI/SearchView.swift
import SwiftUI

struct SearchView: View {
    @Bindable var vm: ItemSearchViewModel

    var body: some View {
        NavigationStack {
            Group {
                if vm.query.isEmpty {
                    ContentUnavailableView(
                        "Search items", systemImage: "magnifyingglass",
                        description: Text("Type at least 1 character"))
                } else if vm.isSearching {
                    ProgressView().controlSize(.large)
                } else if vm.results.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "exclamationmark.magnifyingglass",
                        description: Text("No matches for \"\(vm.query)\""))
                } else {
                    List(vm.results) { item in
                        NavigationLink(value: item) {
                            ItemRowViewEnhanced(item: item)
                        }
                    }
                    .navigationDestination(for: Item.self) { item in
                        ItemDetailViewEnhanced(item: item)
                    }
                }
            }
            .navigationTitle("Classic Items")
        }
        .searchable(text: $vm.query, prompt: "Search by name")
        .onChange(of: vm.query) { vm.updateQuery($0) }
    }
}
