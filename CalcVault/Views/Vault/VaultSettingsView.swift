import SwiftUI

/// إعدادات الأمان، تغيير الرموز، ورمز الإكراه
public struct VaultSettingsView: View {
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var shield = AppShieldManager.shared
    
    // تغيير الرمز الرئيسي
    @State private var newMasterPasscode = ""
    @State private var confirmMasterPasscode = ""
    @State private var masterStatusMessage: String?
    
    // إعداد رمز الإكراه
    @State private var newDuressPasscode = ""
    @State private var duressStatusMessage: String?
    
    public init() {}
    
    public var body: some View {
        List {
            // قسم رمز الإكراه (Duress PIN)
            Section(header: Text("رمز الطوارئ والإكراه (Duress Code)"), footer: Text("إذا أُجبرت على فتح الهاتف والتطبيق، أدخل هذا الرمز في الآلة الحاسبة. سيفتح واجهة وهمية تبدو كأنها مذكرات عادية للتسوق والعمل، ولن تظهر أي أثر لتطبيقاتك أو ملفاتك المخفية.")) {
                SecureField("أدخل رمز الإكراه (4-8 أرقام)", text: $newDuressPasscode)
                    .keyboardType(.numberPad)
                
                Button(action: saveDuressCode) {
                    HStack {
                        Image(systemName: "shield.slash.fill")
                            .foregroundColor(.orange)
                        Text("حفظ رمز الإكراه")
                            .foregroundColor(.primary)
                    }
                }
                .disabled(newDuressPasscode.count < 4)
                
                if let msg = duressStatusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // تغيير الرمز السري الحقيقي
            Section(header: Text("تغيير الرمز السري الرئيسي")) {
                SecureField("الرمز السري الجديد", text: $newMasterPasscode)
                    .keyboardType(.numberPad)
                
                SecureField("تأكيد الرمز الجديد", text: $confirmMasterPasscode)
                    .keyboardType(.numberPad)
                
                Button(action: changeMasterCode) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                        Text("تحديث الرمز الرئيسي")
                    }
                }
                .disabled(newMasterPasscode.count < 4 || newMasterPasscode != confirmMasterPasscode)
                
                if let msg = masterStatusMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(msg.contains("نجاح") ? .green : .red)
                }
            }
            
            // تدقيق الأمان والخصوصية (Security Audit)
            Section(header: Text("مؤشرات الأمان والخصوصية")) {
                statusRow(title: "معيار التشفير", value: "AES-GCM 256-bit", icon: "lock.shield.fill", color: .green)
                statusRow(title: "حماية الهاش والملح", value: "iOS Keychain (Enclave)", icon: "key.horizontal.fill", color: .green)
                statusRow(title: "الاتصال الخارجي", value: "محلي 100% (صفر إنترنت)", icon: "wifi.slash", color: .blue)
                statusRow(title: "قاعدة البيانات السحابية", value: "غير مستخدمة (0$ تكاليف)", icon: "server.rack", color: .blue)
                statusRow(title: "التوافق مع النظام", value: "iOS 27 Screen Time API", icon: "applelogo", color: .purple)
            }
            
            // زر الخروج وقفل الخزانة
            Section {
                Button(action: {
                    auth.lock()
                }) {
                    HStack {
                        Spacer()
                        Label("قفل الخزانة والعودة للآلة الحاسبة", systemImage: "lock.fill")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("إعدادات الأمان")
    }
    
    private func saveDuressCode() {
        if auth.setDuressPasscode(newDuressPasscode) {
            duressStatusMessage = "تم حفظ رمز الإكراه بنجاح. عند كتابته والضغط على (=) ستفتح الخزانة الوهمية."
            newDuressPasscode = ""
        } else {
            duressStatusMessage = "فشل حفظ رمز الإكراه."
        }
    }
    
    private func changeMasterCode() {
        if auth.setMasterPasscode(newMasterPasscode) {
            masterStatusMessage = "تم تحديث الرمز السري بنجاح."
            newMasterPasscode = ""
            confirmMasterPasscode = ""
        } else {
            masterStatusMessage = "حدث خطأ أثناء حفظ الرمز."
        }
    }
    
    private func statusRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
