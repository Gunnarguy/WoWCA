//
//  WoWCAApp.swift
//  WoWCA
//
//  Created by Gunnar Hostetler on 8/13/25.
//

import SwiftUI
import os.log

@main
struct WoWCAApp: App {
    @State private var vm: ItemSearchViewModel?

    // Logger for app lifecycle events
    private let logger = Logger(subsystem: "com.wowca.app", category: "AppLifecycle")

    init() {
        logger.info("🚀 WoWCAApp initializing...")

        // Enable detailed Core Data logging if needed
        #if DEBUG
            print("🔧 DEBUG mode enabled - verbose logging active")
            print("📱 Device: \(UIDevice.current.model)")
            print("📱 iOS Version: \(UIDevice.current.systemVersion)")
            print("📱 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
            print(
                "📱 App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")"
            )
        #endif

        do {
            logger.info("🗄️ Configuring database service...")
            try DatabaseService.shared.configure()
            logger.info("✅ Database service configured successfully")

            logger.info("🏗️ Creating ItemRepository...")
            let repo = ItemRepository(dbQueue: DatabaseService.shared.dbQueue)
            logger.info("✅ ItemRepository created successfully")

            logger.info("🔍 Initializing ItemSearchViewModel...")
            _vm = State(initialValue: ItemSearchViewModel(repository: repo))
            logger.info("✅ ItemSearchViewModel initialized successfully")

        } catch {
            logger.error("❌ App initialization failed: \(error.localizedDescription)")
            print("❌ DB init failed: \(error)")
            print("❌ Error details: \(String(describing: error))")
        }

        logger.info("🏁 WoWCAApp initialization complete")
    }

    var body: some Scene {
        WindowGroup {
            if let vm {
                RootView(vm: vm)
                    .onAppear {
                        logger.info("🖼️ Presenting main UI with view model")
                        logger.info("🎬 Main UI appeared")
                        print("🖼️ Presenting main UI with view model")
                        print("🎬 RootView appeared - app is ready for user interaction")
                        print("🔧 App lifecycle: FOREGROUND_ACTIVE")
                    }
                    .onDisappear {
                        logger.info("👋 Main UI disappeared")
                        print("👋 RootView disappeared")
                        print("🔧 App lifecycle: BACKGROUND")
                    }
            } else {
                Text("Database failed to load")
                    .padding()
                    .onAppear {
                        logger.error("❌ Showing error state - no view model available")
                        print("❌ Error view appeared - database failed to load")
                        print("🔧 App state: ERROR - Database initialization failed")
                    }
            }
        }
    }
}
