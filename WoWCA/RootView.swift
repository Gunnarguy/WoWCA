// UI/RootView.swift
// Main entry container providing tab navigation so About/Privacy is visible immediately.

import SwiftUI
import os.log
import GRDB

struct RootView: View {
    @Bindable var vm: ItemSearchViewModel
    @Bindable var favoritesManager: FavoritesManager
    @Bindable var recentsManager: RecentsManager

    // Logger for navigation events
    private let logger = Logger(subsystem: "com.wowca.app", category: "Navigation")

    var body: some View {
        TabView {
            SearchView(vm: vm)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .onAppear {
                    logger.info("🔍 Search tab appeared")
                }

            FavoritesView(favoritesManager: favoritesManager)
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
                .onAppear {
                    logger.info("⭐ Favorites tab appeared")
                }

            RecentsView(recentsManager: recentsManager)
                .tabItem {
                    Label("Recent", systemImage: "clock")
                }
                .onAppear {
                    logger.info("🕒 Recent tab appeared")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .onAppear {
                    logger.info("ℹ️ About tab appeared")
                }
        }
        .environment(favoritesManager)
        .environment(recentsManager)
        .onAppear {
            logger.info("📱 RootView TabView appeared")
        }
        .onDisappear {
            logger.info("👋 RootView TabView disappeared")
        }
    }
}

#if DEBUG
    struct RootView_Previews: PreviewProvider {
        static var previews: some View {
            // Create mock objects for preview
            let mockRepository = ItemRepository(dbQueue: try! DatabaseQueue())
            let mockVM = ItemSearchViewModel(repository: mockRepository)
            let mockFavorites = FavoritesManager(repository: mockRepository)
            let mockRecents = RecentsManager(repository: mockRepository)
            
            RootView(
                vm: mockVM,
                favoritesManager: mockFavorites,
                recentsManager: mockRecents
            )
        }
    }
#endif
