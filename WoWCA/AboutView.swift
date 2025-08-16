// UI/AboutView.swift
// Lightweight in-app About & Privacy screen for distribution readiness.

import SwiftUI

struct AboutView: View {
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

    var body: some View {
        List {
            Section("App") {
                LabeledContent("Name", value: appDisplayName)
                LabeledContent("Version", value: appVersion)
                LabeledContent("Platform", value: platformString())
            }

            Section("Data Source") {
                Text(
                    "Item & spell statistics come from publicly available classic game data exports. No proprietary artwork or copyrighted assets are included."
                )
                .font(.footnote)
            }

            Section("Privacy") {
                Text(
                    "No personal data is collected, tracked, or transmitted. All lookups happen locally against the bundled read‑only database."
                )
                .font(.footnote)
                if let url = URL(string: privacyURL) {
                    Link("Privacy Policy (Web)", destination: url)
                }
            }

            Section("Support") {
                if let issues = URL(string: "https://github.com/Gunnarguy/WoWCA/issues") {
                    Link(destination: issues) {
                        Label("Report an Issue", systemImage: "ladybug.fill")
                    }
                }
                if let repo = URL(string: "https://github.com/Gunnarguy/WoWCA") {
                    Link(destination: repo) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }

            Section("Acknowledgements") {
                Text("GRDB.swift for SQLite access. Apple SwiftUI. Community data resources.")
                    .font(.footnote)
            }

            Section("Disclaimer") {
                Text(
                    "Fan-made reference. Not affiliated with or endorsed by Blizzard Entertainment. 'World of Warcraft' is a trademark of Blizzard Entertainment, Inc."
                )
                .font(.footnote)
            }

            Section {
                Text("© 2025 Gunndamental. All rights reserved.")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var privacyURL: String { "https://gunnarguy.github.io/WoWCA/privacy" }

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
}

#if DEBUG
    struct AboutView_Previews: PreviewProvider {
        static var previews: some View { NavigationStack { AboutView() } }
    }
#endif
