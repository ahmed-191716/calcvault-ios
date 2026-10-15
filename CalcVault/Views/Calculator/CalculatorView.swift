import SwiftUI

/// الواجهة التمويهية الكاملة: آلة حاسبة أصلية 100% تطابق تصميم آبل الرسمي بدقة
public struct CalculatorView: View {
    @StateObject private var model = CalculatorModel()
    @ObservedObject private var auth = AuthManager.shared
    
    // إشعار الإعداد لأول مرة
    @State private var showSetupSheet = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var setupErrorMessage: String?
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            // قياسات دقيقة مطابقة لآلة آبل الحاسبة
            let spacing: CGFloat = 14
            let horizontalPadding: CGFloat = 16
            let availableWidth = min(geometry.size.width - (horizontalPadding * 2), 430)
            let buttonSize = floor((availableWidth - (spacing * 3)) / 4)
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: spacing) {
                    Spacer()
                    
                    // شاشة عرض الأرقام الكبيرة
                    HStack {
                        Spacer()
                        Text(model.displayText)
                            .font(.system(size: textSize(for: model.displayText), weight: .light))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.35)
                            .padding(.horizontal, 20)
                            // ضغطة سرية مطولة للطوارئ أو أول تشغيل
                            .onLongPressGesture(minimumDuration: 3.0) {
                                if auth.state == .setupRequired {
                                    showSetupSheet = true
                                }
                            }
                    }
                    .padding(.bottom, 8)
                    
                    // شبكة الأزرار - فرض الاتجاه من اليسار لليمين لضمان عدم انقلاب الأرقام بالعربية
                    VStack(spacing: spacing) {
                        // الصف 1: AC/C, ±, %, ÷
                        HStack(spacing: spacing) {
                            CalculatorButton(
                                type: .clear,
                                size: buttonSize,
                                customTitle: model.clearButtonTitle
                            ) { model.buttonTapped(.clear) }
                            
                            CalculatorButton(type: .toggleSign, size: buttonSize) { model.buttonTapped(.toggleSign) }
                            CalculatorButton(type: .percent, size: buttonSize) { model.buttonTapped(.percent) }
                            
                            CalculatorButton(
                                type: .operation(.divide),
                                size: buttonSize,
                                isSelected: model.activeOperation == .divide
                            ) { model.buttonTapped(.operation(.divide)) }
                        }
                        
                        // الصف 2: 7, 8, 9, ×
                        HStack(spacing: spacing) {
                            CalculatorButton(type: .digit(7), size: buttonSize) { model.buttonTapped(.digit(7)) }
                            CalculatorButton(type: .digit(8), size: buttonSize) { model.buttonTapped(.digit(8)) }
                            CalculatorButton(type: .digit(9), size: buttonSize) { model.buttonTapped(.digit(9)) }
                            
                            CalculatorButton(
                                type: .operation(.multiply),
                                size: buttonSize,
                                isSelected: model.activeOperation == .multiply
                            ) { model.buttonTapped(.operation(.multiply)) }
                        }
                        
                        // الصف 3: 4, 5, 6, −
                        HStack(spacing: spacing) {
                            CalculatorButton(type: .digit(4), size: buttonSize) { model.buttonTapped(.digit(4)) }
                            CalculatorButton(type: .digit(5), size: buttonSize) { model.buttonTapped(.digit(5)) }
                            CalculatorButton(type: .digit(6), size: buttonSize) { model.buttonTapped(.digit(6)) }
                            
                            CalculatorButton(
                                type: .operation(.subtract),
                                size: buttonSize,
                                isSelected: model.activeOperation == .subtract
                            ) { model.buttonTapped(.operation(.subtract)) }
                        }
                        
                        // الصف 4: 1, 2, 3, +
                        HStack(spacing: spacing) {
                            CalculatorButton(type: .digit(1), size: buttonSize) { model.buttonTapped(.digit(1)) }
                            CalculatorButton(type: .digit(2), size: buttonSize) { model.buttonTapped(.digit(2)) }
                            CalculatorButton(type: .digit(3), size: buttonSize) { model.buttonTapped(.digit(3)) }
                            
                            CalculatorButton(
                                type: .operation(.add),
                                size: buttonSize,
                                isSelected: model.activeOperation == .add
                            ) { model.buttonTapped(.operation(.add)) }
                        }
                        
                        // الصف 5: 0 (عريض), ., =
                        HStack(spacing: spacing) {
                            CalculatorButton(type: .digit(0), size: buttonSize) { model.buttonTapped(.digit(0)) }
                            CalculatorButton(type: .decimal, size: buttonSize) { model.buttonTapped(.decimal) }
                            CalculatorButton(type: .equals, size: buttonSize) { model.buttonTapped(.equals) }
                        }
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
                .padding(.horizontal, horizontalPadding)
            }
            .environment(\.layoutDirection, .leftToRight)
            .sheet(isPresented: $showSetupSheet) {
                initialSetupSheet
            }
            .onAppear {
                if auth.state == .setupRequired {
                    showSetupSheet = true
                }
            }
        }
    }
    
    private func textSize(for text: String) -> CGFloat {
        if text.count > 8 { return 52 }
        if text.count > 6 { return 66 }
        return 86
    }
    
    // MARK: - نافذة الإعداد لأول مرة
    private var initialSetupSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("إعداد الرمز السري").font(.headline)) {
                    Text("اختر رمزاً من 4 إلى 8 أرقام. عند كتابته في الآلة الحاسبة والضغط على (=) ستفتح خيانتك السرية مباشرة.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    SecureField("أدخل الرمز السري", text: $newPasscode)
                        .keyboardType(.numberPad)
                    
                    SecureField("تأكيد الرمز السري", text: $confirmPasscode)
                        .keyboardType(.numberPad)
                    
                    if let err = setupErrorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("حفظ وتأمين الخزانة") {
                        if newPasscode.count < 4 {
                            setupErrorMessage = "يجب أن يتكون الرمز من 4 أرقام على الأقل."
                            return
                        }
                        if newPasscode != confirmPasscode {
                            setupErrorMessage = "الرمزان غير متطابقين."
                            return
                        }
                        if auth.setMasterPasscode(newPasscode) {
                            showSetupSheet = false
                        } else {
                            setupErrorMessage = "حدث خطأ أثناء حفظ التشفير."
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("تهيئة الحماية")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
