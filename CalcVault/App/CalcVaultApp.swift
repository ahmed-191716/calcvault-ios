import SwiftUI

@main
struct CalcVaultApp: App {
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                switch auth.state {
                case .locked, .setupRequired:
                    CalculatorView()
                        .transition(.opacity)
                case .unlockedReal:
                    VaultHomeView()
                        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                case .unlockedDecoy:
                    DecoyVaultView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: auth.state)
            // قفل فوري ومسح مفاتيح التشفير بمجرد الخروج من التطبيق أو قفل الشاشة
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background || newPhase == .inactive {
                    auth.lock()
                }
            }
        }
    }
}
