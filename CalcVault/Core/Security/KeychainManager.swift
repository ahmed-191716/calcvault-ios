import Foundation
import Security

/// إدارة سلسلة المفاتيح (iOS Keychain) المشفرة عتادياً بواسطة Secure Enclave
/// تضمن حفظ قيم الهاش والأملاح المشفرة دون إمكانية استخراجها حتى لو تم أخذ نسخة احتياطية للجهاز
public final class KeychainManager {
    
    public static let shared = KeychainManager()
    private let serviceName = "com.calcvault.app.security"
    
    private init() {}
    
    // MARK: - حفظ البيانات في Keychain
    public func save(key: String, data: Data) -> Bool {
        // حذف أي عنصر قديم بنفس المفتاح أولاً
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // أقصى درجات الحماية: متاح فقط عندما يكون هذا الجهاز تحديداً مفتوحاً (لا يُنقل في النسخ الاحتياطية)
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - قراءة البيانات من Keychain
    public func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        }
        return nil
    }
    
    // MARK: - حذف البيانات
    @discardableResult
    public func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - مسح كافة البيانات الأمنية (Reset)
    public func resetAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(query as CFDictionary)
    }
}
