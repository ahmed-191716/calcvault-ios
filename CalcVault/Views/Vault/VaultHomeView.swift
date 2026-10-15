import SwiftUI

/// الواجهة الرئيسية للخزانة السرية الحقيقية (Real Vault)
public struct VaultHomeView: View {
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var shield = AppShieldManager.shared
    
    public init() {}
    
    public var body: some View {
        TabView {
            // التبويب 1: قاذف التطبيقات السري المباشر (بدون بصمة!)
            NavigationView {
                SecretAppLauncherView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            panicLockToolbarButton
                        }
                    }
            }
            .tabItem {
                Label("تطبيقاتي", systemImage: "square.grid.2x2.fill")
            }
            
            // التبويب 2: التحكم بصلاحية إخفاء التطبيقات من النظام
            NavigationView {
                AppShieldView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            panicLockToolbarButton
                        }
                    }
            }
            .tabItem {
                Label("درع الإخفاء", systemImage: "eye.slash.fill")
            }
            
            // التبويب 3: الملاحظات المشفرة
            NavigationView {
                SecretNotesView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            panicLockToolbarButton
                        }
                    }
            }
            .tabItem {
                Label("ملاحظات", systemImage: "note.text")
            }
            
            // التبويب 4: الأمان وتغيير الرمز
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
