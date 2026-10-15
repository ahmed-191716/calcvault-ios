import Foundation
import CryptoKit
import Security

/// الأخطاء المحتملة لعمليات التشفير
public enum CryptoError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    case randomBytesGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "فشلت عملية تشفير البيانات بأمان."
        case .decryptionFailed:
            return "فشل فك التشفير: الرمز غير متطابق أو البيانات تالفة."
        case .invalidKey:
            return "مفتاح التشفير المشتق غير صالح."
        case .randomBytesGenerationFailed:
            return "فشل توليد بايتات الملح العشوائي المشفر."
        }
    }
}

/// خدمة التشفير العسكري المحلي (AES-GCM 256-bit + HKDF + Constant-time SHA256)
/// تعمل بالكامل دون اتصال بالإنترنت وتعتمد على محرك التشفير العتادي لآبل (Apple CryptoKit)
public final class CryptoService {
    
    public static let shared = CryptoService()
    private init() {}
    
    // MARK: - توليد الملح العشوائي المشفر (Secure Random Salt)
    
    /// توليد 32 بايت من العشوائية المشفرة عتادياً من SecRandom
    public func generateSecureSalt(count: Int = 32) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else {
            throw CryptoError.randomBytesGenerationFailed
        }
        return Data(bytes)
    }
    
    // MARK: - اشتقاق المفاتيح (Key Derivation via HKDF)
    
    /// اشتقاق مفتاح تشفير متماثل 256-bit من رمز المرور والملح عبر HKDF (SHA256)
    public func deriveSymmetricKey(from passcode: String, salt: Data) -> SymmetricKey {
        let inputKeyMaterial = SymmetricKey(data: Data(passcode.utf8))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: salt,
            info: Data("CalcVault.LocalEncryptionKey.v1".utf8),
            outputByteCount: 32 // 256 bits
        )
    }
    
    // MARK: - تشفير وفك تشفير البيانات (AES-GCM 256-bit)
    
    /// تشفير بيانات عشوائية باستخدام خوارزمية AES-GCM المعتمدة دولياً
    /// تُرجع الحزمة الكاملة (Combined SealedBox) متضمنة الـ Nonce والـ Tag لضمان سلامة البيانات وعدم التلاعب
    public func encrypt(data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed
            }
            return combined
        } catch {
            throw CryptoError.encryptionFailed
        }
    }
    
    /// فك تشفير بيانات مشفرة بـ AES-GCM مع التحقق التلقائي من الـ Auth Tag لمنع التلاعب
    public func decrypt(combinedData: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw CryptoError.decryptionFailed
        }
    }
    
    // MARK: - تجزئة وتدقيق كلمات المرور (Salted Hash & Constant-Time Compare)
    
    /// تجزئة كلمة المرور مع الملح عبر SHA-256
    public func hashPasscode(_ passcode: String, salt: Data) -> Data {
        var hasher = SHA256()
        hasher.update(data: salt)
        hasher.update(data: Data(passcode.utf8))
        let digest = hasher.finalize()
        return Data(digest)
    }
    
    /// مقارنة زمنية ثابتة (Constant-Time) لمنع هجمات التوقيت (Timing Attacks)
    public func verify(passcode: String, salt: Data, expectedHash: Data) -> Bool {
        let computedHash = hashPasscode(passcode, salt: salt)
        
        // مقارنة آمنة زمنياً
        guard computedHash.count == expectedHash.count else { return false }
        var result: UInt8 = 0
        for (a, b) in zip(computedHash, expectedHash) {
            result |= a ^ b
        }
        return result == 0
    }
}
