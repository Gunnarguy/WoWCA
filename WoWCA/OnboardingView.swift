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
                // Page 1: Search Feature
                OnboardingPage(
                    title: "Powerful Search",
                    subtitle: "Find any World of Warcraft Classic item quickly and easily",
                    systemImage: "magnifyingglass.circle.fill",
                    color: .blue,
                    features: [
                        "� Search by item name (e.g., \"Sulfuras\")",
                        "🔢 Direct lookup by item ID (e.g., \"19019\")",
                        "⚡ Instant results with full-text search",
                        "📊 Complete item stats and details"
                    ]
                )
                
                // Page 2: Favorites Feature
                OnboardingPage(
                    title: "Save Your Favorites",
                    subtitle: "Build your personal collection of important items",
                    systemImage: "star.circle.fill",
                    color: .orange,
                    features: [
                        "⭐ Bookmark items for quick access",
                        "📝 Build gear wishlists and shopping lists",
                        "� All favorites saved locally on your device",
                        "� Sync across app launches"
                    ]
                )
                
                // Page 3: Recent History Feature
                OnboardingPage(
                    title: "Recent History",
                    subtitle: "Keep track of items you've viewed recently",
                    systemImage: "clock.circle.fill",
                    color: .green,
                    features: [
                        "🕒 Automatic history of viewed items",
                        "� Pick up where you left off",
                        "🗑️ Clear history when needed",
                        "⚡ Quick access to recent searches"
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
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            #endif
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
