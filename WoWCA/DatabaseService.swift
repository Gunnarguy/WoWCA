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
        print("🗄️ DatabaseService singleton initialized")
    }

    func configure() throws {
        logger.info("🔧 DatabaseService.configure() called")
        print("🔧 Starting database configuration...")

        configureLock.lock()
        defer {
            configureLock.unlock()
            print("🔓 Database configuration lock released")
        }

        guard !isConfigured else {
            logger.info("⚠️ Database already configured, skipping")
            print("⚠️ Database already configured, returning early")
            return
        }

        let dbFileName = "items.sqlite"  // canonical bundled DB
        logger.info("📁 Target database filename: \(dbFileName)")
        print("📁 Looking for database file: \(dbFileName)")

        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let targetURL = appSupport.appendingPathComponent(dbFileName)

        logger.info("📂 Application Support directory: \(appSupport.path)")
        logger.info("🎯 Target database path: \(targetURL.path)")
        print("📂 Application Support: \(appSupport.path)")
        print("🎯 Target database: \(targetURL.path)")

        guard let bundled = Bundle.main.url(forResource: "items", withExtension: "sqlite")
        else {
            let error = NSError(
                domain: "DB", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Bundled items.sqlite not found in app bundle"
                ])
            logger.error("❌ Bundled database not found in app bundle")
            print("❌ FATAL: Bundled items.sqlite not found in app bundle")
            throw error
        }

        logger.info("📦 Found bundled database at: \(bundled.path)")
        print("📦 Bundled DB path: \(bundled.path)")
        let bundledSize =
            (try? FileManager.default.attributesOfItem(atPath: bundled.path))?[.size] as? Int64
            ?? 0
        logger.info("📏 Bundled database size: \(bundledSize) bytes")
        print("📦 Bundled DB size: \(bundledSize) bytes")

        do {
            try fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
            logger.info("✅ Application Support directory created/verified")
            print("✅ Application Support directory ready")
        } catch {
            logger.error(
                "❌ Failed to create Application Support directory: \(error.localizedDescription)")
            print("❌ Failed to create Application Support directory: \(error)")
            throw error
        }

        // Always remove any existing cached database and copy fresh from bundle
        if fm.fileExists(atPath: targetURL.path) {
            logger.info("🗑️ Removing existing database file")
            print("🗑️ Removing existing database file...")
            try fm.removeItem(at: targetURL)
            logger.info("✅ Existing database file removed")
            print("✅ Existing database removed")
        }

        logger.info("📋 Copying database from bundle to Application Support...")
        print("📋 Copying fresh database from bundle...")
        try fm.copyItem(at: bundled, to: targetURL)
        logger.info("✅ Database copied successfully")
        print("📂 Copied fresh bundled \(dbFileName) -> \(targetURL.path)")

        self.dbFileURL = targetURL

        logger.info("⚙️ Configuring GRDB database queue...")
        print("⚙️ Setting up GRDB configuration...")
        var config = Configuration()
        config.readonly = true
        config.prepareDatabase { db in
            print("🔧 GRDB prepareDatabase callback executing...")
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
            print("✅ PRAGMA journal_mode = DELETE executed")
        }

        logger.info("🔌 Opening database connection...")
        print("🔌 Opening database connection...")
        dbQueue = try DatabaseQueue(path: targetURL.path, configuration: config)
        logger.info("✅ Database queue created successfully")
        print("✅ Database connection established")

        // Verify the database has correct data
        logger.info("🔍 Verifying database contents...")
        print("🔍 Verifying database contents...")
        let itemCount = try dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items") ?? 0
            print("📊 Items table query executed, found \(count) items")
            return count
        }
        let ftsCount = try dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items_fts") ?? 0
            print("🔎 FTS table query executed, found \(count) entries")
            return count
        }

        logger.info("📊 Database verification complete: \(itemCount) items, \(ftsCount) FTS entries")
        print("🗃️ Database loaded: \(itemCount) items, \(ftsCount) FTS entries")
        print("[DB] Opened database (readonly) at: \(targetURL.path)")

        isConfigured = true
        logger.info("🏁 Database configuration completed successfully")
        print("🏁 Database configuration complete!")
    }
}
