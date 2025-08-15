import SwiftUI

struct DatabaseTestView: View {
    @State private var testResult = "Testing..."

    var body: some View {
        VStack(spacing: 20) {
            Text("Database Bundle Test")
                .font(.headline)

            Text(testResult)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Button("Test Database File") {
                testDatabaseFile()
            }
        }
        .padding()
        .onAppear {
            testDatabaseFile()
        }
    }

    private func testDatabaseFile() {
        if let bundledURL = Bundle.main.url(forResource: "items", withExtension: "sqlite") {
            testResult = "✅ Database found at: \(bundledURL.path)"
        } else {
            testResult = "❌ Database file not found in app bundle"

            // List all sqlite files in bundle for debugging
            if let bundlePath = Bundle.main.resourcePath {
                let fm = FileManager.default
                do {
                    let files = try fm.contentsOfDirectory(atPath: bundlePath)
                    let sqliteFiles = files.filter { $0.contains("sqlite") }
                    if sqliteFiles.isEmpty {
                        testResult += "\n\nNo SQLite files found in bundle"
                    } else {
                        testResult +=
                            "\n\nSQLite files in bundle: \(sqliteFiles.joined(separator: ", "))"
                    }
                } catch {
                    testResult += "\n\nError listing bundle contents: \(error)"
                }
            }
        }
    }
}

#Preview {
    DatabaseTestView()
}
