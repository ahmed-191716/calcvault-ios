import Foundation
import SwiftUI

/// أنواع أزرار الآلة الحاسبة
public enum CalcButtonType: Hashable {
    case digit(Int)
    case decimal
    case operation(CalcOperation)
    case clear
    case toggleSign
    case percent
    case equals
    
    public var title: String {
        switch self {
        case .digit(let n): return "\(n)"
        case .decimal: return "."
        case .operation(let op): return op.symbol
        case .clear: return "AC"
        case .toggleSign: return "±"
        case .percent: return "%"
        case .equals: return "="
        }
    }
}

public enum CalcOperation: Hashable {
    case add, subtract, multiply, divide
    
    public var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }
}

/// المحرك الحسابي للآلة الحاسبة مع رصد الرمز السري دون لفت الانتباه
@MainActor
public final class CalculatorModel: ObservableObject {
    
    @Published public var displayText: String = "0"
    @Published public var activeOperation: CalcOperation? = nil
    
    // تسجيل الأرقام المتتالية لاكتشاف الرمز السري
    private var enteredDigitSequence: String = ""
    
    private var storedNumber: Double? = nil
    private var isTypingFreshNumber: Bool = true
    
    public var clearButtonTitle: String {
        if isTypingFreshNumber && displayText == "0" {
            return "AC"
        } else {
            return "C"
        }
    }
    
    // MARK: - التعامل مع ضغط الأزرار
    public func buttonTapped(_ button: CalcButtonType) {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
        
        switch button {
        case .digit(let n):
            handleDigit(n)
        case .decimal:
            handleDecimal()
        case .clear:
            handleClear()
        case .toggleSign:
            handleToggleSign()
        case .percent:
            handlePercent()
        case .operation(let op):
            handleOperation(op)
        case .equals:
            handleEquals()
        }
    }
    
    private func handleDigit(_ n: Int) {
        activeOperation = nil
        enteredDigitSequence.append("\(n)")
        
        if isTypingFreshNumber || displayText == "0" {
            displayText = "\(n)"
            isTypingFreshNumber = false
        } else {
            if displayText.replacingOccurrences(of: ".", with: "").count < 9 {
                displayText.append("\(n)")
            }
        }
    }
    
    private func handleDecimal() {
        activeOperation = nil
        if isTypingFreshNumber {
            displayText = "0."
            isTypingFreshNumber = false
        } else if !displayText.contains(".") {
            displayText.append(".")
        }
    }
    
    private func handleClear() {
        if displayText != "0" && !isTypingFreshNumber {
            // مسح الشاشة الحالية فقط (C)
            displayText = "0"
            isTypingFreshNumber = true
        } else {
            // مسح كلي (AC)
            displayText = "0"
            storedNumber = nil
            activeOperation = nil
            isTypingFreshNumber = true
            enteredDigitSequence = ""
        }
    }
    
    private func handleToggleSign() {
        if let val = Double(displayText), val != 0 {
            let inverted = -val
            displayText = formatResult(inverted)
        }
    }
    
    private func handlePercent() {
        if let val = Double(displayText) {
            let result = val / 100.0
            displayText = formatResult(result)
        }
    }
    
    private func handleOperation(_ op: CalcOperation) {
        if let val = Double(displayText) {
            if let stored = storedNumber, let currentOp = activeOperation, !isTypingFreshNumber {
                let res = calculate(stored, currentOp, val)
                storedNumber = res
                displayText = formatResult(res)
            } else {
                storedNumber = val
            }
        }
        activeOperation = op
        isTypingFreshNumber = true
    }
    
    private func handleEquals() {
        // 1. فحص هل الأرقام المدخلة تطابق الرمز السري (الفتح السري)!
        let secretCandidate = enteredDigitSequence
        
        if AuthManager.shared.state == .setupRequired {
            // إذا لم يتم تحديد رمز مسبقاً وكان المدخل 4 أرقام أو أكثر، يتم اعتماده
            if secretCandidate.count >= 4 {
                if AuthManager.shared.setMasterPasscode(secretCandidate) {
                    displayText = "0"
                    enteredDigitSequence = ""
                    activeOperation = nil
                    return
                }
            }
        } else {
            // فحص المصادقة ضد الرمز السري الحقيقي أو رمز الإكراه
            if !secretCandidate.isEmpty && AuthManager.shared.evaluatePasscode(secretCandidate) {
                // تم الفتح بنجاح! يتم تصفير الآلة فوراً
                handleClear()
                return
            }
        }
        
        // 2. إذا لم يكن رمزاً سرياً، نقوم بالحساب الطبيعي كأي آلة حاسبة دون أن يشك أحد!
        if let stored = storedNumber, let op = activeOperation, let current = Double(displayText) {
            let result = calculate(stored, op, current)
            displayText = formatResult(result)
            storedNumber = nil
            activeOperation = nil
            isTypingFreshNumber = true
        }
        
        // إعادة تهيئة تتبع الرمز
        enteredDigitSequence = ""
    }
    
    private func calculate(_ a: Double, _ op: CalcOperation, _ b: Double) -> Double {
        switch op {
        case .add: return a + b
        case .subtract: return a - b
        case .multiply: return a * b
        case .divide: return b == 0 ? 0 : a / b
        }
    }
    
    private func formatResult(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 && val < Double(Int.max) && val > Double(Int.min) {
            return "\(Int(val))"
        }
        return String(format: "%.6g", val)
    }
}
