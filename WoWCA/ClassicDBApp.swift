//
//  ClassicDBApp.swift
//  ClassicDB
//
//  Created by Gunnar Hostetler on 8/13/25.
//

import SwiftUI
import os.log

@main
struct ClassicDBApp: App {
    @State private var vm: ItemSearchViewModel?
    @State private var favoritesManager: FavoritesManager?
    @State private var recentsManager: RecentsManager?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Logger for app lifecycle events
    private let logger = Logger(subsystem: "com.wowca.app", category: "AppLifecycle")

    init() {
        logger.info("🚀 ClassicDBApp initializing...")

        // Enable detailed Core Data logging if needed
        #if DEBUG
            logger.debug("🔧 DEBUG mode enabled - verbose logging active")
            #if os(iOS)
            logger.debug("📱 Device: \(UIDevice.current.model)")
            logger.debug("📱 iOS Version: \(UIDevice.current.systemVersion)")
            #endif
            logger.debug("📱 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
            logger.debug(
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

            logger.info("⭐ Initializing FavoritesManager...")
            _favoritesManager = State(initialValue: FavoritesManager(repository: repo))
            logger.info("✅ FavoritesManager initialized successfully")

            logger.info("🕒 Initializing RecentsManager...")
            _recentsManager = State(initialValue: RecentsManager(repository: repo))
            logger.info("✅ RecentsManager initialized successfully")

        } catch {
            logger.error("❌ App initialization failed: \(error.localizedDescription)")
            #if DEBUG
            logger.debug("❌ DB init failed: \(error)")
            logger.debug("❌ Error details: \(String(describing: error))")
            #endif
        }

        logger.info("🏁 WoWCAApp initialization complete")
    }

    var body: some Scene {
        WindowGroup {
            if let vm, let favoritesManager, let recentsManager {
                RootView(
                    vm: vm,
                    favoritesManager: favoritesManager,
                    recentsManager: recentsManager
                )
                .sheet(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView()
                        .interactiveDismissDisabled()
                }
                .onAppear {
                    logger.info("🖼️ Presenting main UI with view model")
                    logger.info("🎬 Main UI appeared")
                    #if DEBUG
                    logger.debug("🔧 App lifecycle: FOREGROUND_ACTIVE")
                    #endif
                }
                .onDisappear {
                    logger.info("👋 Main UI disappeared")
                    #if DEBUG
                    logger.debug("🔧 App lifecycle: BACKGROUND")
                    #endif
                }
            } else {
                DatabaseErrorView()
                    .onAppear {
                        logger.error("❌ Showing error state - no view model available")
                        #if DEBUG
                        logger.debug("🔧 App state: ERROR - Database initialization failed")
                        #endif
                    }
            }
        }
    }
}
