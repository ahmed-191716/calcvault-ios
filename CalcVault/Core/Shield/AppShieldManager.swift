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
    
    /// رسالة تشخيص الخطأ في حال رفض النظام للأذونات
    @Published public var authorizationError: String? = nil
    
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
            if !isAuthorized {
                self.authorizationError = "لم يتم تفعيل الإذن من النظام. تقيّد آبل واجهات Screen Time على الحسابات المجانية خارج المتجر."
            } else {
                self.authorizationError = nil
            }
        } catch {
            print("خطأ في تفويض FamilyControls: \(error.localizedDescription)")
            self.isAuthorized = false
            self.authorizationError = "تقيّد آبل صلاحية FamilyControls على حسابات Apple ID المجانية عند التثبيت الجانبي (\(error.localizedDescription))."
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
        
        // درع أمان لحجب وإخفاء التطبيقات المختارة
        store.shield.applications = activitySelection.applicationTokens
        
        isShieldActive = true
        UserDefaults.standard.set(true, forKey: kShieldActiveStorageKey)
    }
    
    // MARK: - إلغاء الإخفاء واستعادة التطبيقات (Unhide All)
    public func unhideAll() {
        // إزالة الحجب لتعود التطبيقات
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
