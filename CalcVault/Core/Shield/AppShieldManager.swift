import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings

/// مدير التحكم بإخفاء وتأمين تطبيقات الآيفون عبر Screen Time & ManagedSettings APIs
@MainActor
public final class AppShieldManager: ObservableObject {
    
    public static let shared = AppShieldManager()
    
    // مخزن إعدادات آبل الرسمية
    private let store = ManagedSettingsStore()
    
    // مفتاح حفظ التطبيقات المختارة محلياً
    private let kSelectedAppsStorageKey = "calcvault.shield.selected_apps"
    private let kShieldActiveStorageKey = "calcvault.shield.is_active"
    
    /// التطبيقات المختارة للإخفاء (رموز مشفرة من آبل تحفظ خصوصية المستخدم)
    @Published public var activitySelection: FamilyActivitySelection {
        didSet {
            saveSelection()
        }
    }
    
    /// هل وضع الإخفاء نشط حالياً؟
    @Published public var isShieldActive: Bool = false
    
    /// حالة تفويض الصلاحية من آبل
    @Published public var isAuthorized: Bool = false
    
    private init() {
        // استرجاع التطبيقات المحفوظة سابقاً
        if let data = UserDefaults.standard.data(forKey: kSelectedAppsStorageKey),
           let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = decoded
        } else {
            self.activitySelection = FamilyActivitySelection()
        }
        
        self.isShieldActive = UserDefaults.standard.bool(forKey: kShieldActiveStorageKey)
        checkAuthorization()
    }
    
    // MARK: - طلب إذن Screen Time من آبل
    public func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            checkAuthorization()
        } catch {
            print("خطأ في تفويض FamilyControls: \(error.localizedDescription)")
            self.isAuthorized = false
        }
    }
    
    public func checkAuthorization() {
        self.isAuthorized = (AuthorizationCenter.shared.authorizationStatus == .approved)
    }
    
    // MARK: - تفعيل الإخفاء الفوري (Hide All Selected Apps)
    public func hideAll() {
        guard !activitySelection.applicationTokens.isEmpty else {
            print("لا توجد تطبيقات مختارة للإخفاء.")
            return
        }
        
        // 1. إخفاء التطبيقات تماماً من الشاشة الرئيسية، مكتبة التطبيقات، ونتائج البحث
        store.application.blockedApplications = activitySelection.applicationTokens
        
        // 2. درع أمان إضافي للحجب
        store.shield.applications = activitySelection.applicationTokens
        
        isShieldActive = true
        UserDefaults.standard.set(true, forKey: kShieldActiveStorageKey)
    }
    
    // MARK: - إلغاء الإخفاء واستعادة التطبيقات (Unhide All)
    public func unhideAll() {
        // إزالة الحجب والإخفاء لتعود التطبيقات للشاشة الرئيسية
        store.application.blockedApplications = nil
        store.shield.applications = nil
        
        isShieldActive = false
        UserDefaults.standard.set(false, forKey: kShieldActiveStorageKey)
    }
    
    // MARK: - التبديل التلقائي
    public func toggleShield() {
        if isShieldActive {
            unhideAll()
        } else {
            hideAll()
        }
    }
    
    // MARK: - حفظ التطبيقات المحددة
    private func saveSelection() {
        if let encoded = try? PropertyListEncoder().encode(activitySelection) {
            UserDefaults.standard.set(encoded, forKey: kSelectedAppsStorageKey)
        }
        // إذا كان الإخفاء مفعلاً أثناء التعديل، نحدث القائمة فوراً
        if isShieldActive {
            hideAll()
        }
    }
}
