// UI/SearchView.swift
import SwiftUI
import os.log

// Forward declaration ensures AboutView symbol is visible to previews even if file ordering changes.
@available(*, unavailable)
private struct _AboutView_ForwardDecl: View { var body: some View { EmptyView() } }

struct SearchView: View {
    @Bindable var vm: ItemSearchViewModel

    // Logger for UI events
    private let logger = Logger(subsystem: "com.wowca.app", category: "SearchUI")

    var body: some View {
        NavigationStack {
            Group {
                if vm.query.isEmpty {
                    ContentUnavailableView(
                        "Search items", systemImage: "magnifyingglass",
                        description: Text("Type at least 1 character")
                    )
                    .onAppear {
                        logger.info("🔍 Empty state view appeared")
                        print("🔍 Showing empty search state")
                    }
                } else if vm.isSearching {
                    ProgressView()
                        .controlSize(.large)
                        .onAppear {
                            logger.info("⏳ Loading state view appeared")
                            print("⏳ Showing search loading state")
                        }
                } else if vm.results.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "exclamationmark.magnifyingglass",
                        description: Text("No matches for \"\(vm.query)\"")
                    )
                    .onAppear {
                        logger.info("📭 No results state view appeared for query: '\(vm.query)'")
                        print("📭 Showing no results state for: '\(vm.query)'")
                    }
                } else {
                    List(vm.results) { item in
                        NavigationLink(value: item) {
                            ItemRowView(item: item)
                                .onAppear {
                                    print("👁️ Item row appeared: [\(item.entry)] \(item.name)")
                                }
                        }
                        .onTapGesture {
                            logger.info("👆 User tapped item: [\(item.entry)] \(item.name)")
                            print("👆 User tapped item: [\(item.entry)] \(item.name)")
                        }
                    }
                    .navigationDestination(for: Item.self) { item in
                        ItemDetailViewEnhanced(item: item)
                            .onAppear {
                                logger.info(
                                    "📱 ItemDetailViewEnhanced appeared for: [\(item.entry)] \(item.name)")
                                print("📱 Detail view opened: [\(item.entry)] \(item.name)")
                            }
                            .onDisappear {
                                logger.info(
                                    "👋 ItemDetailViewEnhanced disappeared for: [\(item.entry)] \(item.name)"
                                )
                                print("👋 Detail view closed: [\(item.entry)] \(item.name)")
                            }
                    }
                    .onAppear {
                        logger.info("📋 Results list appeared with \(vm.results.count) items")
                        print("📋 Results list showing \(vm.results.count) items")
                    }
                }
            }
            .navigationTitle("Classic Items")
            .onAppear {
                logger.info("🏠 SearchView appeared")
                print("🏠 SearchView appeared")
            }
            .onDisappear {
                logger.info("👋 SearchView disappeared")
                print("👋 SearchView disappeared")
            }
            .searchable(text: $vm.query, prompt: "Search by name")
            .onChange(of: vm.query) { oldValue, newValue in
                logger.info("📝 Search text changed from '\(oldValue)' to '\(newValue)'")
                print("📝 Search input: '\(oldValue)' -> '\(newValue)'")
                vm.updateQuery(newValue)
            }
        }
        .onAppear {
            logger.info("🔍 SearchView with NavigationStack appeared")
            print("🔍 Main search interface loaded")
        }
    }
}
