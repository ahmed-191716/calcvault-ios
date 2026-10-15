import Foundation
import SwiftUI
import CryptoKit

/// مدير الجلسة والمصادقة الأمنية
@MainActor
public final class AuthManager: ObservableObject {
    
    public static let shared = AuthManager()
    
    // مفاتيح التخزين في الـ Keychain
    private let kMasterSaltKey = "vault.master.salt"
    private let kMasterHashKey = "vault.master.hash"
    private let kDuressSaltKey = "vault.duress.salt"
    private let kDuressHashKey = "vault.duress.hash"
    private let kIsSetupCompleted = "vault.setup.completed"
    
    @Published public var state: VaultState = .locked
    @Published public var isSetupCompleted: Bool = false
    
    /// مفتاح التشفير المتماثل المؤقت (يُحفظ في الذاكرة RAM فقط أثناء فتح الخزانة الحقيقية ويُمسح فوراً عند القفل)
    @Published public private(set) var activeSymmetricKey: SymmetricKey?
    
    private let crypto = CryptoService.shared
    private let keychain = KeychainManager.shared
    
    private init() {
        checkInitialSetup()
    }
    
    // MARK: - فحص حالة الإعداد
    public func checkInitialSetup() {
        let hasMasterHash = keychain.load(key: kMasterHashKey) != nil
        isSetupCompleted = hasMasterHash
        if !isSetupCompleted {
            state = .setupRequired
        } else {
            state = .locked
        }
    }
    
    // MARK: - إعداد الرمز السري الحقيقي لأول مرة
    @discardableResult
    public func setMasterPasscode(_ passcode: String) -> Bool {
        guard passcode.count >= 4 else { return false }
        
        do {
            let salt = try crypto.generateSecureSalt()
            let hash = crypto.hashPasscode(passcode, salt: salt)
            
            let savedSalt = keychain.save(key: kMasterSaltKey, data: salt)
            let savedHash = keychain.save(key: kMasterHashKey, data: hash)
            
            if savedSalt && savedHash {
                isSetupCompleted = true
                state = .locked
                return true
            }
        } catch {
            return false
        }
        return false
    }
    
    // MARK: - إعداد رمز الإكراه / الطوارئ (Duress Passcode)
    @discardableResult
    public func setDuressPasscode(_ passcode: String) -> Bool {
        guard passcode.count >= 4 else { return false }
        
        do {
            let salt = try crypto.generateSecureSalt()
            let hash = crypto.hashPasscode(passcode, salt: salt)
            
            let savedSalt = keychain.save(key: kDuressSaltKey, data: salt)
            let savedHash = keychain.save(key: kDuressHashKey, data: hash)
            return savedSalt && savedHash
        } catch {
            return false
        }
    }
    
    // MARK: - التحقق من الرمز المدخل في الآلة الحاسبة
    /// يُفحص الرمز بمقارنة زمنية ثابتة دون إظهار أي أخطاء تثير الشبهة
    public func evaluatePasscode(_ input: String) -> Bool {
        // 1. فحص الرمز السري الحقيقي أولاً
        if let masterSalt = keychain.load(key: kMasterSaltKey),
           let masterHash = keychain.load(key: kMasterHashKey) {
            
            if crypto.verify(passcode: input, salt: masterSalt, expectedHash: masterHash) {
                // توليد مفتاح التشفير في الذاكرة الحية فقط
                self.activeSymmetricKey = crypto.deriveSymmetricKey(from: input, salt: masterSalt)
                self.state = .unlockedReal
                triggerHapticFeedback(success: true)
                return true
            }
        }
        
        // 2. فحص رمز الإكراه/الطوارئ (Fake Vault)
        if let duressSalt = keychain.load(key: kDuressSaltKey),
           let duressHash = keychain.load(key: kDuressHashKey) {
            
            if crypto.verify(passcode: input, salt: duressSalt, expectedHash: duressHash) {
                // مسح أي مفاتيح تشفير حقيقية
                self.activeSymmetricKey = nil
                self.state = .unlockedDecoy
                triggerHapticFeedback(success: true)
                return true
            }
        }
        
        return false
    }
    
    // MARK: - قفل التطبيق ومسح الذاكرة الحساسة فوراً
    public func lock() {
        self.state = .locked
        // تفريغ مفتاح التشفير من الذاكرة لضمان عدم بقائه في RAM
        self.activeSymmetricKey = nil
    }
    
    // MARK: - زر الطوارئ الفوري (Panic Button)
    public func panicLock() {
        lock()
        triggerHapticFeedback(success: false)
    }
    
    // MARK: - الاهتزاز التكتيكي
    private func triggerHapticFeedback(success: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(success ? .success : .warning)
    }
}
