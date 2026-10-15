import SwiftUI

/// زر الآلة الحاسبة بمظهر وملمس أزرار iOS الأصلية المطابقة 100%
public struct CalculatorButton: View {
    let type: CalcButtonType
    let size: CGFloat
    let isSelected: Bool
    let customTitle: String?
    let action: () -> Void
    
    public init(
        type: CalcButtonType,
        size: CGFloat,
        isSelected: Bool = false,
        customTitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.size = size
        self.isSelected = isSelected
        self.customTitle = customTitle
        self.action = action
    }
    
    private var titleText: String {
        if let custom = customTitle {
            return custom
        }
        return type.title
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .white
        }
        
        switch type {
        case .clear, .toggleSign, .percent:
            // الرمادي الفاتح لأزرار الوظائف العليا
            return Color(red: 0.65, green: 0.65, blue: 0.65)
        case .operation, .equals:
            // برتقالي آبل الكلاسيكي
            return Color(red: 1.0, green: 0.62, blue: 0.04)
        case .digit, .decimal:
            // الرمادي الداكن للأرقام
            return Color(red: 0.20, green: 0.20, blue: 0.20)
        }
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return Color(red: 1.0, green: 0.62, blue: 0.04)
        }
        
        switch type {
        case .clear, .toggleSign, .percent:
            return .black
        default:
            return .white
        }
    }
    
    public var body: some View {
        Button(action: action) {
            if case .digit(0) = type {
                // زر الصفر العريض: يأخذ مساحة زرين مع الفراغ بينهما
                let zeroWidth = (size * 2) + 14
                HStack {
                    Text(titleText)
                        .font(.system(size: size * 0.44, weight: .regular))
                        .foregroundColor(foregroundColor)
                        .padding(.leading, (size - (size * 0.44)) / 2 + 10)
                    Spacer()
                }
                .frame(width: zeroWidth, height: size)
                .background(backgroundColor)
                .clipShape(Capsule())
            } else {
                Text(titleText)
                    .font(.system(size: size * 0.44, weight: isOperation ? .medium : .regular))
                    .foregroundColor(foregroundColor)
                    .frame(width: size, height: size)
                    .background(backgroundColor)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(CalcButtonStyle())
    }
    
    private var isOperation: Bool {
        if case .operation = type { return true }
        if case .equals = type { return true }
        return false
    }
}

/// تأثير الضغط الاحترافي المطابق لنظام iOS
struct CalcButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.15 : 0.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
