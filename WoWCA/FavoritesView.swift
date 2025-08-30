// FavoritesView.swift
// View for displaying and managing favorite items

import SwiftUI
import GRDB
import os.log

struct FavoritesView: View {
    @Bindable var favoritesManager: FavoritesManager
    
    // Logger for favorites UI events
    private let logger = Logger(subsystem: "com.wowca.app", category: "FavoritesUI")
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Favorites")
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !favoritesManager.isEmpty {
                            Text("\(favoritesManager.favoritesCount)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    #else
                    ToolbarItem(placement: .primaryAction) {
                        if !favoritesManager.isEmpty {
                            Text("\(favoritesManager.favoritesCount)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    #endif
                }
                .onAppear {
                    logger.info("⭐ FavoritesView appeared")
                    print("⭐ FavoritesView appeared")
                    Task {
                        await favoritesManager.loadFavorites()
                    }
                }
                .onDisappear {
                    logger.info("👋 FavoritesView disappeared")
                    print("👋 FavoritesView disappeared")
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if favoritesManager.isLoading {
            loadingView
        } else if favoritesManager.isEmpty {
            emptyStateView
        } else {
            favoritesListView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading favorites...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            logger.info("⏳ Favorites loading state appeared")
            print("⏳ Loading favorites...")
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Favorites Yet", systemImage: "star")
        } description: {
            Text("Items you favorite will appear here. Tap the star icon on any item to add it to your favorites.")
        }
        .onAppear {
            logger.info("📭 Empty favorites state appeared")
            print("📭 No favorites to display")
        }
    }
    
    private var favoritesListView: some View {
        List(favoritesManager.favoriteItems) { item in
            NavigationLink(value: item) {
                ItemRowView(item: item)
                    .contextMenu {
                        Button("Remove from Favorites", systemImage: "star.slash", role: .destructive) {
                            Task {
                                await favoritesManager.removeFavorite(item: item)
                            }
                        }
                    }
                    .onAppear {
                        logger.info("👁️ Favorite item row appeared: [\(item.entry)] \(item.name)")
                        print("👁️ Showing favorite: [\(item.entry)] \(item.name)")
                    }
            }
            .swipeActions(edge: .trailing) {
                Button("Remove", systemImage: "star.slash") {
                    Task {
                        await favoritesManager.removeFavorite(item: item)
                    }
                }
                .tint(.red)
            }
        }
        .navigationDestination(for: Item.self) { item in
            ItemDetailViewEnhanced(item: item)
                .environment(favoritesManager)
                .onAppear {
                    logger.info("📱 ItemDetailViewEnhanced appeared from favorites for: [\(item.entry)] \(item.name)")
                    print("📱 Detail view opened from favorites: [\(item.entry)] \(item.name)")
                }
        }
        .onAppear {
            logger.info("📋 Favorites list appeared with \(favoritesManager.favoritesCount) items")
            print("📋 Favorites list showing \(favoritesManager.favoritesCount) items")
        }
        .refreshable {
            await favoritesManager.loadFavorites()
        }
    }
}

#if DEBUG
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock favorites manager for preview
        let mockRepository = ItemRepository(dbQueue: try! DatabaseQueue())
        let mockManager = FavoritesManager(repository: mockRepository)
        
        FavoritesView(favoritesManager: mockManager)
    }
}
#endif
