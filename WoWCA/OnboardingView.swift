// OnboardingView.swift
// Interactive onboarding flow showcasing app features and value proposition

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView {
                // Page 1: Complete Database
                OnboardingPage(
                    title: "Complete WoW Classic Database",
                    subtitle: "Search through thousands of items, spells, and stats completely offline",
                    systemImage: "magnifyingglass.circle.fill",
                    color: .blue,
                    features: [
                        "🔍 Fast text search with auto-complete",
                        "🔢 Direct item ID lookup",
                        "⚡ Instant results with FTS5 search"
                    ]
                )
                
                // Page 2: Privacy & Offline
                OnboardingPage(
                    title: "Privacy First & Offline",
                    subtitle: "No tracking, no analytics, no network calls - all data stays on your device",
                    systemImage: "lock.shield.fill",
                    color: .green,
                    features: [
                        "🔒 Zero data collection or tracking",
                        "📱 Works completely offline",
                        "🚫 No permissions required"
                    ]
                )
                
                // Page 3: Personalization
                OnboardingPage(
                    title: "Save Your Favorites",
                    subtitle: "Bookmark items to build gear lists, wishlists, and track your progress",
                    systemImage: "star.circle.fill",
                    color: .orange,
                    features: [
                        "⭐ Save favorite items",
                        "🕒 Track recently viewed items",
                        "📝 Build personalized gear lists"
                    ],
                    isLast: true
                ) {
                    VStack(spacing: 16) {
                        Button("Get Started") {
                            hasCompletedOnboarding = true
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Skip") {
                            hasCompletedOnboarding = true
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPage<Actions: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    var features: [String] = []
    var isLast: Bool = false
    @ViewBuilder var actions: Actions
    
    init(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        features: [String] = [],
        isLast: Bool = false,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.features = features
        self.isLast = isLast
        self.actions = actions()
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isLast)
            
            VStack(spacing: 16) {
                // Title
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Subtitle
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Features list
            if !features.isEmpty {
                VStack(spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack {
                            Text(feature)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            // Actions (only on last page)
            if isLast {
                actions
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Extension for EmptyView conformance
extension OnboardingPage where Actions == EmptyView {
    init(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color,
        features: [String] = [],
        isLast: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.features = features
        self.isLast = isLast
        self.actions = EmptyView()
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif
