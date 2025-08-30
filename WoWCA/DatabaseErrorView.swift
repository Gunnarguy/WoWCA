// DatabaseErrorView.swift
// Enhanced error view for database initialization failures

import SwiftUI
import os.log

struct DatabaseErrorView: View {
    @State private var isRetrying = false
    
    // Logger for error handling
    private let logger = Logger(subsystem: "com.wowca.app", category: "ErrorHandling")
    
    var body: some View {
        ContentUnavailableView {
            Label("Database Error", systemImage: "exclamationmark.triangle.fill")
        } description: {
            VStack(spacing: 8) {
                Text("Could not load the app's database.")
                    .font(.body)
                
                Text("This contains all the World of Warcraft Classic item data needed for the app to function.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } actions: {
            VStack(spacing: 12) {
                Button("Retry") {
                    retryDatabaseInit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRetrying)
                
                if isRetrying {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Retrying...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("If this problem continues, try restarting the app or reinstalling from the App Store.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
    
    private func retryDatabaseInit() {
        logger.info("🔄 User initiated database retry")
        print("🔄 Retrying database initialization...")
        
        isRetrying = true
        
        Task {
            do {
                // Give a small delay for UI feedback
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Attempt to reconfigure the database
                try DatabaseService.shared.configure()
                
                logger.info("✅ Database retry successful")
                print("✅ Database retry successful")
                
                // Restart the app by triggering a scene refresh
                // Note: In a real app, you might want to implement a more sophisticated
                // restart mechanism or state management
                
            } catch {
                logger.error("❌ Database retry failed: \(error.localizedDescription)")
                print("❌ Database retry failed: \(error)")
            }
            
            await MainActor.run {
                isRetrying = false
            }
        }
    }
}

#if DEBUG
struct DatabaseErrorView_Previews: PreviewProvider {
    static var previews: some View {
        DatabaseErrorView()
    }
}
#endif
