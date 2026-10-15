import SwiftUI
import FamilyControls
import ManagedSettings

/// واجهة إدارة إخفاء التطبيقات باستخدام Screen Time API المتوافق مع iOS 27
public struct AppShieldView: View {
    @ObservedObject private var shieldManager = AppShieldManager.shared
    @State private var showPicker = false
    
    public init() {}
    
    public var body: some View {
        List {
            // قسم حالة الصلاحية
            Section {
                if !shieldManager.isAuthorized {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("صلاحية التحكم بالتطبيقات مطلوبة", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("يتطلب نظام iOS إذن Screen Time لتمكين التطبيق من إخفاء البرامج من الشاشة الرئيسية ومكتبة التطبيقات بشكل آمن ومشفر.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            Task {
                                await shieldManager.requestAuthorization()
                            }
                        }) {
                            Text("منح الصلاحية الآن")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } else {
                    HStack {
                        Label("صلاحية آبل مفعلة", systemImage: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Spacer()
                        Text("متوافق")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }
            
            // مفتاح الإخفاء الرئيسي الفوري
            Section(header: Text("التحكم السريع بالإخفاء")) {
                Toggle(isOn: Binding(
                    get: { shieldManager.isShieldActive },
                    set: { _ in shieldManager.toggleShield() }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shieldManager.isShieldActive ? "التطبيقات مخفية الآن" : "التطبيقات ظاهرة حالياً")
                            .font(.headline)
                            .foregroundColor(shieldManager.isShieldActive ? .red : .primary)
                        
                        Text(shieldManager.isShieldActive ? "البرامج غير مرئية في الشاشة الرئيسية والبحث." : "البرامج تظهر بشكل طبيعي.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!shieldManager.isAuthorized || shieldManager.activitySelection.applicationTokens.isEmpty)
                
                if shieldManager.activitySelection.applicationTokens.isEmpty {
                    Text("يرجى اختيار تطبيق واحد على الأقل من الأسفل لتفعيل زر الإخفاء.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // اختيار التطبيقات المستهدفة
            Section(header: Text("قائمة التطبيقات المستهدفة")) {
                Button(action: {
                    showPicker = true
                }) {
                    HStack {
                        Image(systemName: "square.grid.3x3.fill")
                            .foregroundColor(.blue)
                        Text("تحديد / تعديل التطبيقات المخفية")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(shieldManager.activitySelection.applicationTokens.count) تطبيق")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!shieldManager.isAuthorized)
            }
            
            // تعليمات الأمان والخصوصية
            Section(header: Text("كيف يعمل الإخفاء في iOS 27؟")) {
                VStack(alignment: .leading, spacing: 6) {
                    bulletPoint(text: "يتم مسح أيقونات البرامج تماماً من الشاشة الرئيسية ومكتبة التطبيقات (App Library).")
                    bulletPoint(text: "لا تظهر البرامج في نتائج البحث (Spotlight) أثناء تفعيل الإخفاء.")
                    bulletPoint(text: "تتوقف الإشعارات القادمة من البرامج المخفية لحمايتك من التطفل.")
                    bulletPoint(text: "لا يمكن لأحد معرفة أن البرامج مثبتة في الهاتف إلا بعد فتح الخزانة.")
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("إخفاء التطبيقات")
        .familyActivityPicker(isPresented: $showPicker, selection: $shieldManager.activitySelection)
    }
    
    private func bulletPoint(text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
