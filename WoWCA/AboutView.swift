// UI/AboutView.swift
// Enhanced styled About / Privacy / Transparency screen.

import SwiftUI
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
        if let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !display.isEmpty { return display }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty { return name }
        return "App"
    }

    private var privacyURL: String { "https://gunnarguy.github.io/WoWCA/privacy" }

    // MARK: - Body
    // MARK: - Runtime Stats State
    @State private var itemCount: Int? = nil
    @State private var ftsCount: Int? = nil
    @State private var versionRow: [String: String] = [:]
    @State private var statsError: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroHeader
                Group {
                    InfoCard(title: "Overview", systemImage: "info.circle.fill") {
                        Text("A fast, fully offline reference for Classic items & spells. Everything is bundled – zero tracking, zero network calls.")
                    }
                    InfoCard(title: "Data Sources", systemImage: "tray.full.fill") {
                        Text("Data originates from publicly available classic game exports (vendored snapshot in the repository). No proprietary art or copyrighted assets are shipped.")
                    }
                    InfoCard(title: "Build & Provenance", systemImage: "shippingbox.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deterministic pipeline assembles a SQLite database + FTS index via `items_build.sh`. Fully offline; reproducible with one script.")
                            DisclosureGroup("Reproduce Locally") {
                                VStack(alignment: .leading, spacing: 6) {
                                    CodeBlock(lines: [
                                        "./items_build.sh",
                                        "sqlite3 build/items.sqlite 'select count(*) from items;'",
                                        "sqlite3 build/items.sqlite \"select entry,name from items_fts where items_fts match 'sulfuras*' limit 5;\""
                                    ])
                                    CodeBlock(lines: [
                                        "# Expected artifacts:",
                                        "build/items.sqlite  # working copy",
                                        "Resources/items.sqlite  # bundled copy",
                                        "item_changes_report.csv (optional diff)"
                                    ])
                                }.padding(.top, 4)
                            }
                            DisclosureGroup("Data Version Row") {
                                VStack(alignment: .leading, spacing: 4) {
                                    if versionRow.isEmpty { Text("Not available (row missing)").font(.footnote) } else {
                                        ForEach(versionRow.keys.sorted(), id: \.self) { k in
                                            HStack { Text(k).font(.caption.monospaced()); Spacer(); Text(versionRow[k] ?? "").font(.caption) }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                            if let url = URL(string: "https://github.com/Gunnarguy/WoWCA/blob/main/TRANSPARENCY.md") {
                                Link("Full Transparency Document", destination: url)
                                    .font(.footnote.weight(.semibold))
                            }
                        }
                    }
                    InfoCard(title: "Runtime Stats", systemImage: "gauge.with.dots.needle.50percent") {
                        VStack(alignment: .leading, spacing: 6) {
                            statLine(label: "Items", value: itemCount.map(String.init) ?? "…")
                            statLine(label: "FTS Rows", value: ftsCount.map(String.init) ?? "…")
                            if let err = statsError { Text(err).font(.caption).foregroundStyle(.red) }
                            DisclosureGroup("Query Examples") {
                                CodeBlock(lines: [
                                    "SELECT COUNT(*) FROM items;",
                                    "SELECT * FROM data_version;",
                                    "SELECT entry,name FROM items_fts WHERE items_fts MATCH 'sulfuras*' LIMIT 5;"
                                ])
                                .padding(.top, 4)
                            }
                        }
                    }
                    InfoCard(title: "Privacy", systemImage: "lock.shield.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No personal data collected, stored, or transmitted. All lookups run locally against a read‑only bundled database.")
                            if let url = URL(string: privacyURL) {
                                Link("Web Privacy Policy", destination: url)
                            }
                        }
                    }
                    InfoCard(title: "Support & Source", systemImage: "hammer.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            if let issues = URL(string: "https://github.com/Gunnarguy/WoWCA/issues") {
                                Link("Report an Issue", destination: issues)
                            }
                            if let repo = URL(string: "https://github.com/Gunnarguy/WoWCA") {
                                Link("Source Code (GitHub)", destination: repo)
                            }
                        }
                    }
                    InfoCard(title: "Acknowledgements", systemImage: "hands.clap.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("GRDB.swift (SQLite/FTS) – MIT")
                            Text("SwiftUI & Apple SDKs")
                            Text("Community data maintainers")
                        }.font(.footnote)
                    }
                    InfoCard(title: "Disclaimer", systemImage: "exclamationmark.triangle.fill", tint: .orange) {
                        Text("Fan-made reference. Not affiliated with or endorsed by Blizzard Entertainment. 'World of Warcraft' is a trademark of Blizzard Entertainment, Inc.")
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
    }

    // MARK: - Subviews
    private var heroHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(colors: [Color(#colorLiteral(red:0.18,green:0.24,blue:0.55,alpha:1)), Color(#colorLiteral(red:0.48,green:0.19,blue:0.66,alpha:1))], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        AngularGradient(colors: [Color.white.opacity(0.25), .clear, Color.white.opacity(0.05)], center: .center)
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
                .foregroundStyle(LinearGradient(colors: [Color.primary, Color.accentColor.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
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

    // MARK: - Load Stats
    private func loadStats() async {
#if canImport(GRDB)
        guard let queue = DatabaseService.shared.dbQueue else { return }
        do {
            let (i, f, row) = try await queue.read { db -> (Int, Int, [String: String]) in
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
                return (i, f, dict)
            }
            await MainActor.run {
                self.itemCount = i
                self.ftsCount = f
                self.versionRow = row
            }
        } catch {
            await MainActor.run { self.statsError = error.localizedDescription }
        }
#endif
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
private extension AboutView {
    var appIconVisual: some View {
        // Attempt to resolve an icon listed in CFBundleIcons; fallback to symbol.
        Group {
            #if canImport(UIKit)
            if let iconName = primaryIconName(), UIImage(named: iconName) != nil {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(radius: 5, y: 3)
            } else {
                fallbackSymbol
            }
            #else
            fallbackSymbol
            #endif
        }
        .accessibilityLabel("App Icon")
    }

    func primaryIconName() -> String? {
        guard let dict = Bundle.main.infoDictionary?[("CFBundleIcons")] as? [String: Any],
              let primary = dict["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String] else { return nil }
        return files.last
    }

    private var fallbackSymbol: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 46, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(radius: 4)
    }

    @ViewBuilder
    func statLine(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption.monospaced())
            Spacer()
            Text(value).font(.caption)
        }
        .accessibilityElement(children: .combine)
    }

    var noiseOverlay: some View {
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
}

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
