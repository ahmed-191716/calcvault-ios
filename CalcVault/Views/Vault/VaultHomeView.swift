import SwiftUI

/// الواجهة الرئيسية للخزانة السرية الحقيقية (Real Vault)
public struct VaultHomeView: View {
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var shield = AppShieldManager.shared
    
    public init() {}
    
    public var body: some View {
        TabView {
            // التبويب 1: إخفاء التطبيقات
            NavigationView {
                AppShieldView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            panicLockToolbarButton
                        }
                    }
            }
            .tabItem {
                Label("إخفاء التطبيقات", systemImage: "eye.slash.fill")
            }
            
            // التبويب 2: الملاحظات السرية
            NavigationView {
                SecretNotesView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            panicLockToolbarButton
                        }
                    }
            }
            .tabItem {
                Label("ملاحظات مشفرة", systemImage: "note.text")
            }
            
            // التبويب 3: الإعدادات والأمان
            NavigationView {
                VaultSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            panicLockToolbarButton
                        }
                    }
            }
            .tabItem {
                Label("الأمان", systemImage: "shield.lefthalf.filled")
            }
        }
        .accentColor(.orange)
    }
    
    // زر القفل الفوري والسريع في شريط الأدوات العلوي
    private var panicLockToolbarButton: some View {
        Button(action: {
            auth.panicLock()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                Text("قفل فوري")
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.red)
            .cornerRadius(14)
        }
    }
}
