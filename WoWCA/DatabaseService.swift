// Data/DatabaseService.swift
import Foundation
import GRDB
import os.log

/// Singleton responsible for provisioning the bundled database into
/// Application Support. Not main-actor isolated to avoid forcing
/// synchronous hops when accessed from background tasks. Query usage is
/// funneled through `ItemRepository` actor.
final class DatabaseService {
    static let shared = DatabaseService()
    private(set) var dbQueue: DatabaseQueue!
    private(set) var dbFileURL: URL?
    private let configureLock = NSLock()
    private var isConfigured = false

    // Logger for database operations
    private let logger = Logger(subsystem: "com.wowca.app", category: "Database")

    private init() {
        logger.info("🗄️ DatabaseService singleton created")
    }

    func configure() throws {
        logger.info("🔧 DatabaseService.configure() called")

        configureLock.lock()
        defer {
            configureLock.unlock()
        }

        guard !isConfigured else {
            logger.info("⚠️ Database already configured, skipping")
            return
        }

        let dbFileName = "items.sqlite"  // canonical bundled DB
        logger.info("📁 Target database filename: \(dbFileName)")

        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let targetURL = appSupport.appendingPathComponent(dbFileName)

        logger.info("📂 Application Support directory: \(appSupport.path)")
        logger.info("🎯 Target database path: \(targetURL.path)")

        guard let bundled = Bundle.main.url(forResource: "items", withExtension: "sqlite")
        else {
            let error = NSError(
                domain: "DB", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Bundled items.sqlite not found in app bundle"
                ])
            logger.error("❌ Bundled database not found in app bundle")
            throw error
        }

        logger.info("📦 Found bundled database at: \(bundled.path)")
        let bundledSize =
            (try? FileManager.default.attributesOfItem(atPath: bundled.path))?[.size] as? Int64
            ?? 0
        logger.info("📏 Bundled database size: \(bundledSize) bytes")

        do {
            try fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
            logger.info("✅ Application Support directory created/verified")
        } catch {
            logger.error(
                "❌ Failed to create Application Support directory: \(error.localizedDescription)")
            throw error
        }

                // Only copy database if it doesn't exist (preserve user data)
        if !fm.fileExists(atPath: targetURL.path) {
            logger.info("� First launch: Copying database from bundle to Application Support...")
            try fm.copyItem(at: bundled, to: targetURL)
            logger.info("✅ Database copied successfully")
        } else {
            logger.info("� Using existing database with user data")
        }

        // Verify database file size
        let finalSize = (try? FileManager.default.attributesOfItem(atPath: targetURL.path))?[.size] as? Int64 ?? 0
        logger.info("📏 Final database size: \(finalSize) bytes")

        self.dbFileURL = targetURL

        logger.info("⚙️ Configuring GRDB database queue...")
        var config = Configuration()
        // Don't set readonly=true since we need to support favorites/recents tables
        config.prepareDatabase { [self] db in
            #if DEBUG
            logger.debug("🔧 GRDB prepareDatabase callback executing...")
            #endif
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
            #if DEBUG
            logger.debug("✅ PRAGMA journal_mode = DELETE executed")
            #endif
        }

        logger.info("🔌 Opening database connection with read/write access...")
        dbQueue = try DatabaseQueue(path: targetURL.path, configuration: config)
        logger.info("✅ Database queue created successfully")

        // Setup database migrations for user data tables
        try setupMigrations()

        // Verify the database has correct data
        logger.info("🔍 Verifying database contents...")
        let itemCount = try dbQueue.read { [self] db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items") ?? 0
            #if DEBUG
            logger.debug("📊 Items table query executed, found \(count) items")
            #endif
            return count
        }
        let ftsCount = try dbQueue.read { [self] db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items_fts") ?? 0
            #if DEBUG
            logger.debug("🔎 FTS table query executed, found \(count) entries")
            #endif
            return count
        }

        logger.info("📊 Database verification complete: \(itemCount) items, \(ftsCount) FTS entries")

        isConfigured = true
        logger.info("🏁 Database configuration completed successfully")
    }

    /// Setup database migrations for user data tables
    private func setupMigrations() throws {
        var migrator = DatabaseMigrator()
        
        // v1.0 -> v1.1: Add favorites table
        migrator.registerMigration("create_favorites") { [self] db in
            logger.info("🔄 Creating favorites table...")
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS favorites (
                    item_id INTEGER PRIMARY KEY,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)
            logger.info("✅ Favorites table created")
        }
        
        // v1.1 -> v1.2: Add recent items table  
        migrator.registerMigration("create_recent_items") { [self] db in
            logger.info("🔄 Creating recent items table...")
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS recent_items (
                    item_id INTEGER PRIMARY KEY,
                    accessed_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)
            logger.info("✅ Recent items table created")
        }
        
        logger.info("🚀 Running database migrations...")
        try migrator.migrate(dbQueue)
        logger.info("✅ All migrations completed successfully")
    }
}
