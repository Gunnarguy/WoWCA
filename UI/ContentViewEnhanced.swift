// UI/ContentViewEnhanced.swift
import SwiftUI

struct ContentViewEnhanced: View {
    @State private var searchViewModel = ItemSearchViewModel()

    var body: some View {
        NavigationView {
            VStack {
                SearchView(viewModel: searchViewModel)
                    .padding(.horizontal)

                List(searchViewModel.searchResults) { item in
                    NavigationLink(destination: ItemDetailViewEnhanced(item: item)) {
                        ItemRowViewEnhanced(item: item)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("WoW Classic Items")
            .task {
                await searchViewModel.loadInitialData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentViewEnhanced()
}
