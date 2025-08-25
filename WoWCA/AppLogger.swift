//
//  AppLogger.swift
//  WoWCA
//
//  Comprehensive logging utility for debugging and monitoring
//

import Foundation
import os.log

/// Centralized logging utility for the WoW Classic App
/// Provides both unified logger instances and convenience methods
struct AppLogger {

    // MARK: - Logger Instances
    static let app = Logger(subsystem: "com.wowca.app", category: "App")
    static let database = Logger(subsystem: "com.wowca.app", category: "Database")
    static let search = Logger(subsystem: "com.wowca.app", category: "Search")
    static let ui = Logger(subsystem: "com.wowca.app", category: "UI")
    static let repository = Logger(subsystem: "com.wowca.app", category: "Repository")
    static let detail = Logger(subsystem: "com.wowca.app", category: "ItemDetail")
    static let navigation = Logger(subsystem: "com.wowca.app", category: "Navigation")

    // MARK: - Convenience Methods

    /// Log and print an info message
    static func info(_ message: String, category: LogCategory = .app) {
        let logger = logger(for: category)
        logger.info("\(message)")
        print("ℹ️ \(message)")
    }

    /// Log and print an error message
    static func error(_ message: String, category: LogCategory = .app) {
        let logger = logger(for: category)
        logger.error("\(message)")
        print("❌ \(message)")
    }

    /// Log and print a debug message (only in DEBUG builds)
    static func debug(_ message: String, category: LogCategory = .app) {
        #if DEBUG
            let logger = logger(for: category)
            logger.debug("\(message)")
            print("🐛 \(message)")
        #endif
    }

    /// Log detailed function entry with parameters
    static func enter(
        _ function: String = #function, file: String = #file, line: Int = #line,
        category: LogCategory = .app
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let message = "🔵 ENTER \(function) [\(fileName):\(line)]"
        let logger = logger(for: category)
        logger.info("\(message)")
        print(message)
    }

    /// Log detailed function exit
    static func exit(
        _ function: String = #function, file: String = #file, line: Int = #line,
        category: LogCategory = .app
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let message = "🔴 EXIT \(function) [\(fileName):\(line)]"
        let logger = logger(for: category)
        logger.info("\(message)")
        print(message)
    }

    /// Log performance timing
    static func timing(_ message: String, duration: TimeInterval, category: LogCategory = .app) {
        let formattedDuration = String(format: "%.3f", duration)
        let fullMessage = "⏱️ \(message): \(formattedDuration)s"
        let logger = logger(for: category)
        logger.info("\(fullMessage)")
        print(fullMessage)
    }

    /// Log user interaction events
    static func userAction(_ action: String, category: LogCategory = .ui) {
        let message = "👆 USER: \(action)"
        let logger = logger(for: category)
        logger.info("\(message)")
        print(message)
    }

    /// Log data/state changes
    static func stateChange(_ description: String, category: LogCategory = .app) {
        let message = "🔄 STATE: \(description)"
        let logger = logger(for: category)
        logger.info("\(message)")
        print(message)
    }

    /// Log API/Database operations
    static func operation(_ description: String, category: LogCategory = .database) {
        let message = "🔧 OP: \(description)"
        let logger = logger(for: category)
        logger.info("\(message)")
        print(message)
    }

    // MARK: - Private Helpers

    private static func logger(for category: LogCategory) -> Logger {
        switch category {
        case .app: return app
        case .database: return database
        case .search: return search
        case .ui: return ui
        case .repository: return repository
        case .detail: return detail
        case .navigation: return navigation
        }
    }
}

/// Categories for different types of logging
enum LogCategory {
    case app
    case database
    case search
    case ui
    case repository
    case detail
    case navigation
}

// MARK: - Performance Timing Helper

/// Helper for timing operations
struct PerformanceTimer {
    private let startTime: Date
    private let operation: String
    private let category: LogCategory

    init(_ operation: String, category: LogCategory = .app) {
        self.operation = operation
        self.category = category
        self.startTime = Date()
        AppLogger.info("⏱️ START: \(operation)", category: category)
    }

    func end() {
        let duration = Date().timeIntervalSince(startTime)
        AppLogger.timing(operation, duration: duration, category: category)
    }
}

// MARK: - Extensions for easier logging

extension String {
    /// Quick logging helpers
    func logInfo(category: LogCategory = .app) {
        AppLogger.info(self, category: category)
    }

    func logError(category: LogCategory = .app) {
        AppLogger.error(self, category: category)
    }

    func logDebug(category: LogCategory = .app) {
        AppLogger.debug(self, category: category)
    }
}
