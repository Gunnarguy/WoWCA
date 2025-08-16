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
                                "No Blizzard art or proprietary assets included; only structured item + spell fields."
                            )
                        }
                    }
                    InfoCard(title: "Build & Provenance", systemImage: "shippingbox.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                "Deterministic script (`items_build.sh`) produces the SQLite + FTS5 database. Re-run locally to reproduce this build bit‑for‑bit (same input snapshot → same output hash)."
                            )
                            DisclosureGroup("Reproduce Locally") {
                                VStack(alignment: .leading, spacing: 6) {
                                    CodeBlock(lines: [
                                        "./items_build.sh",
                                        "sqlite3 build/items.sqlite 'select count(*) from items;'",
                                        "sqlite3 build/items.sqlite \"select entry,name from items_fts where items_fts match 'sulfuras*' limit 5;\"",
                                    ])
                                    CodeBlock(lines: [
                                        "# Expected artifacts:",
                                        "build/items.sqlite  # working copy",
                                        "Resources/items.sqlite  # bundled copy",
                                        "item_changes_report.csv (optional diff)",
                                    ])
                                }.padding(.top, 4)
                            }
                            DisclosureGroup("Data Version Row") {
                                VStack(alignment: .leading, spacing: 4) {
                                    if versionRow.isEmpty {
                                        Text("Not available (row missing)").font(.footnote)
                                    } else {
                                        ForEach(versionRow.keys.sorted(), id: \.self) { k in
                                            HStack {
                                                Text(friendlyVersionKey(k)).font(
                                                    .caption.monospaced())
                                                Spacer()
                                                Text(versionRow[k] ?? "").font(.caption)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                            if let url = URL(
                                string:
                                    "https://github.com/Gunnarguy/WoWCA/blob/main/TRANSPARENCY.md")
                            {
                                Link("Full Transparency Document", destination: url)
                                    .font(.footnote.weight(.semibold))
                            }
                        }
                    }
                    InfoCard(title: "Core Stats", systemImage: "gauge.with.dots.needle.50percent") {
                        VStack(alignment: .leading, spacing: 6) {
                            statLine(label: "Items", value: itemCount.map(String.init) ?? "…")
                            statLine(
                                label: ftsMismatch ? "FTS Rows ⚠️" : "FTS Rows",
                                value: ftsCount.map(String.init) ?? "…")
                            if itemCount != nil, let withSpell = itemsWithSpellCount,
                                let pct = itemsWithSpellPercent
                            {
                                statLine(
                                    label: "Items w/ Spell",
                                    value: "\(withSpell) (" + String(format: "%.1f%%", pct) + ")")
                            }
                            if let size = dbFileSizeBytes {
                                statLine(label: "DB Size", value: byteString(size))
                            }
                            if let h = dbHashShort { statLine(label: "DB Hash", value: h) }
                            if let ratio = dbCompressionEstimate {
                                statLine(
                                    label: "Vacuum Gain", value: String(format: "~%.2fx", ratio))
                            }
                            if spellCount != nil {
                                DisclosureGroup("Spell Linking") {
                                    VStack(alignment: .leading, spacing: 4) {
                                        statLine(
                                            label: "Spells",
                                            value: spellCount.map(String.init) ?? "…")
                                        statLine(
                                            label: "Spell Refs",
                                            value: linkedSpellRefs.map(String.init) ?? "…")
                                        statLine(
                                            label: "Distinct Spell Refs",
                                            value: distinctSpellRefs.map(String.init) ?? "…")
                                        if let refs = linkedSpellRefs,
                                            let withSpell = itemsWithSpellCount, withSpell > 0
                                        {
                                            let avg = Double(refs) / Double(withSpell)
                                            statLine(
                                                label: "Avg Refs/Item",
                                                value: String(format: "%.2f", avg))
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            if ftsMismatch {
                                Text("FTS row count differs from items; rebuild advised.").font(
                                    .caption2
                                ).foregroundStyle(.orange)
                            }
                            if dbCompressionEstimate != nil {
                                Text(
                                    "Vacuum Gain is an approximate space saving if the DB were compacted (freelist removed)."
                                ).font(.caption2).foregroundStyle(.secondary)
                            }
                            if let err = statsError {
                                Text(err).font(.caption).foregroundStyle(.red)
                            }
                            DisclosureGroup("Query Examples") {
                                CodeBlock(lines: [
                                    "SELECT COUNT(*) FROM items;",
                                    "SELECT * FROM data_version;",
                                    "SELECT COUNT(*) FROM spells;",
                                    "SELECT COUNT(*) FROM items WHERE spellid_1 IS NOT NULL OR spellid_2 IS NOT NULL OR spellid_3 IS NOT NULL OR spellid_4 IS NOT NULL OR spellid_5 IS NOT NULL;",
                                    "SELECT (COUNT(spellid_1)+COUNT(spellid_2)+COUNT(spellid_3)+COUNT(spellid_4)+COUNT(spellid_5)) FROM items;",
                                    "SELECT COUNT(DISTINCT s) FROM (SELECT spellid_1 AS s FROM items WHERE spellid_1 IS NOT NULL UNION ALL SELECT spellid_2 FROM items WHERE spellid_2 IS NOT NULL UNION ALL SELECT spellid_3 FROM items WHERE spellid_3 IS NOT NULL UNION ALL SELECT spellid_4 FROM items WHERE spellid_4 IS NOT NULL UNION ALL SELECT spellid_5 FROM items WHERE spellid_5 IS NOT NULL);",
                                    "SELECT entry,name FROM items_fts WHERE items_fts MATCH 'sulfuras*' LIMIT 5;",
                                ])
                                .padding(.top, 4)
                            }
                        }
                    }
                    InfoCard(
                        title: "Database Deep Stats", systemImage: "chart.bar.doc.horizontal.fill"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            if !deepStatsLoaded {
                                ProgressView().task { await loadDeepStats() }
                            }
                            if let err = deepStatsError {
                                Text(err).font(.caption).foregroundStyle(.red)
                            }
                            if deepStatsLoaded {
                                if let range = itemLevelRange {
                                    statLine(label: "Item Level Min", value: String(range.min))
                                    statLine(label: "Item Level Max", value: String(range.max))
                                    statLine(
                                        label: "Item Level Avg",
                                        value: String(format: "%.1f", range.avg))
                                    if let med = medianItemLevel {
                                        statLine(label: "Item Level Median", value: String(med))
                                    }
                                }
                                DisclosureGroup("Table Row Counts") {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(tableCounts, id: \.0) { t in
                                            HStack {
                                                Text(t.0).font(.caption.monospaced())
                                                Spacer()
                                                Text("\(t.1)").font(.caption)
                                            }
                                        }
                                    }.padding(.top, 4)
                                }
                                DisclosureGroup("Item Qualities") {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(qualityCounts, id: \.0) { q in
                                            HStack {
                                                Text("Quality \(q.0)").font(.caption.monospaced())
                                                Spacer()
                                                Text("\(q.1)").font(.caption)
                                            }
                                        }
                                    }.padding(.top, 4)
                                    Text(
                                        "Counts by item quality enumeration (0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary)."
                                    )
                                    .font(.caption2).foregroundStyle(.secondary)
                                }
                                DisclosureGroup("Patch Distribution") {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(patchCounts, id: \.0) { p in
                                            HStack {
                                                Text("Patch \(p.0)").font(.caption.monospaced())
                                                Spacer()
                                                Text("\(p.1)").font(.caption)
                                            }
                                        }
                                    }.padding(.top, 4)
                                }
                                if !topSpellRefs.isEmpty {
                                    DisclosureGroup("Top Spell References") {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(topSpellRefs, id: \.0) { s in
                                                HStack {
                                                    Text("SpellID \(s.0)").font(
                                                        .caption.monospaced())
                                                    Spacer()
                                                    Text("\(s.1)x").font(.caption)
                                                }
                                            }
                                        }.padding(.top, 4)
                                        Text(
                                            "Most frequently referenced spell IDs across all item spell slots."
                                        ).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                DisclosureGroup("Deep Query Examples") {
                                    CodeBlock(lines: [
                                        // Each line kept short for small device widths
                                        "SELECT quality,COUNT(*) FROM items GROUP BY quality;",
                                        "SELECT patch,COUNT(*) FROM items WHERE patch IS NOT NULL GROUP BY patch;",
                                        "SELECT MIN(item_level),MAX(item_level),AVG(item_level) FROM items WHERE item_level IS NOT NULL;",
                                        "WITH refs AS (... union spellid_1..5) SELECT s,COUNT(*) c FROM refs GROUP BY s ORDER BY c DESC LIMIT 5;",
                                    ])
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    InfoCard(title: "Privacy", systemImage: "lock.shield.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                "No data leaves the device. The app has: • no analytics • no network fetches • no tracking identifiers. All queries execute locally in a read‑only SQLite file."
                            )
                            Text(
                                "Permissions: none required. No camera, contacts, location, or network entitlement is used."
                            ).font(.caption2).foregroundStyle(.secondary)
                            if let url = URL(string: privacyURL) {
                                Link("Web Privacy Policy", destination: url)
                            }
                        }
                    }
                    InfoCard(title: "Support & Source", systemImage: "hammer.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            if let issues = URL(string: "https://github.com/Gunnarguy/WoWCA/issues")
                            {
                                Link("Report an Issue", destination: issues)
                            }
                            if let repo = URL(string: "https://github.com/Gunnarguy/WoWCA") {
                                Link("Source Code (GitHub)", destination: repo)
                            }
                            if let licenseURL = URL(
                                string: "https://github.com/Gunnarguy/WoWCA/blob/main/LICENSE")
                            {
                                Link("Project License (MIT)", destination: licenseURL)
                            }
                            NavigationLink("In‑App Licenses") { LicensesView() }
                            Button(action: { copyStatsToClipboard() }) {
                                Label("Copy Diagnostics", systemImage: "doc.on.doc")
                                    .labelStyle(.titleAndIcon)
                            }
                            .font(.caption)
                            #if os(iOS)
                                Button(action: { prepareAndShareDiagnostics() }) {
                                    Label("Share Diagnostics", systemImage: "square.and.arrow.up")
                                        .labelStyle(.titleAndIcon)
                                }
                                .font(.caption)
                            #endif
                            Text("Include diagnostics in new issues to speed up triage.").font(
                                .caption2
                            ).foregroundStyle(.secondary)
                        }
                    }
                    InfoCard(title: "Search Tips", systemImage: "magnifyingglass") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Prefix match: type early letters (e.g. 'sulfu') for Sulfuras.")
                            Text("Wildcard: add * for stem expansion (e.g. 'gladiat*').")
                            Text("Exact ID: enter an item ID number (e.g. 19019).")
                            Text(
                                "Spell text: search effect phrases like 'chance on hit' or 'use:' to surface procs."
                            ).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    InfoCard(title: "Acknowledgements", systemImage: "hands.clap.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("GRDB.swift – MIT (SQLite / FTS5 layer)")
                            Text("Apple Swift / SwiftUI frameworks")
                            Text("Community Classic data curators")
                            Text("Open-source contributors & testers")
                        }.font(.footnote)
                    }
                    InfoCard(
                        title: "Disclaimer", systemImage: "exclamationmark.triangle.fill",
                        tint: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                "Unofficial fan-made reference. Not affiliated with Blizzard Entertainment."
                            )
                            Text(
                                "World of Warcraft is a trademark or registered trademark of Blizzard Entertainment, Inc. in the U.S. and/or other countries."
                            )
                        }
                        .font(.footnote)
                    }
                }
                footer
            }
            .padding(.horizontal, 20)
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
                ShareSheet(text: diagnosticsText)
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
        .padding(.bottom, 4)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Divider().opacity(0.3)
            Text("© 2025 Gunndamental. All rights reserved.")
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
        // Simplified: show dedicated preview asset if added, else fallback symbol.
        Group {
            #if canImport(UIKit)
                if let preview = UIImage(named: "AppIconPreview") {
                    Image(uiImage: preview)
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

    @ViewBuilder
    fileprivate func statLine(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption.monospaced())
            Spacer()
            Text(value).font(.caption)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(label.replacingOccurrences(of: "w/", with: "with")))
        .accessibilityValue(Text(value))
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
    #endif
}

#if os(iOS)
    import UIKit
    extension AboutView {
        // iOS Share Sheet
        struct ShareSheet: UIViewControllerRepresentable {
            let text: String
            func makeUIViewController(context: Context) -> UIActivityViewController {
                UIActivityViewController(activityItems: [text], applicationActivities: nil)
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
