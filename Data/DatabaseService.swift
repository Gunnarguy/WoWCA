// Data/DatabaseService.swift
import Foundation
import GRDB

@MainActor
final class DatabaseService {
    static let shared = DatabaseService()
    private(set) var dbQueue: DatabaseQueue!

    private init() {}

    func configure() throws {
        // Single canonical DB name used by the app. Remove other .sqlite variants to avoid confusion.
        let dbFileName = "items.sqlite"  // canonical bundled DB
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let targetURL = appSupport.appendingPathComponent(dbFileName)

        if !fm.fileExists(atPath: targetURL.path) {
            guard let bundled = Bundle.main.url(forResource: "items", withExtension: "sqlite")
            else {
                throw NSError(
                    domain: "DB", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Bundled items.sqlite not found in app bundle"
                    ])
            }
            try fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
            try fm.copyItem(at: bundled, to: targetURL)
            print("[DB] Copied bundled \(dbFileName) -> \(targetURL.path)")
        } else {
            print("[DB] Using existing cached \(dbFileName) at \(targetURL.path)")
        }

        var config = Configuration()
        config.readonly = true
        dbQueue = try DatabaseQueue(path: targetURL.path, configuration: config)
        print("[DB] Opened database (readonly) at: \(targetURL.path)")
    }
}
