import SwiftUI
import FamilyControls
import ManagedSettings

/// واجهة إدارة إخفاء التطبيقات والتحكم بالرمز السري
public struct AppShieldView: View {
    @ObservedObject private var shieldManager = AppShieldManager.shared
    @ObservedObject private var auth = AuthManager.shared
    
    @State private var showPicker = false
    @State private var showChangePasscodeSheet = false
    @State private var showAlertError = false
    
    // متغيرات تغيير الرمز
    @State private var newCode = ""
    @State private var confirmNewCode = ""
    @State private var passcodeErrorMessage: String?
    @State private var passcodeSuccessToast = false
    
    public init() {}
    
    public var body: some View {
        List {
            // قسم تغيير الرمز السري المباشر
            Section {
                Button(action: {
                    newCode = ""
                    confirmNewCode = ""
                    passcodeErrorMessage = nil
                    showChangePasscodeSheet = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange)
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("تغيير رمز الدخول السري")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("اضغط لتعديل الرمز الذي يفتح هذه الخزانة من الآلة الحاسبة")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // قسم حالة صلاحية آبل Screen Time
            Section(header: Text("التحكم البرمجي بالتطبيقات (Screen Time API)")) {
                if !shieldManager.isAuthorized {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("صلاحية آبل مقيدة بحساب المطور", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("عند تثبيت التطبيقات عبر Sideloadly بحساب Apple ID مجاني، تمنع آبل تفويض واجهة FamilyControls خارج متجر App Store الرسمي.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            Task {
                                await shieldManager.requestAuthorization()
                                if shieldManager.authorizationError != nil {
                                    showAlertError = true
                                }
                            }
                        }) {
                            Text("محاولة طلب الصلاحية")
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
                        Text("نشط")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }
            
            // مفتاح الإخفاء إذا كانت الصلاحية متوفرة
            if shieldManager.isAuthorized {
                Section(header: Text("التحكم السريع بالإخفاء")) {
                    Toggle(isOn: Binding(
                        get: { shieldManager.isShieldActive },
                        set: { _ in shieldManager.toggleShield() }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shieldManager.isShieldActive ? "التطبيقات مخفية الآن" : "التطبيقات ظاهرة حالياً")
                                .font(.headline)
                                .foregroundColor(shieldManager.isShieldActive ? .red : .primary)
                            Text(shieldManager.isShieldActive ? "البرامج غير مرئية في الشاشة والبحث." : "البرامج تظهر بشكل طبيعي.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: { showPicker = true }) {
                        HStack {
                            Image(systemName: "square.grid.3x3.fill")
                                .foregroundColor(.blue)
                            Text("تحديد التطبيقات المستهدفة")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(shieldManager.activitySelection.applicationTokens.count) تطبيق")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // طريقة آبل المدمجة الرسمية في iOS 27 (تعمل 100% فوراً على جهازك!)
            Section(header: Text("طريقة آبل المدمجة في iOS 27 (بدون أذونات) ⭐️")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("في نظام iOS 27، وفرت آبل ميزة مدمجة خارقة لإخفاء أي تطبيق بدون الحاجة لأي صلاحيات مطورين:")
                        .font(.footnote)
                        .foregroundColor(.primary)
                    
                    guideStep(num: "1", text: "اخرج للشاشة الرئيسية واضغط ضغطة مطولة على أي تطبيق تريد إخفاءه (واتساب، بنوك، صور).")
                    guideStep(num: "2", text: "اختر من القائمة: \"طلب Face ID\" (Require Face ID).")
                    guideStep(num: "3", text: "اضغط على: \"إخفاء وطلب Face ID\" (Hide and Require Face ID).")
                    guideStep(num: "4", text: "يختفي التطبيق فوراً من الشاشة الرئيسية، وتتوقف إشعاراته ولا يظهر في البحث!")
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("الخزانة السرية")
        .alert(isPresented: $showAlertError) {
            Alert(
                title: Text("تنبيه بخصوص صلاحيات آبل"),
                message: Text(shieldManager.authorizationError ?? "تقيّد آبل إذن Screen Time للتطبيقات المثبتة بحساب مجاني خارج المتجر. يمكنك استخدام طريقة iOS 27 المدمجة الموضحة في الأسفل لإخفاء أي تطبيق بضغطة زر واحدة مجاناً وبدون أي قيود!"),
                dismissButton: .default(Text("فهمت"))
            )
        }
        .sheet(isPresented: $showChangePasscodeSheet) {
            changePasscodeSheet
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $shieldManager.activitySelection)
    }
    
    private func guideStep(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.orange)
                .clipShape(Circle())
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - نافذة تغيير الرمز السري المباشرة
    private var changePasscodeSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("تعديل رمز الدخول")) {
                    Text("أدخل رمزك الجديد (من 4 إلى 8 أرقام). هذا هو الرمز الذي ستكتبه في الآلة الحاسبة متبوعاً بزر (=) لفتح الخزانة.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    SecureField("الرمز السري الجديد", text: $newCode)
                        .keyboardType(.numberPad)
                    
                    SecureField("تأكيد الرمز السري الجديد", text: $confirmNewCode)
                        .keyboardType(.numberPad)
                    
                    if let err = passcodeErrorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if passcodeSuccessToast {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("تم تحديث رمز الدخول السري بنجاح!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section {
                    Button(action: saveNewPasscode) {
                        Text("حفظ الرمز الجديد الآن")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.orange)
                    .disabled(newCode.count < 4 || newCode != confirmNewCode)
                }
            }
            .navigationTitle("تغيير الرمز السري")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") {
                        showChangePasscodeSheet = false
                    }
                }
            }
        }
    }
    
    private func saveNewPasscode() {
        if newCode.count < 4 {
            passcodeErrorMessage = "يجب أن يتكون الرمز من 4 أرقام على الأقل."
            return
        }
        if newCode != confirmNewCode {
            passcodeErrorMessage = "الرمزان غير متطابقين."
            return
        }
        
        if auth.setMasterPasscode(newCode) {
            passcodeSuccessToast = true
            passcodeErrorMessage = nil
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showChangePasscodeSheet = false
                passcodeSuccessToast = false
            }
        } else {
            passcodeErrorMessage = "حدث خطأ أثناء حفظ التشفير."
        }
    }
}
