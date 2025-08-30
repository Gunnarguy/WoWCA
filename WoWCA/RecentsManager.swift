// RecentsManager.swift
// Manages recently viewed items with observable state for SwiftUI

import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
final class RecentsManager {
    private(set) var recentItems: [Item] = []
    private(set) var isLoading = false
    private let repository: ItemRepository
    
    // Logger for recent items operations
    private let logger = Logger(subsystem: "com.wowca.app", category: "Recents")
    
    init(repository: ItemRepository) {
        self.repository = repository
        logger.info("🕒 RecentsManager initialized")
        print("🕒 RecentsManager created")
    }
    
    /// Add an item to recent items (called when user views item detail)
    func addToRecent(item: Item) async {
        logger.info("🕒 Adding item to recent: [\(item.entry)] \(item.name)")
        print("🕒 Adding to recent: \(item.name)")
        
        do {
            try await repository.addToRecent(itemId: item.entry)
            // Don't automatically reload - let the view decide when to refresh
            // This prevents infinite loading when navigating to detail views
            
            logger.info("✅ Successfully added to recent items")
            print("✅ Added to recent items")
        } catch {
            logger.error("❌ Failed to add to recent items: \(error.localizedDescription)")
            print("❌ Error adding to recent: \(error)")
        }
    }
    
    /// Load all recent items
    func loadRecentItems() async {
        logger.info("📦 Loading recent items")
        print("📦 Loading recent items...")
        
        isLoading = true
        
        do {
            let items = try await repository.fetchRecentItems()
            recentItems = items
            
            logger.info("✅ Loaded \(items.count) recent items")
            print("✅ Loaded \(items.count) recent items")
        } catch {
            logger.error("❌ Failed to load recent items: \(error.localizedDescription)")
            print("❌ Error loading recent items: \(error)")
            recentItems = []
        }
        
        isLoading = false
    }
    
    /// Clear all recent items
    func clearRecentItems() async {
        logger.info("🗑️ Clearing all recent items")
        print("🗑️ Clearing recent items...")
        
        do {
            try await repository.clearRecentItems()
            recentItems = []
            
            // Provide haptic feedback on iOS
            #if os(iOS)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            #endif
            
            logger.info("✅ Recent items cleared")
            print("✅ Recent items cleared")
        } catch {
            logger.error("❌ Failed to clear recent items: \(error.localizedDescription)")
            print("❌ Error clearing recent items: \(error)")
        }
    }
    
    /// Get count of recent items for display
    var recentsCount: Int {
        recentItems.count
    }
    
    /// Check if recent items list is empty
    var isEmpty: Bool {
        recentItems.isEmpty
    }
    
    /// Get most recently viewed item
    var mostRecentItem: Item? {
        recentItems.first
    }
    
    /// Get recent items limited to a specific count
    func getRecentItems(limit: Int) -> [Item] {
        Array(recentItems.prefix(limit))
    }
}
