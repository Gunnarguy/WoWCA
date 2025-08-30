// RecentsView.swift
// View for displaying recently viewed items

import SwiftUI
import GRDB
import os.log

struct RecentsView: View {
    @Bindable var recentsManager: RecentsManager
    
    // Logger for recents UI events
    private let logger = Logger(subsystem: "com.wowca.app", category: "RecentsUI")
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Recent")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !recentsManager.isEmpty {
                            Button("Clear", systemImage: "trash") {
                                Task {
                                    await recentsManager.clearRecentItems()
                                }
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
                .onAppear {
                    logger.info("🕒 RecentsView appeared")
                    print("🕒 RecentsView appeared")
                    Task {
                        await recentsManager.loadRecentItems()
                    }
                }
                .onDisappear {
                    logger.info("👋 RecentsView disappeared")
                    print("👋 RecentsView disappeared")
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if recentsManager.isLoading {
            loadingView
        } else if recentsManager.isEmpty {
            emptyStateView
        } else {
            recentsListView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading recent items...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            logger.info("⏳ Recent items loading state appeared")
            print("⏳ Loading recent items...")
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Recent Items", systemImage: "clock")
        } description: {
            Text("Items you view will appear here for quick access. Start by searching for an item.")
        }
        .onAppear {
            logger.info("📭 Empty recent items state appeared")
            print("📭 No recent items to display")
        }
    }
    
    private var recentsListView: some View {
        List {
            Section {
                ForEach(recentsManager.recentItems) { item in
                    NavigationLink(value: item) {
                        ItemRowView(item: item)
                            .onAppear {
                                logger.info("👁️ Recent item row appeared: [\(item.entry)] \(item.name)")
                                print("👁️ Showing recent: [\(item.entry)] \(item.name)")
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Recently Viewed")
                    Spacer()
                    if recentsManager.recentsCount > 0 {
                        Text("\(recentsManager.recentsCount)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationDestination(for: Item.self) { item in
            ItemDetailViewEnhanced(item: item)
                .environment(recentsManager)
                .onAppear {
                    logger.info("📱 ItemDetailViewEnhanced appeared from recents for: [\(item.entry)] \(item.name)")
                    print("📱 Detail view opened from recents: [\(item.entry)] \(item.name)")
                    
                    // Add to recent items when viewed
                    Task {
                        await recentsManager.addToRecent(item: item)
                    }
                }
        }
        .onAppear {
            logger.info("📋 Recent items list appeared with \(recentsManager.recentsCount) items")
            print("📋 Recent items list showing \(recentsManager.recentsCount) items")
        }
        .refreshable {
            await recentsManager.loadRecentItems()
        }
    }
}

#if DEBUG
struct RecentsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock recents manager for preview
        let mockRepository = ItemRepository(dbQueue: try! DatabaseQueue())
        let mockManager = RecentsManager(repository: mockRepository)
        
        RecentsView(recentsManager: mockManager)
    }
}
#endif
