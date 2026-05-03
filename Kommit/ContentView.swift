import SwiftUI
import AVFoundation

// MARK: - Theme

enum CommitTheme {
    static let background = Color(hex: "050914")
    static let cardPrimary = Color(hex: "111827")
    static let cardSecondary = Color(hex: "151A24")
    static let accentBlue = Color(hex: "3B82F6")
    static let accentCyan = Color(hex: "67E8F9")
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let danger = Color(hex: "EF4444")
}

// MARK: - Models

struct BudgetCategory: Identifiable {
    let id = UUID()
    let name: String
    let spent: Double
    let limit: Double
    let symbol: String

    var progress: Double {
        min(spent / limit, 1.2)
    }
}

struct Partner: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let imageName: String?

    var initials: String {
        String(name.prefix(1)).uppercased()
    }
}

struct Brand: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let imageName: String?
}

enum DemoStep: Int, CaseIterable {
    case welcome
    case onboarding
    case budgetSetup
    case partners
    case plaid
    case home
    case purchaseAlert
    case video
    case aiReview
    case partnerDecision
    case saveOverride
    case earnedSummary
}

// MARK: - App State

@MainActor
final class DemoStore: ObservableObject {
    @Published var step: DemoStep = .welcome
    @Published var onboardingSelections: [String: String] = [:]
    @Published var selectedPartners: Set<Partner> = []
    @Published var socialTaxPercent: Double = 3
    @Published var plaidProgress: [String] = []
    @Published var isPlaidConnecting = false
    @Published var aiProgress: [String] = []
    @Published var isAIProcessing = false
    @Published var isRecording = false
    @Published var recordingSeconds = 0
    @Published var showBanner = false
    @Published var bannerText = ""

    let categories: [BudgetCategory] = [
        .init(name: "Food", spent: 410, limit: 450, symbol: "fork.knife"),
        .init(name: "Shopping", spent: 295, limit: 300, symbol: "bag"),
        .init(name: "Entertainment", spent: 160, limit: 200, symbol: "music.note.tv"),
        .init(name: "Subscriptions", spent: 102, limit: 120, symbol: "repeat"),
        .init(name: "Travel", spent: 90, limit: 250, symbol: "airplane")
    ]

    let partners: [Partner] = [
        .init(name: "Maya", imageName: "maya"),
        .init(name: "Jordan", imageName: "jordan"),
        .init(name: "Aaliyah", imageName: "aaliyah"),
        .init(name: "Chris", imageName: "chris"),
        .init(name: "Mom", imageName: "mom")
    ]

    let brands: [Brand] = [
        .init(name: "Apple", symbol: "apple.logo", imageName: "apple"),
        .init(name: "Nike", symbol: "shoe.2", imageName: "nike"),
        .init(name: "AMC", symbol: "ticket", imageName: "amc"),
        .init(name: "Starbucks", symbol: "cup.and.saucer", imageName: "starbucks"),
        .init(name: "OpenAI", symbol: "sparkles", imageName: "openai")
    ]

    func next() {
        guard let next = DemoStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            step = next
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func backHome() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
            step = .home
        }
    }

    func togglePartner(_ partner: Partner) {
        if selectedPartners.contains(partner) {
            selectedPartners.remove(partner)
        } else if selectedPartners.count < 3 {
            selectedPartners.insert(partner)
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func startPlaidMockFlow() {
        guard !isPlaidConnecting else { return }
        isPlaidConnecting = true
        plaidProgress = []
        Task {
            let steps = [
                "Encrypting connection…",
                "Reading recent transactions…",
                "Budget rules ready."
            ]
            for item in steps {
                try? await Task.sleep(for: .milliseconds(850))
                plaidProgress.append(item)
            }
            isPlaidConnecting = false
            next()
        }
    }

    func startAIReview() {
        guard !isAIProcessing else { return }
        isAIProcessing = true
        aiProgress = []
        Task {
            let steps = [
                "Checking your budget",
                "Reading purchase context",
                "Detecting emotional trigger",
                "Comparing wants vs needs",
                "Preparing recommendation"
            ]
            for item in steps {
                try? await Task.sleep(for: .milliseconds(700))
                aiProgress.append(item)
            }
            isAIProcessing = false
        }
    }

    func startRecording() {
        isRecording = true
        recordingSeconds = 0
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        Task {
            while isRecording {
                try? await Task.sleep(for: .seconds(1))
                recordingSeconds += 1
                if recordingSeconds >= 10 {
                    isRecording = false
                }
            }
        }
    }

    func stopRecording() {
        isRecording = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func showSavedBanner() {
        bannerText = "Saved $89.99 and kept your streak alive"
        showBanner = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task {
            try? await Task.sleep(for: .seconds(2))
            showBanner = false
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var store = DemoStore()

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            Group {
                switch store.step {
                case .welcome: WelcomeScreen(store: store)
                case .onboarding: OnboardingScreen(store: store)
                case .budgetSetup: BudgetSetupScreen(store: store)
                case .partners: PartnersScreen(store: store)
                case .plaid: MockPlaidScreen(store: store)
                case .home: HomeDashboardScreen(store: store)
                case .purchaseAlert: PurchaseAlertScreen(store: store)
                case .video: VideoJustificationScreen(store: store)
                case .aiReview: AIReviewScreen(store: store)
                case .partnerDecision: PartnerDecisionScreen(store: store)
                case .saveOverride: SaveOverrideScreen(store: store)
                case .earnedSummary: EarnedSummaryScreen(store: store)
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))

            if store.showBanner {
                VStack {
                    DemoNotificationBanner(text: store.bannerText)
                    Spacer()
                }
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Screens

struct WelcomeScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .font(.system(size: 58))
                .foregroundStyle(CommitTheme.accentCyan)
                .shadow(color: CommitTheme.accentBlue.opacity(0.8), radius: 14)

            Text("Spend with intention.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Commit helps you pause before impulse purchases and turn better habits into savings.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            PrimaryButton(title: "Start Demo") {
                store.next()
            }
        }
        .padding(24)
    }
}

struct OnboardingScreen: View {
    @ObservedObject var store: DemoStore

    private let sections: [(String, [String], String)] = [
        ("What are you trying to improve?", ["Stop impulse spending", "Reduce BNPL use", "Save more consistently", "Track emotional spending"], "improve"),
        ("Where do you overspend most?", ["Food", "Shopping", "Entertainment", "Subscriptions", "Travel"], "overspend"),
        ("What accountability feels best?", ["Friend", "Partner", "Family", "Private AI coach"], "accountability")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Quick setup")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                ForEach(sections, id: \ .2) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.0)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.95))

                        FlowLayout(items: section.1) { item in
                            PillButton(
                                title: item,
                                isSelected: store.onboardingSelections[section.2] == item
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    store.onboardingSelections[section.2] = item
                                }
                            }
                        }
                    }
                }

                PrimaryButton(title: "Continue") {
                    store.next()
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
    }
}

struct BudgetSetupScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget setup")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Your monthly categories")
                .foregroundStyle(.white.opacity(0.75))

            ForEach(store.categories) { category in
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(category.name, systemImage: category.symbol)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("$\(Int(category.spent)) / $\(Int(category.limit))")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        ProgressBar(progress: category.progress, tint: category.name == "Shopping" ? CommitTheme.warning : CommitTheme.accentBlue)
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Looks good") {
                store.next()
            }
        }
        .padding(20)
    }
}

struct PartnersScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose up to 3 accountability partners.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
                ForEach(store.partners) { partner in
                    VStack(spacing: 8) {
                        AvatarView(partner: partner, isSelected: store.selectedPartners.contains(partner))
                            .onTapGesture {
                                store.togglePartner(partner)
                            }
                        Text(partner.name)
                            .foregroundStyle(.white.opacity(0.85))
                            .font(.caption)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Social tax: \(Int(store.socialTaxPercent))%")
                        .foregroundStyle(.white)
                    Slider(value: $store.socialTaxPercent, in: 1...5, step: 1)
                        .tint(CommitTheme.accentBlue)
                    Text("If you override a denied request, this percentage goes to your accountability partner.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()
            PrimaryButton(title: "Continue") {
                if store.selectedPartners.isEmpty {
                    if let first = store.partners.first {
                        store.selectedPartners.insert(first)
                    }
                }
                store.next()
            }
        }
        .padding(20)
    }
}

struct MockPlaidScreen: View {
    @ObservedObject var store: DemoStore

    private let accounts = ["Chase Checking ****2049", "Apple Card ****4556", "Cash App Card ****9912"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect your spending account.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                HStack(spacing: 10) {
                    Image(systemName: "link.circle.fill")
                        .foregroundStyle(CommitTheme.accentCyan)
                    Text("PLAID")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }
            }

            ForEach(accounts, id: \ .self) { account in
                GlassCard {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundStyle(CommitTheme.accentBlue)
                        Text(account)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .onTapGesture {
                    store.startPlaidMockFlow()
                }
            }

            if store.isPlaidConnecting || !store.plaidProgress.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.plaidProgress, id: \ .self) { step in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(CommitTheme.success)
                                Text(step)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

struct HomeDashboardScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Good evening, Mo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Available Balance")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("$2,405.80")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        HStack {
                            Text("Safe to spend: $186")
                                .foregroundStyle(CommitTheme.success)
                            Spacer()
                            Text("$967 / $1,320 spent")
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        ProgressBar(progress: 967 / 1320, tint: CommitTheme.accentBlue)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.categories) { category in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(category.name, systemImage: category.symbol)
                                        .foregroundStyle(.white)
                                    Text("$\(Int(category.spent)) / $\(Int(category.limit))")
                                        .foregroundStyle(.white.opacity(0.75))
                                    ProgressBar(progress: category.progress, tint: category.name == "Shopping" ? CommitTheme.warning : CommitTheme.accentBlue)
                                }
                                .frame(width: 180)
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accountability Circle")
                            .foregroundStyle(.white)
                        HStack(spacing: 12) {
                            ForEach(Array(store.selectedPartners.prefix(3)), id: \ .self) { partner in
                                AvatarView(partner: partner, isSelected: true)
                            }
                        }
                    }
                }

                GlassCard {
                    Text("$120.12 earned through better choices")
                        .foregroundStyle(CommitTheme.success)
                        .font(.headline)
                }

                Text("Brand Watch")
                    .foregroundStyle(.white)

                HStack {
                    ForEach(store.brands) { brand in
                        BrandLogoView(brand: brand)
                    }
                }

                PrimaryButton(title: "Simulate Purchase") {
                    store.step = .purchaseAlert
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }

                DemoTabBar()
            }
            .padding(20)
        }
    }
}

struct PurchaseAlertScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(spacing: 16) {
            Text("Pause before you swipe")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Merchant: Nike")
                    Text("Amount: $89.99")
                    Text("Category: Shopping")
                    Text("Current spend: $295 / $300")
                    Text("New total: $384.99 / $300")
                    Text("Over budget by: $84.99")
                        .foregroundStyle(CommitTheme.danger)
                }
                .foregroundStyle(.white)
            }

            PrimaryButton(title: "Record why I need this") {
                store.next()
            }

            Button("Cancel purchase") {
                store.backHome()
            }
            .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .padding(20)
    }
}

struct VideoJustificationScreen: View {
    @ObservedObject var store: DemoStore
    @State private var useRealCamera = false

    private let chips = ["Want", "Need", "Stress", "Excited", "Bored", "Treat myself"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Record your why")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ZStack(alignment: .topTrailing) {
                Group {
                    if useRealCamera {
                        CameraPreviewView()
                    } else {
                        MockCameraView()
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 1))

                Text(timeString(store.recordingSeconds))
                    .font(.caption.monospacedDigit())
                    .padding(8)
                    .background(.black.opacity(0.4))
                    .clipShape(Capsule())
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Why do you need this purchase?")
                Text("Want or need?")
                Text("How are you feeling?")
            }
            .foregroundStyle(.white.opacity(0.85))

            FlowLayout(items: chips) { chip in
                PillButton(title: chip, isSelected: false) {}
            }

            HStack(spacing: 16) {
                Button {
                    store.isRecording ? store.stopRecording() : store.startRecording()
                } label: {
                    Circle()
                        .fill(store.isRecording ? CommitTheme.danger : .white)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(CommitTheme.danger, lineWidth: 5).scaleEffect(store.isRecording ? 1.15 : 1))
                        .shadow(color: CommitTheme.danger.opacity(0.7), radius: 16)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: store.isRecording)
                }

                PrimaryButton(title: "Submit for Review") {
                    store.stopRecording()
                    // Real implementation hook: upload short video clip to backend moderation service.
                    store.next()
                }
            }

            Spacer()
        }
        .padding(20)
        .task {
            useRealCamera = await CameraAvailabilityChecker.canUseCamera
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

struct AIReviewScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Review")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.aiProgress, id: \ .self) { item in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CommitTheme.success)
                            Text(item)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            if !store.isAIProcessing && !store.aiProgress.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommendation: Wait 24 hours")
                            .foregroundStyle(CommitTheme.warning)
                            .font(.headline)
                        Text("You are $84.99 over your Shopping budget. This looks like a want, not an urgent need.")
                            .foregroundStyle(.white.opacity(0.85))
                        Text("AI Confidence: 87%")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                PrimaryButton(title: "Send to Maya") {
                    // Real implementation hook: send structured decision packet to trusted reviewer.
                    store.next()
                }
            }

            Spacer()
        }
        .padding(20)
        .task {
            store.startAIReview()
        }
    }
}

struct PartnerDecisionScreen: View {
    @ObservedObject var store: DemoStore
    @State private var decided = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Maya is reviewing")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                Text("Do you really need this today, or can we wait until next paycheck?")
                    .foregroundStyle(.white)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nike • $89.99")
                    Text("Category: Shopping")
                    Text("Over budget by $84.99")
                }
                .foregroundStyle(.white.opacity(0.9))
            }

            HStack {
                Button("Approved") {
                    decided = true
                }
                .buttonStyle(.bordered)

                Button("Denied") {
                    decided = true
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                .buttonStyle(.borderedProminent)
                .tint(CommitTheme.danger)
            }

            if decided {
                GlassCard {
                    Text("Maya voted: Deny")
                        .foregroundStyle(CommitTheme.danger)
                }
                PrimaryButton(title: "Choose what to do") {
                    store.next()
                }
            }

            Spacer()
        }
        .padding(20)
    }
}

struct SaveOverrideScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(spacing: 14) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save instead")
                        .font(.title3.bold())
                        .foregroundStyle(CommitTheme.success)
                    Text("Move $89.99 to savings")
                    Text("Keep streak")
                    Text("Avoid social tax")
                }
                .foregroundStyle(.white)
            }
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(CommitTheme.success, lineWidth: 1.2))
            .onTapGesture {
                store.showSavedBanner()
                store.next()
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Override purchase")
                        .font(.title3.bold())
                        .foregroundStyle(CommitTheme.warning)
                    Text("Continue anyway")
                    Text("Pay 3% social tax to Maya")
                    Text("Social tax: $2.70")
                    Text("Streak resets")
                }
                .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(20)
    }
}

struct EarnedSummaryScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You turned impulse into progress.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("$89.99 saved today")
                    Text("$120.12 earned this month")
                    Text("5-day reflection streak")
                    Text("3 avoided purchases")
                }
                .foregroundStyle(.white)
            }

            HStack {
                ForEach(store.brands) { brand in
                    BrandLogoView(brand: brand)
                }
            }

            Text("Demo only. Not financial advice. No real investing.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))

            PrimaryButton(title: "Back to Home") {
                // Real implementation hook: persist milestone metrics to backend profile.
                store.backHome()
            }

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Reusable Components

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [CommitTheme.cardPrimary.opacity(0.92), CommitTheme.cardSecondary.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: CommitTheme.accentBlue.opacity(0.12), radius: 12, y: 8)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [CommitTheme.accentBlue, CommitTheme.accentCyan], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .shadow(color: CommitTheme.accentBlue.opacity(0.5), radius: 10)
    }
}

struct ProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12))
                Capsule().fill(tint)
                    .frame(width: max(6, geo.size.width * progress))
            }
        }
        .frame(height: 8)
    }
}

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? CommitTheme.accentBlue.opacity(0.35) : .white.opacity(0.06))
                .overlay(Capsule().stroke(isSelected ? CommitTheme.accentCyan : .white.opacity(0.15), lineWidth: 1))
                .clipShape(Capsule())
                .foregroundStyle(.white)
        }
    }
}

struct AvatarView: View {
    let partner: Partner
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let imageName = partner.imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle().fill(CommitTheme.cardSecondary)
                    Text(partner.initials)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 66, height: 66)
            .clipShape(Circle())
            .overlay(Circle().stroke(isSelected ? CommitTheme.accentCyan : .white.opacity(0.18), lineWidth: 2))

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(CommitTheme.success)
                    .background(Circle().fill(.black))
            }
        }
    }
}

struct BrandLogoView: View {
    let brand: Brand

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(.white.opacity(0.08))
                if let imageName = brand.imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Image(systemName: brand.symbol)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 54, height: 54)
            Text(brand.name)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            CommitTheme.background
            RadialGradient(colors: [CommitTheme.accentBlue.opacity(0.26), .clear], center: animate ? .topLeading : .bottomTrailing, startRadius: 80, endRadius: 500)
            RadialGradient(colors: [CommitTheme.accentCyan.opacity(0.18), .clear], center: animate ? .bottomTrailing : .topLeading, startRadius: 70, endRadius: 460)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

struct DemoNotificationBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(CommitTheme.success.opacity(0.85)))
    }
}

struct DemoTabBar: View {
    private let tabs: [(String, String)] = [
        ("Home", "house.fill"),
        ("Budgets", "chart.bar.fill"),
        ("Record", "record.circle.fill"),
        ("Earned", "star.fill"),
        ("Profile", "person.crop.circle")
    ]

    var body: some View {
        GlassCard {
            HStack {
                ForEach(tabs, id: \ .0) { tab in
                    VStack(spacing: 4) {
                        Image(systemName: tab.1)
                        Text(tab.0)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(tab.0 == "Home" ? CommitTheme.accentCyan : .white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Camera

actor CameraAvailabilityChecker {
    static var canUseCamera: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                return AVCaptureDevice.default(for: .video) != nil
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                return granted && AVCaptureDevice.default(for: .video) != nil
            default:
                return false
            }
        }
    }
}

final class CameraSessionModel: ObservableObject {
    let session = AVCaptureSession()

    init() {
        configure()
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
        session.startRunning()
    }
}

struct CameraPreviewView: UIViewRepresentable {
    @StateObject private var model = CameraSessionModel()

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = model.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {}
}

final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct MockCameraView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [CommitTheme.cardSecondary, CommitTheme.background], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 14) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.85))
                Text("Camera preview unavailable")
                    .foregroundStyle(.white.opacity(0.85))
                Text("Using polished demo mode")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }
}

// MARK: - Utilities

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \ .self) { item in
                content(item)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
