// Data/DatabaseService.swift
import Foundation
import GRDB

@MainActor
final class DatabaseService {
    static let shared = DatabaseService()
    private(set) var dbQueue: DatabaseQueue!

    private init() {}

    func configure() throws {
        let dbFileName = "items.sqlite"  // canonical bundled DB
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let targetURL = appSupport.appendingPathComponent(dbFileName)

        guard let bundled = Bundle.main.url(forResource: "items", withExtension: "sqlite")
        else {
            throw NSError(
                domain: "DB", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Bundled items.sqlite not found in app bundle"
                ])
        }

        print("📦 Bundled DB path: \(bundled.path)")
        let bundledSize =
            (try? FileManager.default.attributesOfItem(atPath: bundled.path))?[.size] as? Int64 ?? 0
        print("📦 Bundled DB size: \(bundledSize) bytes")

        try fm.createDirectory(at: appSupport, withIntermediateDirectories: true)

        // Always remove any existing cached database and copy fresh from bundle
        if fm.fileExists(atPath: targetURL.path) {
            try fm.removeItem(at: targetURL)
        }
        try fm.copyItem(at: bundled, to: targetURL)
        print("📂 Copied fresh bundled \(dbFileName) -> \(targetURL.path)")

        var config = Configuration()
        config.readonly = true
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
        }
        dbQueue = try DatabaseQueue(path: targetURL.path, configuration: config)

        // Verify the database has correct data
        let itemCount = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items") ?? 0
        }
        let ftsCount = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items_fts") ?? 0
        }
        print("🗃️ Database loaded: \(itemCount) items, \(ftsCount) FTS entries")
        print("[DB] Opened database (readonly) at: \(targetURL.path)")
    }
}
