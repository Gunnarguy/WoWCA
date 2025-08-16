// UI/SearchView.swift
import SwiftUI

// Forward declaration ensures AboutView symbol is visible to previews even if file ordering changes.
@available(*, unavailable)
private struct _AboutView_ForwardDecl: View { var body: some View { EmptyView() } }

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
                            ItemRowView(item: item)
                        }
                    }
                    .navigationDestination(for: Item.self) { item in
                        ItemDetailView(item: item)
                    }
                }
            }
            .navigationTitle("Classic Items")
        }
        .searchable(text: $vm.query, prompt: "Search by name")
        .onChange(of: vm.query) { _, newValue in
            vm.updateQuery(newValue)
        }
    }
}
