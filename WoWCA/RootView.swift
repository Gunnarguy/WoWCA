// UI/RootView.swift
// Main entry container providing tab navigation so About/Privacy is visible immediately.

import SwiftUI
import os.log

struct RootView: View {
    @Bindable var vm: ItemSearchViewModel

    // Logger for navigation events
    private let logger = Logger(subsystem: "com.wowca.app", category: "Navigation")

    var body: some View {
        TabView {
            SearchView(vm: vm)
                .tabItem {
                    Label("Items", systemImage: "magnifyingglass")
                }
                .onAppear {
                    logger.info("🔍 Items tab appeared")
                    print("🔍 Items tab selected")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .onAppear {
                    logger.info("ℹ️ About tab appeared")
                    print("ℹ️ About tab selected")
                }
        }
        .onAppear {
            logger.info("📱 RootView TabView appeared")
            print("📱 Main tab interface loaded")
        }
        .onDisappear {
            logger.info("👋 RootView TabView disappeared")
            print("👋 Main tab interface unloaded")
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
