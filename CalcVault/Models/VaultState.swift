import Foundation

/// حالات أمان التطبيق
public enum VaultState: Equatable {
    /// الوضع العادي: واجهة الآلة الحاسبة التمويهية نشطة
    case locked
    /// تم إدخال الرمز السري الحقيقي: فتح الخزانة الحقيقية وإدارة التطبيقات المخفية
    case unlockedReal
    /// تم إدخال رمز الإكراه/الطوارئ: فتح واجهة وهمية بريئة تماماً
    case unlockedDecoy
    /// الإعداد الأولي: تحديد رمز المرور لأول مرة
    case setupRequired
}
