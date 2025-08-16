// UI/RootView.swift
// Main entry container providing tab navigation so About/Privacy is visible immediately.

import SwiftUI

struct RootView: View {
    @Bindable var vm: ItemSearchViewModel

    var body: some View {
        TabView {
            SearchView(vm: vm)
                .tabItem { Label("Items", systemImage: "magnifyingglass") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
    }
}

#if DEBUG
    struct RootView_Previews: PreviewProvider {
        static var previews: some View {
            Text("Preview").tabItem { Label("Items", systemImage: "magnifyingglass") }
        }
    }
#endif
