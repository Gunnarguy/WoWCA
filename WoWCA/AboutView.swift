// UI/AboutView.swift
// Enhanced styled About / Privacy / Transparency screen.

import Foundation
import SwiftUI

#if canImport(CryptoKit)
    import CryptoKit
#endif

#if canImport(GRDB)
    import GRDB
#endif

struct AboutView: View {
    // MARK: - Derived App Metadata
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }

    private var appDisplayName: String {
        if let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
            !display.isEmpty
        {
            return display
        }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
            !name.isEmpty
        {
            return name
        }
        return "App"
    }

    private var privacyURL: String { "https://gunnarguy.github.io/WoWCA/privacy" }

    // MARK: - Body
    // MARK: - Runtime Stats State
    @State private var itemCount: Int? = nil
    @State private var ftsCount: Int? = nil
    @State private var versionRow: [String: String] = [:]
    @State private var statsError: String? = nil
    // Additional nerd stats
    @State private var spellCount: Int? = nil
    @State private var itemsWithSpellCount: Int? = nil
    @State private var linkedSpellRefs: Int? = nil
    @State private var distinctSpellRefs: Int? = nil
    @State private var itemsWithSpellPercent: Double? = nil
    // Deep stats
    @State private var tableCounts: [(String, Int)] = []
    @State private var qualityCounts: [(Int, Int)] = []
    @State private var patchCounts: [(Int, Int)] = []
    @State private var itemLevelRange: (min: Int, max: Int, avg: Double)? = nil
    @State private var medianItemLevel: Int? = nil
    @State private var topSpellRefs: [(Int, Int)] = []  // (spellId, count)
    @State private var deepStatsError: String? = nil
    @State private var deepStatsLoaded: Bool = false
    @State private var dbFileSizeBytes: Int64? = nil
    @State private var dbCompressionEstimate: Double? = nil
    @State private var ftsMismatch: Bool = false
    @State private var dbHashShort: String? = nil
    @State private var diagnosticsText: String = ""
    @State private var showShareSheet: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroHeader
                Group {
                    InfoCard(title: "Overview", systemImage: "info.circle.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                "Offline Classic Era item & spell reference. Everything ships inside one signed bundle: no servers, no trackers, no ads."
                            )
                            if let i = itemCount { statLine(label: "Indexed Items", value: "\(i)") }
                            if let snapshot = snapshotDateDisplay {
                                statLine(label: "Snapshot Date", value: snapshot)
                            }
                            if let sc = spellCount {
                                statLine(
                                    label: "Spells Table", value: sc > 0 ? "Present" : "Missing")
                            }
                        }
                    }
                    InfoCard(title: "Data Sources", systemImage: "tray.full.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                "Data derived from publicly available community Classic data exports vendored in-repo as a frozen snapshot."
                            )
                            if let commit = versionRowCommitShort {
                                statLine(label: "Source Commit", value: commit)
                            }
                            Text(
                                "No proprietary art or assets included; only structured item + spell fields."
                            )
                        }
                    }
                    InfoCard(title: "Build & Provenance", systemImage: "shippingbox.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                "Deterministic script (`items_build.sh`) produces the SQLite + FTS5 database. Re-run locally to reproduce this build bit‑for‑bit (same input snapshot → same output hash)."
                            )
                            if let commit = versionRowCommitShort {
                                statLine(label: "Source Commit", value: commit)
                            }
                            if let hash = dbHashShort {
                                statLine(label: "DB Hash", value: hash)
                            }
                        }
                    }
                    legalDisclaimerSection
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .background(
            ZStack {
                backgroundGradient.ignoresSafeArea()
                noiseOverlay.blendMode(.overlay).allowsHitTesting(false).accessibilityHidden(true)
            }
        )
        .navigationTitle("About")
        #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await loadStats() }
        #if os(iOS)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [diagnosticsText])
            }
        #endif
    }

    // MARK: - Subviews
    private var heroHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(#colorLiteral(red: 0.18, green: 0.24, blue: 0.55, alpha: 1)),
                                Color(#colorLiteral(red: 0.48, green: 0.19, blue: 0.66, alpha: 1)),
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        AngularGradient(
                            colors: [Color.white.opacity(0.25), .clear, Color.white.opacity(0.05)],
                            center: .center
                        )
                        .blendMode(.overlay)
                        .mask(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .frame(width: 116, height: 116)
                    .shadow(color: Color.black.opacity(0.35), radius: 16, y: 10)
                appIconVisual
            }
            Text(appDisplayName)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.accentColor.opacity(0.9)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .primary.opacity(0.12), radius: 4, y: 2)
            Text("\(appVersion) • \(platformString())")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var legalDisclaimerSection: some View {
        InfoCard(title: "Legal Disclaimer", systemImage: "gavel.fill") {
            Text(
                "World of Warcraft ©2004 Blizzard Entertainment, Inc. All rights reserved. World of Warcraft, Warcraft and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. in the U.S. and/or other countries. This is an unofficial fan-made application and is not affiliated with or endorsed by Blizzard Entertainment."
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private func statLine(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption.monospaced())
            Spacer()
            Text(value).font(.caption)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(label.replacingOccurrences(of: "w/", with: "with")))
        .accessibilityValue(Text(value))
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Divider().opacity(0.3)
            Text("© \(currentYear()) Gunndamental. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var backgroundGradient: LinearGradient {
        #if canImport(UIKit)
            let base = Color(UIColor.systemBackground)
            let secondary = Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
            let base = Color(nsColor: NSColor.windowBackgroundColor)
            let secondary = Color(nsColor: NSColor.controlBackgroundColor)
        #else
            let base = Color.black
            let secondary = Color.gray.opacity(0.2)
        #endif
        return LinearGradient(colors: [base, secondary], startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Helpers
    private func currentYear() -> String {
        return String(Calendar.current.component(.year, from: Date()))
    }

    private func platformString() -> String {
        #if os(iOS)
            return "iOS"
        #elseif os(macOS)
            return "macOS"
        #elseif os(visionOS)
            return "visionOS"
        #else
            return "Unknown"
        #endif
    }

    private func byteString(_ bytes: Int64) -> String {
        let units: [String] = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var i = 0
        while value >= 1024 && i < units.count - 1 {
            value /= 1024
            i += 1
        }
        return String(format: i == 0 ? "%.0f %@" : "%.2f %@", value, units[i])
    }

    private func patchVersionName(for id: Int) -> String {
        switch id {
        case 0: return "1.0 (Release)"
        case 1: return "1.1 (WoW Launch)"
        case 2: return "1.2 (Mysteries of Maraudon)"
        case 3: return "1.3 (Ruins of the Dire Maul)"
        case 4: return "1.4 (The Call to War)"
        case 5: return "1.5 (Battlegrounds)"
        case 6: return "1.6 (Assault on Blackwing Lair)"
        case 7: return "1.7 (Rise of the Blood God)"
        case 8: return "1.8 (Dragons of Nightmare)"
        case 9: return "1.9 (The Gates of Ahn'Qiraj)"
        case 10: return "1.10 (Storms of Azeroth)"
        case 11: return "1.11 (Shadow of the Necropolis)"
        case 12: return "1.12 (Drums of War)"
        default: return "Patch \(id)"
        }
    }

    private func qualityName(for id: Int) -> String {
        switch id {
        case 0: return "Poor"
        case 1: return "Common"
        case 2: return "Uncommon"
        case 3: return "Rare"
        case 4: return "Epic"
        case 5: return "Legendary"
        case 6: return "Artifact"
        case 7: return "Heirloom"
        default: return "Unknown"
        }
    }

    private func qualityColor(for id: Int) -> Color {
        switch id {
        case 0: return .gray
        case 1: return .primary
        case 2: return .green
        case 3: return .blue
        case 4: return .purple
        case 5: return .orange
        case 6: return .red
        case 7: return .yellow
        default: return .secondary
        }
    }

    // MARK: - Load Stats
    private func loadStats() async {
        #if canImport(GRDB)
            guard let queue = DatabaseService.shared.dbQueue else { return }
            do {
                let (i, f, row, scOpt, iw, ls, ds, pageCount, freeList, pageSize) =
                    try await queue.read {
                        db -> (Int, Int, [String: String], Int?, Int, Int, Int, Int, Int, Int) in
                        let i = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items") ?? 0
                        let f = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items_fts") ?? 0
                        var dict: [String: String] = [:]
                        if let r = try Row.fetchOne(db, sql: "SELECT * FROM data_version LIMIT 1") {
                            for name in r.columnNames {
                                // Row subscripting returns a DatabaseValueConvertible?; stringify or mark NULL
                                if let anyValue = r[name] as (any DatabaseValueConvertible)? {
                                    dict[name] = String(describing: anyValue)
                                } else {
                                    dict[name] = "NULL"
                                }
                            }
                        }
                        // Only query spells table if it exists in this build of the DB
                        let spellsTableExists =
                            try Bool.fetchOne(
                                db,
                                sql:
                                    "SELECT 1 FROM sqlite_master WHERE type='table' AND name='spells' LIMIT 1"
                            ) ?? false
                        let sc: Int? =
                            spellsTableExists
                            ? (try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM spells") ?? 0) : nil
                        let iw =
                            try Int.fetchOne(
                                db,
                                sql:
                                    "SELECT COUNT(*) FROM items WHERE spellid_1 IS NOT NULL OR spellid_2 IS NOT NULL OR spellid_3 IS NOT NULL OR spellid_4 IS NOT NULL OR spellid_5 IS NOT NULL"
                            ) ?? 0
                        let ls =
                            try Int.fetchOne(
                                db,
                                sql:
                                    "SELECT (COUNT(spellid_1)+COUNT(spellid_2)+COUNT(spellid_3)+COUNT(spellid_4)+COUNT(spellid_5)) FROM items"
                            ) ?? 0
                        let ds =
                            try Int.fetchOne(
                                db,
                                sql:
                                    "SELECT COUNT(DISTINCT s) FROM (SELECT spellid_1 AS s FROM items WHERE spellid_1 IS NOT NULL UNION ALL SELECT spellid_2 FROM items WHERE spellid_2 IS NOT NULL UNION ALL SELECT spellid_3 FROM items WHERE spellid_3 IS NOT NULL UNION ALL SELECT spellid_4 FROM items WHERE spellid_4 IS NOT NULL UNION ALL SELECT spellid_5 FROM items WHERE spellid_5 IS NOT NULL)"
                            ) ?? 0
                        // Low-level page stats for compression estimate
                        let pageCount = (try Int.fetchOne(db, sql: "PRAGMA page_count")) ?? 0
                        let freeList = (try Int.fetchOne(db, sql: "PRAGMA freelist_count")) ?? 0
                        let pageSize = (try Int.fetchOne(db, sql: "PRAGMA page_size")) ?? 0
                        return (i, f, dict, sc, iw, ls, ds, pageCount, freeList, pageSize)
                    }
                await MainActor.run {
                    self.itemCount = i
                    self.ftsCount = f
                    self.versionRow = row
                    self.spellCount = scOpt
                    self.itemsWithSpellCount = iw
                    self.linkedSpellRefs = ls
                    self.distinctSpellRefs = ds
                    self.ftsMismatch = (i != f)
                    if iw > 0, i > 0 {
                        self.itemsWithSpellPercent = (Double(iw) / Double(i)) * 100.0
                    }
                    // File size
                    if let url = DatabaseService.shared.dbFileURL,
                        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                        let size = attrs[.size] as? Int64
                    {
                        self.dbFileSizeBytes = size
                        // Compression estimate: what would VACUUM reclaim (remove free pages)
                        if pageCount > 0 && pageSize > 0 && pageCount > freeList {
                            let currentBytes = Double(pageCount * pageSize)
                            let compactBytes = Double((pageCount - freeList) * pageSize)
                            if compactBytes > 0 {
                                self.dbCompressionEstimate = currentBytes / compactBytes
                            }
                        }
                        // Lightweight DB hash (SHA256 short) for integrity (best-effort)
                        #if canImport(CryptoKit)
                            if let data = try? Data(contentsOf: url), data.count < 60_000_000 {  // guard memory
                                let digest = SHA256.hash(data: data)
                                self.dbHashShort = digest.compactMap { String(format: "%02x", $0) }
                                    .joined().prefix(12).uppercased()
                            } else {
                                self.dbHashShort = nil
                            }
                        #endif
                    }
                }
            } catch {
                await MainActor.run { self.statsError = error.localizedDescription }
            }
        #endif
    }

    private func loadDeepStats() async {
        #if canImport(GRDB)
            if deepStatsLoaded { return }
            guard let queue = DatabaseService.shared.dbQueue else { return }
            do {
                let result = try await queue.read {
                    db -> (
                        [(String, Int)], [(Int, Int)], [(Int, Int)], (Int, Int, Double)?, Int?,
                        [(Int, Int)]
                    ) in
                    // Table counts
                    var tCounts: [(String, Int)] = []
                    let tableRows = try Row.fetchAll(
                        db,
                        sql:
                            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
                    )
                    for r in tableRows {
                        if let name: String = r["name"] {
                            let c = (try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(name)")) ?? 0
                            tCounts.append((name, c))
                        }
                    }
                    // Quality distribution
                    var qCounts: [(Int, Int)] = []
                    for row in try Row.fetchAll(
                        db,
                        sql:
                            "SELECT quality, COUNT(*) c FROM items GROUP BY quality ORDER BY quality"
                    ) {
                        if let q: Int = row["quality"], let c: Int = row["c"] {
                            qCounts.append((q, c))
                        }
                    }
                    // Patch distribution
                    var pCounts: [(Int, Int)] = []
                    for row in try Row.fetchAll(
                        db,
                        sql:
                            "SELECT patch, COUNT(*) c FROM items WHERE patch IS NOT NULL GROUP BY patch ORDER BY patch"
                    ) {
                        if let p: Int = row["patch"], let c: Int = row["c"] {
                            pCounts.append((p, c))
                        }
                    }
                    // Item level range
                    var rangeTuple: (Int, Int, Double)? = nil
                    if let row = try Row.fetchOne(
                        db,
                        sql:
                            "SELECT MIN(item_level) mn, MAX(item_level) mx, AVG(item_level) av FROM items WHERE item_level IS NOT NULL"
                    ) {
                        if let mn: Int = row["mn"], let mx: Int = row["mx"],
                            let av: Double = row["av"]
                        {
                            rangeTuple = (mn, mx, av)
                        }
                    }
                    var median: Int? = nil
                    if let countAll = try Int.fetchOne(
                        db, sql: "SELECT COUNT(*) FROM items WHERE item_level IS NOT NULL"),
                        countAll > 0
                    {
                        // 0-based offset for median (lower median if even)
                        let offset = (countAll - 1) / 2
                        median = try Int.fetchOne(
                            db,
                            sql:
                                "SELECT item_level FROM items WHERE item_level IS NOT NULL ORDER BY item_level LIMIT 1 OFFSET \(offset)"
                        )
                    }
                    // Top spell references if spells present & any refs
                    var topRefs: [(Int, Int)] = []
                    let refsSQL =
                        "WITH refs AS (SELECT spellid_1 AS s FROM items WHERE spellid_1 IS NOT NULL UNION ALL SELECT spellid_2 FROM items WHERE spellid_2 IS NOT NULL UNION ALL SELECT spellid_3 FROM items WHERE spellid_3 IS NOT NULL UNION ALL SELECT spellid_4 FROM items WHERE spellid_4 IS NOT NULL UNION ALL SELECT spellid_5 FROM items WHERE spellid_5 IS NOT NULL) SELECT s, COUNT(*) c FROM refs GROUP BY s ORDER BY c DESC LIMIT 5"
                    for row in try Row.fetchAll(db, sql: refsSQL) {
                        if let s: Int = row["s"], let c: Int = row["c"] { topRefs.append((s, c)) }
                    }
                    return (tCounts, qCounts, pCounts, rangeTuple, median, topRefs)
                }
                await MainActor.run {
                    self.tableCounts = result.0
                    self.qualityCounts = result.1
                    self.patchCounts = result.2
                    self.itemLevelRange = result.3
                    self.medianItemLevel = result.4
                    self.topSpellRefs = result.5
                    self.deepStatsLoaded = true
                }
            } catch {
                await MainActor.run {
                    self.deepStatsError = error.localizedDescription
                    self.deepStatsLoaded = true
                }
            }
        #endif
    }
}

// MARK: - Friendly Key Mapping
extension AboutView {
    fileprivate func friendlyVersionKey(_ raw: String) -> String {
        let lower = raw.lowercased()
        switch lower {
        case "snapshot_date", "snapshotdate": return "Snapshot Date"
        case "source_hash", "git_hash", "commit": return "Source Commit"
        case "generator_version", "pipeline_version": return "Pipeline Version"
        case "export_build", "client_build": return "Client Build"
        default:
            return raw.replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    // Parsed convenience values extracted from versionRow
    fileprivate var snapshotDateDisplay: String? {
        guard let raw = versionRow.first(where: { $0.key.lowercased().contains("snapshot") })?.value
        else { return nil }
        // Accept YYYY-MM-DD or YYYYMMDD; format to YYYY-MM-DD
        let digits = raw.replacingOccurrences(of: "-", with: "")
        if digits.count == 8, let y = Int(digits.prefix(4)),
            let m = Int(digits.dropFirst(4).prefix(2)), let d = Int(digits.suffix(2)),
            (1...12).contains(m), (1...31).contains(d)
        {
            return String(format: "%04d-%02d-%02d", y, m, d)
        }
        return raw
    }

    fileprivate var versionRowCommitShort: String? {
        // Look for a commit / hash field and shorten to 7 chars
        if let pair = versionRow.first(where: { k, _ in
            let l = k.lowercased()
            return l.contains("hash") || l.contains("commit")
        }) {
            let v = pair.value
            if v.count > 7 { return String(v.prefix(7)) } else { return v }
        }
        return nil
    }
}

// MARK: - Reusable Card
private struct InfoCard<Content: View>: View {
    let title: String
    let systemImage: String
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
                    .foregroundStyle(tint ?? Color.accentColor)
                Text(title)
                    .font(.headline)
                Spacer(minLength: 0)
            }
            content
                .font(.subheadline)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08))
        )
    }
}

// MARK: - Code Block Utility
private struct CodeBlock: View {
    let lines: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(lines, id: \.self) { l in
                Text(l)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if l != lines.last { Divider().opacity(0.15) }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(codeBlockBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.06))
        )
        .textSelection(.enabled)
    }
}

// MARK: - Visual Helpers
extension AboutView {
    fileprivate var appIconVisual: some View {
        // Display the actual app icon from the bundle
        Group {
            #if canImport(UIKit)
                if let appIcon = getAppIcon() {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white)
                }
            #elseif canImport(AppKit)
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white)
                }
            #else
                Image(systemName: "sparkles")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
            #endif
        }
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(radius: 5, y: 3)
        .accessibilityLabel("App Icon")
    }

    fileprivate var noiseOverlay: some View {
        Canvas(rendersAsynchronously: true) { ctx, size in
            let noiseDensity = 420
            for _ in 0..<noiseDensity {
                let x = Double.random(in: 0..<size.width)
                let y = Double.random(in: 0..<size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                ctx.fill(Path(rect), with: .color(Color.white.opacity(0.08)))
            }
        }
        .opacity(0.35)
    }

    fileprivate func buildDiagnostics() -> String {
        var lines: [String] = []
        lines.append("App: \(appDisplayName) \(appVersion) (")
        lines.append("Platform: \(platformString())")
        if let i = itemCount { lines.append("Items: \(i)") }
        if let f = ftsCount { lines.append("FTS Rows: \(f)") }
        if let hash = dbHashShort { lines.append("DB Hash: \(hash)") }
        if let m = medianItemLevel { lines.append("Median ilvl: \(m)") }
        if let range = itemLevelRange {
            lines.append(
                "ilvl range: \(range.min)-\(range.max) avg \(String(format: "%.1f", range.avg))")
        }
        if let withSpell = itemsWithSpellCount, let pct = itemsWithSpellPercent {
            lines.append("Items w/ Spell: \(withSpell) (\(String(format: "%.1f%%", pct)))")
        }
        if let sc = spellCount { lines.append("Spells: \(sc)") }
        if let refs = linkedSpellRefs { lines.append("Spell Refs: \(refs)") }
        if let distinct = distinctSpellRefs { lines.append("Distinct Spell Refs: \(distinct)") }
        if let size = dbFileSizeBytes { lines.append("DB Size: \(byteString(size))") }
        if let ratio = dbCompressionEstimate {
            lines.append(String(format: "Vacuum Gain: ~%.2fx", ratio))
        }
        if ftsMismatch { lines.append("Anomaly: items vs FTS mismatch") }
        if !versionRow.isEmpty {
            lines.append("Data Version Row:")
            for k in versionRow.keys.sorted() {
                lines.append("  - \(friendlyVersionKey(k)): \(versionRow[k] ?? "")")
            }
        }
        return lines.joined(separator: "\n")
    }

    fileprivate func copyStatsToClipboard() {
        let export = buildDiagnostics()
        #if canImport(UIKit)
            UIPasteboard.general.string = export
            
            // Provide haptic feedback to confirm action
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        #elseif canImport(AppKit)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(export, forType: .string)
        #endif
    }

    #if os(iOS)
        fileprivate func prepareAndShareDiagnostics() {
            diagnosticsText = buildDiagnostics()
            showShareSheet = true
        }

        // Helper function to get the app icon from the bundle
        fileprivate func getAppIcon() -> UIImage? {
            // First try to access the AppIcon directly from the asset catalog
            if let appIcon = UIImage(named: "AppIcon") {
                return appIcon
            }

            // Alternative: try to get icon from bundle info and manually construct
            guard
                let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"]
                    as? [String: Any],
                let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
                let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                let lastIcon = iconFiles.last
            else {
                return nil
            }

            return UIImage(named: lastIcon)
        }
    #endif
}

#if os(iOS)
    import UIKit
    extension AboutView {
        // iOS Share Sheet
        struct ShareSheet: UIViewControllerRepresentable {
            let activityItems: [Any]
            func makeUIViewController(context: Context) -> UIActivityViewController {
                UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            }
            func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
        }
    }
#endif

// MARK: - Platform Colors
private var codeBlockBackground: Color {
    #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground.withAlphaComponent(0.9))
    #elseif canImport(AppKit)
        return Color(nsColor: NSColor.controlBackgroundColor.withSystemEffect(.none))
    #else
        return Color.gray.opacity(0.25)
    #endif
}

#if DEBUG
    struct AboutView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack { AboutView() }
                .preferredColorScheme(.light)
            NavigationStack { AboutView() }
                .preferredColorScheme(.dark)
        }
    }
#endif
