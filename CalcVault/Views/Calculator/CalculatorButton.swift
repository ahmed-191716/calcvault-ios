import SwiftUI

/// زر الآلة الحاسبة بمظهر وملمس أزرار iOS الأصلية
public struct CalculatorButton: View {
    let type: CalcButtonType
    let size: CGFloat
    let action: () -> Void
    
    public init(type: CalcButtonType, size: CGFloat, action: @escaping () -> Void) {
        self.type = type
        self.size = size
        self.action = action
    }
    
    private var backgroundColor: Color {
        switch type {
        case .clear, .toggleSign, .percent:
            return Color(red: 0.64, green: 0.64, blue: 0.64)
        case .operation, .equals:
            return Color(red: 0.98, green: 0.58, blue: 0.11)
        case .digit, .decimal:
            return Color(red: 0.20, green: 0.20, blue: 0.20)
        }
    }
    
    private var foregroundColor: Color {
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
                // زر الصفر عريض في الآلة الأصلية
                HStack {
                    Text(type.title)
                        .font(.system(size: size * 0.42, weight: .regular))
                        .foregroundColor(foregroundColor)
                        .padding(.leading, size * 0.35)
                    Spacer()
                }
                .frame(width: (size * 2) + 12, height: size)
                .background(backgroundColor)
                .clipShape(Capsule())
            } else {
                Text(type.title)
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundColor(foregroundColor)
                    .frame(width: size, height: size)
                    .background(backgroundColor)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(CalcButtonStyle())
    }
}

/// تأثير الضغط السلس
struct CalcButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
