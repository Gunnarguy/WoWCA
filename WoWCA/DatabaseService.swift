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

        try fm.createDirectory(at: appSupport, withIntermediateDirectories: true)

        // Always remove any existing cached database and copy fresh from bundle
        if fm.fileExists(atPath: targetURL.path) {
            try fm.removeItem(at: targetURL)
        }
        try fm.copyItem(at: bundled, to: targetURL)
        print("[DB] Copied fresh bundled \(dbFileName) -> \(targetURL.path)")

        var config = Configuration()
        config.readonly = true
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = DELETE")
        }
        dbQueue = try DatabaseQueue(path: targetURL.path, configuration: config)
        print("[DB] Opened database (readonly) at: \(targetURL.path)")
    }
}
