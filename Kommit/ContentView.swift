import SwiftUI
import AVFoundation
import Combine

// MARK: - Theme

enum KommitTheme {
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

struct SpendingAccount: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String?
}

enum DemoStep: Int, CaseIterable {
    case welcome
    case onboarding
    case initialReflection
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
    @Published var socialTaxPool: Double = 30
    @Published var selectedAlertThresholds: Set<Int> = [25, 50, 75, 90]
    @Published var plaidProgress: [String] = []
    @Published var isPlaidConnecting = false
    @Published var aiProgress: [String] = []
    @Published var isAIProcessing = false
    @Published var isRecording = false
    @Published var recordingSeconds = 0
    @Published var showBanner = false
    @Published var bannerText = ""
    @Published var showMonthEndPayoutAnimation = false

    let categories: [BudgetCategory] = [
        .init(name: "Food", spent: 410, limit: 450, symbol: "fork.knife"),
        .init(name: "Shopping", spent: 295, limit: 300, symbol: "bag"),
        .init(name: "Entertainment", spent: 160, limit: 200, symbol: "music.note.tv"),
        .init(name: "Subscriptions", spent: 102, limit: 120, symbol: "repeat"),
        .init(name: "Travel", spent: 90, limit: 250, symbol: "airplane")
    ]

    let partners: [Partner] = [
        .init(name: "Maya", imageName: "profile-image-1"),
        .init(name: "Jordan", imageName: "profile-image-2"),
        .init(name: "Aaliyah", imageName: nil),
        .init(name: "Chris", imageName: nil),
        .init(name: "Mom", imageName: "mom")
    ]

    let brands: [Brand] = [
        .init(name: "Apple", symbol: "apple.logo", imageName: "Apple_logo"),
        .init(name: "Nike", symbol: "shoe.2", imageName: "Nike-Logo"),
        .init(name: "Adidas", symbol: "figure.run", imageName: "Adidas-Logo"),
        .init(name: "H&M", symbol: "bag", imageName: "H&M-Logo"),
        .init(name: "Netflix", symbol: "play.rectangle", imageName: "netflix_logo")
    ]

    let accounts: [SpendingAccount] = [
        .init(name: "Chase Checking ****2049", imageName: "Chase-Logo"),
        .init(name: "Apple Card ****4556", imageName: "Apple_logo"),
        .init(name: "Cash App Card ****9912", imageName: "Bank-of-America-Logo")
    ]

    var perPartnerPayout: Double {
        let count = max(selectedPartners.count, 1)
        return socialTaxPool / Double(count)
    }

    var shoppingTaxBucket: Double {
        36.45
    }

    var partnerPayoutIfGoalMissed: Double {
        shoppingTaxBucket + socialTaxPool
    }

    var lastAlertThreshold: Int {
        selectedAlertThresholds.max() ?? 90
    }

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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                step = .budgetSetup
            }
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

    func triggerMissedBudgetGoalNotification() {
        bannerText = "Month-end: You missed your Shopping budget goal"
        showBanner = true
        showMonthEndPayoutAnimation = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        Task {
            try? await Task.sleep(for: .seconds(2))
            showBanner = false
            try? await Task.sleep(for: .milliseconds(700))
            showMonthEndPayoutAnimation = false
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var store = DemoStore()
    @State private var animateMonthEndPayout = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            Group {
                switch store.step {
                case .welcome: WelcomeScreen(store: store)
                case .onboarding: OnboardingScreen(store: store)
                case .initialReflection: InitialReflectionScreen(store: store)
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
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            .animation(.spring(response: 0.58, dampingFraction: 0.88), value: store.step)

            if store.showBanner {
                VStack {
                    DemoNotificationBanner(text: store.bannerText)
                    Spacer()
                }
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if store.showMonthEndPayoutAnimation {
                ZStack {
                    Color.black.opacity(0.66).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("Missed Goal Payout")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("$30 social tax pool sent to accountability partners")
                            .foregroundStyle(.white.opacity(0.85))
                        PartnerMoneyFlightView(
                            partners: payoutPartners,
                            animate: animateMonthEndPayout
                        )
                        .frame(height: 190)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 24).fill(KommitTheme.cardPrimary.opacity(0.96)))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(KommitTheme.warning, lineWidth: 1.2))
                    .padding(.horizontal, 20)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: store.showMonthEndPayoutAnimation) { _, show in
            animateMonthEndPayout = false
            guard show else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(140))
                animateMonthEndPayout = true
            }
        }
    }

    private var payoutPartners: [Partner] {
        let selected = Array(store.selectedPartners.prefix(3))
        return selected.isEmpty ? Array(store.partners.prefix(3)) : selected
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
                .foregroundStyle(KommitTheme.accentCyan)
                .shadow(color: KommitTheme.accentBlue.opacity(0.8), radius: 14)

            Text("Spend with intention.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Kommit helps you pause before impulse purchases and turn better habits into savings.")
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
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        store.step = .initialReflection
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
    }

}

struct InitialReflectionScreen: View {
    @ObservedObject var store: DemoStore
    @State private var canUseCamera = false
    @StateObject private var cameraModel = CameraSessionModel(preferredPosition: .front)
    @State private var isRecording = false
    @State private var recordingSeconds = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Initial Reflection")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Record a quick portrait video about your spending goals for this month.")
                .foregroundStyle(.white.opacity(0.8))

            ZStack(alignment: .topTrailing) {
                Group {
                    if canUseCamera {
                        CameraPreviewView(model: cameraModel)
                    } else {
                        MockCameraView()
                    }
                }
                .frame(height: 420)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 1))

                Text(timeString(recordingSeconds))
                    .font(.caption.monospacedDigit())
                    .padding(8)
                    .background(.black.opacity(0.45))
                    .clipShape(Capsule())
                    .padding(10)

                if canUseCamera {
                    Button {
                        cameraModel.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.45))
                            .clipShape(Circle())
                    }
                    .padding(.top, 44)
                    .padding(.trailing, 10)
                }
            }

            HStack(spacing: 16) {
                Button {
                    if isRecording {
                        isRecording = false
                    } else {
                        isRecording = true
                        recordingSeconds = 0
                        Task {
                            while isRecording {
                                try? await Task.sleep(for: .seconds(1))
                                recordingSeconds += 1
                                if recordingSeconds >= 10 { isRecording = false }
                            }
                        }
                    }
                } label: {
                    Circle()
                        .fill(isRecording ? KommitTheme.danger : .white)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(KommitTheme.danger, lineWidth: 5).scaleEffect(isRecording ? 1.15 : 1))
                }

                PrimaryButton(title: "Continue to Partners") {
                    isRecording = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        store.step = .partners
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .task {
            canUseCamera = await CameraAvailabilityChecker.canUseCamera
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
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
                        ProgressBar(progress: category.progress, tint: category.name == "Shopping" ? KommitTheme.warning : KommitTheme.accentBlue)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Alert limits for this budget")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Set notifications after connecting your account so you get warned before overspending.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                    HStack {
                        ForEach([25, 50, 75, 90], id: \.self) { threshold in
                            PillButton(
                                title: "\(threshold)%",
                                isSelected: store.selectedAlertThresholds.contains(threshold)
                            ) {
                                if store.selectedAlertThresholds.contains(threshold) {
                                    store.selectedAlertThresholds.remove(threshold)
                                } else {
                                    store.selectedAlertThresholds.insert(threshold)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Looks good") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    store.step = .home
                }
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
                    Text("Social tax pool: $30")
                        .foregroundStyle(.white)
                    Text("Fixed social tax for this demo. If you miss your monthly goal, this pool is split among selected partners.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Current split: $\(store.perPartnerPayout, specifier: "%.2f") per partner")
                        .font(.footnote)
                        .foregroundStyle(KommitTheme.accentCyan)
                }
            }

            Spacer()
            PrimaryButton(title: "Continue") {
                if store.selectedPartners.isEmpty {
                    if let first = store.partners.first {
                        store.selectedPartners.insert(first)
                    }
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    store.step = .plaid
                }
            }
        }
        .padding(20)
    }
}

struct MockPlaidScreen: View {
    @ObservedObject var store: DemoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect your spending account.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                HStack(spacing: 10) {
                    if UIImage(named: "Plaid_logo.svg") != nil {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white)
                            Image("Plaid_logo.svg")
                                .resizable()
                                .scaledToFit()
                                .padding(4)
                        }
                        .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "link.circle.fill")
                            .foregroundStyle(KommitTheme.accentCyan)
                    }
                    Text("PLAID")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                }
            }

            ForEach(store.accounts) { account in
                GlassCard {
                    HStack {
                        if let imageName = account.imageName, UIImage(named: imageName) != nil {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.white)
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(3)
                            }
                            .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(KommitTheme.accentBlue)
                        }
                        Text(account.name)
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
                                    .foregroundStyle(KommitTheme.success)
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
                                .foregroundStyle(KommitTheme.success)
                            Spacer()
                            Text("$967 / $1,320 spent")
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        ProgressBar(progress: 967 / 1320, tint: KommitTheme.accentBlue)
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
                                    ProgressBar(progress: category.progress, tint: category.name == "Shopping" ? KommitTheme.warning : KommitTheme.accentBlue)
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Tax Pool")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Text("$\(store.socialTaxPool, specifier: "%.2f") fixed monthly pool")
                            .foregroundStyle(KommitTheme.warning)
                        Text("Only pays out at month-end if you're over your monthly Shopping budget.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))
                        Text("Current split: $\(store.perPartnerPayout, specifier: "%.2f") per selected partner")
                            .foregroundStyle(KommitTheme.accentCyan)
                        Text("Trigger payout using “Fake Missed Goal Notification”.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                GlassCard {
                    Text("$120.12 earned through better choices")
                        .foregroundStyle(KommitTheme.success)
                        .font(.headline)
                }

                Text("Brand Watch")
                    .foregroundStyle(.white)

                HStack {
                    ForEach(store.brands) { brand in
                        BrandLogoView(brand: brand)
                    }
                }

                PrimaryButton(title: "Trigger Last Alert Flow") {
                    store.step = .purchaseAlert
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }

                PrimaryButton(title: "Fake Missed Goal Notification") {
                    store.triggerMissedBudgetGoalNotification()
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
                    Text("Last limit notification")
                        .foregroundStyle(KommitTheme.warning)
                    Text("Triggered at your \(store.lastAlertThreshold)% budget alert.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Merchant: Nike")
                    Text("Amount: $89.99")
                    Text("Category: Shopping")
                    Text("Current spend: $295 / $300")
                    Text("New total: $384.99 / $300")
                    Text("Over budget by: $84.99")
                        .foregroundStyle(KommitTheme.danger)
                }
                .foregroundStyle(.white)
            }

            PrimaryButton(title: "Record video for partners") {
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
    @StateObject private var cameraModel = CameraSessionModel(preferredPosition: .front)

    private let chips = ["Want", "Need", "Stress", "Excited", "Bored", "Treat myself"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Record your why")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            ZStack(alignment: .topTrailing) {
                Group {
                    if useRealCamera {
                        CameraPreviewView(model: cameraModel)
                    } else {
                        MockCameraView()
                    }
                }
                .frame(height: 420)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15), lineWidth: 1))

                Text(timeString(store.recordingSeconds))
                    .font(.caption.monospacedDigit())
                    .padding(8)
                    .background(.black.opacity(0.4))
                    .clipShape(Capsule())
                    .padding(10)

                if useRealCamera {
                    Button {
                        cameraModel.flipCamera()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.45))
                            .clipShape(Circle())
                    }
                    .padding(.top, 46)
                    .padding(.trailing, 10)
                }
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
                        .fill(store.isRecording ? KommitTheme.danger : .white)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(KommitTheme.danger, lineWidth: 5).scaleEffect(store.isRecording ? 1.15 : 1))
                        .shadow(color: KommitTheme.danger.opacity(0.7), radius: 16)
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
                                .foregroundStyle(KommitTheme.success)
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
                            .foregroundStyle(KommitTheme.warning)
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
    @State private var reactionLabel = ""
    @State private var includeResponseVideo = false
    @State private var partnerRecording = false
    @State private var partnerRecordingSeconds = 0
    @State private var canUseCamera = false
    @StateObject private var cameraModel = CameraSessionModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Maya is reviewing")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            GlassCard {
                Text("React to this transaction and leave feedback for your friend.")
                    .foregroundStyle(.white)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Attach response video with vote", isOn: $includeResponseVideo)
                        .tint(KommitTheme.accentBlue)
                        .foregroundStyle(.white)

                    if includeResponseVideo {
                        ZStack(alignment: .topTrailing) {
                            Group {
                                if canUseCamera {
                                    CameraPreviewView(model: cameraModel)
                                } else {
                                    MockCameraView()
                                }
                            }
                                .frame(height: 420)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            Text(timeString(partnerRecordingSeconds))
                                .font(.caption.monospacedDigit())
                                .padding(8)
                                .background(.black.opacity(0.45))
                                .clipShape(Capsule())
                                .padding(8)

                            if canUseCamera {
                                Button {
                                    cameraModel.flipCamera()
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "camera.rotate.fill")
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(.black.opacity(0.45))
                                        .clipShape(Circle())
                                }
                                .padding(.top, 42)
                                .padding(.trailing, 8)
                            }
                        }

                        Button {
                            if partnerRecording {
                                partnerRecording = false
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            } else {
                                partnerRecording = true
                                partnerRecordingSeconds = 0
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                Task {
                                    while partnerRecording {
                                        try? await Task.sleep(for: .seconds(1))
                                        partnerRecordingSeconds += 1
                                        if partnerRecordingSeconds >= 8 {
                                            partnerRecording = false
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label(partnerRecording ? "Stop Response Video" : "Record Response Video", systemImage: partnerRecording ? "stop.circle.fill" : "record.circle")
                                .foregroundStyle(.white)
                        }
                    }
                }
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
                Button("Thumbs Up") {
                    decided = true
                    reactionLabel = "Maya reacted: 👍 Good purchase"
                }
                .buttonStyle(.bordered)

                Button("Not a good purchase") {
                    decided = true
                    reactionLabel = "Maya reacted: 👎 Not a good purchase"
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                .buttonStyle(.borderedProminent)
                .tint(KommitTheme.danger)
            }

            if decided {
                GlassCard {
                    Text(reactionLabel)
                        .foregroundStyle(KommitTheme.warning)
                }
                PrimaryButton(title: "View video responses") {
                    store.next()
                }
            }

            Spacer()
        }
        .padding(20)
        .task {
            canUseCamera = await CameraAvailabilityChecker.canUseCamera
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

struct SaveOverrideScreen: View {
    @ObservedObject var store: DemoStore
    @State private var selectedResponder: Partner?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Partner Video Responses")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Select a partner to watch their response video.")
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                ForEach(displayPartners, id: \.self) { partner in
                    GlassCard {
                        VStack(spacing: 8) {
                            AvatarView(partner: partner, isSelected: selectedResponder == partner)
                            Text(partner.name)
                                .foregroundStyle(.white)
                                .font(.caption)
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(KommitTheme.accentCyan)
                                .font(.title2)
                        }
                    }
                    .onTapGesture {
                        selectedResponder = partner
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        Task {
                            try? await Task.sleep(for: .milliseconds(800))
                            store.backHome()
                        }
                    }
                }
            }

            GlassCard {
                Text("Partners can only react to your transaction. Payout happens only at month-end if you're over budget.")
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(20)
    }

    private var displayPartners: [Partner] {
        let selected = Array(store.selectedPartners.prefix(3))
        return selected.isEmpty ? Array(store.partners.prefix(3)) : selected
    }
}

struct PartnerMoneyFlightView: View {
    let partners: [Partner]
    let animate: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: 20) {
                    ForEach(partners, id: \.self) { partner in
                        AvatarView(partner: partner, isSelected: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                ForEach(0..<6, id: \.self) { index in
                    Text("💸")
                        .font(.system(size: 34))
                        .position(
                            x: animate ? targetX(for: index, width: geo.size.width, partnerCount: max(partners.count, 1)) : geo.size.width / 2,
                            y: animate ? 34 : geo.size.height - 20
                        )
                        .opacity(animate ? 0.95 : 0.0)
                        .animation(
                            .easeInOut(duration: 0.85)
                                .delay(Double(index) * 0.09),
                            value: animate
                        )
                }
            }
        }
    }

    private func targetX(for index: Int, width: CGFloat, partnerCount: Int) -> CGFloat {
        let slot = index % partnerCount
        let spacing = width / CGFloat(partnerCount + 1)
        return spacing * CGFloat(slot + 1)
    }
}

enum OutcomeState {
    case none
    case saved
    case override
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
                    .fill(LinearGradient(colors: [KommitTheme.cardPrimary.opacity(0.92), KommitTheme.cardSecondary.opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: KommitTheme.accentBlue.opacity(0.12), radius: 12, y: 8)
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
                    LinearGradient(colors: [KommitTheme.accentBlue, KommitTheme.accentCyan], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .shadow(color: KommitTheme.accentBlue.opacity(0.5), radius: 10)
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
                .background(isSelected ? KommitTheme.accentBlue.opacity(0.35) : .white.opacity(0.06))
                .overlay(Capsule().stroke(isSelected ? KommitTheme.accentCyan : .white.opacity(0.15), lineWidth: 1))
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
                    Circle().fill(KommitTheme.cardSecondary)
                    Text(partner.initials)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 66, height: 66)
            .clipShape(Circle())
            .overlay(Circle().stroke(isSelected ? KommitTheme.accentCyan : .white.opacity(0.18), lineWidth: 2))

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(KommitTheme.success)
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
                if let imageName = brand.imageName, UIImage(named: imageName) != nil {
                    Circle()
                        .fill(.white)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Circle().fill(.white.opacity(0.08))
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
            KommitTheme.background
            RadialGradient(colors: [KommitTheme.accentBlue.opacity(0.26), .clear], center: animate ? .topLeading : .bottomTrailing, startRadius: 80, endRadius: 500)
            RadialGradient(colors: [KommitTheme.accentCyan.opacity(0.18), .clear], center: animate ? .bottomTrailing : .topLeading, startRadius: 70, endRadius: 460)
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
            .background(RoundedRectangle(cornerRadius: 12).fill(KommitTheme.success.opacity(0.85)))
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
                    .foregroundStyle(tab.0 == "Home" ? KommitTheme.accentCyan : .white.opacity(0.7))
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
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position

    init(preferredPosition: AVCaptureDevice.Position = .back) {
        self.currentPosition = preferredPosition
        configure()
    }

    private func configure() {
        guard let input = makeInput(for: currentPosition) else { return }

        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        session.commitConfiguration()
        session.startRunning()
    }

    func flipCamera() {
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        guard let newInput = makeInput(for: newPosition) else { return }
        session.beginConfiguration()
        if let currentInput {
            session.removeInput(currentInput)
        }
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            self.currentInput = newInput
            currentPosition = newPosition
        }
        session.commitConfiguration()
    }

    private func makeInput(for position: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            return nil
        }
        return try? AVCaptureDeviceInput(device: device)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var model: CameraSessionModel

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
            LinearGradient(colors: [KommitTheme.cardSecondary, KommitTheme.background], startPoint: .top, endPoint: .bottom)
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
