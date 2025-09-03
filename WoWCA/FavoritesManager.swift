// FavoritesManager.swift
// Manages user's favorited items with observable state for SwiftUI

import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
final class FavoritesManager {
    private(set) var favoriteItems: [Item] = []
    private(set) var isLoading = false
    private let repository: ItemRepository
    
    // Logger for favorites operations
    private let logger = Logger(subsystem: "com.wowca.app", category: "Favorites")
    
    init(repository: ItemRepository) {
        self.repository = repository
        logger.info("⭐ FavoritesManager initialized")
    }
    
    /// Toggle favorite status for an item
    func toggleFavorite(item: Item) async {
        logger.info("🔄 Toggling favorite for item \(item.entry): \(item.name)")
        
        do {
            let isFav = try await repository.isFavorite(itemId: item.entry)
            
            if isFav {
                try await repository.removeFavorite(itemId: item.entry)
                logger.info("➖ Removed item \(item.entry) from favorites")
                
                // Provide haptic feedback on iOS
                #if os(iOS)
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                #endif
            } else {
                try await repository.addFavorite(itemId: item.entry)
                logger.info("➕ Added item \(item.entry) to favorites")
                
                // Provide haptic feedback on iOS
                #if os(iOS)
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                #endif
            }
            
            // Reload favorites list
            await loadFavorites()
            
        } catch {
            logger.error("❌ Failed to toggle favorite for item \(item.entry): \(error.localizedDescription)")
        }
    }
    
    /// Add item to favorites
    func addFavorite(item: Item) async {
        logger.info("➕ Adding item to favorites: [\(item.entry)] \(item.name)")
        
        do {
            try await repository.addFavorite(itemId: item.entry)
            await loadFavorites()
            
            // Provide haptic feedback on iOS
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            
            logger.info("✅ Successfully added favorite")
        } catch {
            logger.error("❌ Failed to add favorite: \(error.localizedDescription)")
        }
    }
    
    /// Remove item from favorites
    func removeFavorite(item: Item) async {
        logger.info("➖ Removing item from favorites: [\(item.entry)] \(item.name)")
        
        do {
            try await repository.removeFavorite(itemId: item.entry)
            await loadFavorites()
            
            // Provide haptic feedback on iOS
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            
            logger.info("✅ Successfully removed favorite")
        } catch {
            logger.error("❌ Failed to remove favorite: \(error.localizedDescription)")
        }
    }
    
    /// Check if an item is favorited
    func isFavorite(item: Item) async -> Bool {
        do {
            let result = try await repository.isFavorite(itemId: item.entry)
            logger.info("🔍 Item \(item.entry) favorite status: \(result)")
            return result
        } catch {
            logger.error("❌ Failed to check favorite status: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Load all favorite items
    func loadFavorites() async {
        logger.info("📦 Loading all favorite items")
        
        isLoading = true
        
        do {
            let items = try await repository.fetchFavorites()
            favoriteItems = items
            
            logger.info("✅ Loaded \(items.count) favorite items")
        } catch {
            logger.error("❌ Failed to load favorites: \(error.localizedDescription)")
            favoriteItems = []
        }
        
        isLoading = false
    }
    
    /// Get count of favorites for display
    var favoritesCount: Int {
        favoriteItems.count
    }
    
    /// Check if favorites list is empty
    var isEmpty: Bool {
        favoriteItems.isEmpty
    }
}
