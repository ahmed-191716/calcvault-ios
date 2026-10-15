import Foundation
import CryptoKit

/// مخزن البيانات المحلي المشفر بنسبة 100% داخل مساحة التطبيق المعزولة (Sandbox)
/// لا يتصل بأي سيرفر خارجي ولا يستخدم أي قواعد بيانات باهظة أو معقدة
public final class LocalVaultStore: ObservableObject {
    
    public static let shared = LocalVaultStore()
    
    @Published public var notes: [SecretNote] = []
    @Published public var decoyNotes: [SecretNote] = []
    @Published public var files: [SecretFileMetadata] = []
    
    private let fileManager = FileManager.default
    private let crypto = CryptoService.shared
    
    // المجلد السري
    private var vaultDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("EncryptedVault", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private var notesFileURL: URL {
        vaultDirectory.appendingPathComponent("notes.vault")
    }
    
    private var decoyNotesFileURL: URL {
        vaultDirectory.appendingPathComponent("decoy_notes.json")
    }
    
    private init() {
        loadDecoyNotes()
    }
    
    // MARK: - الملاحظات السرية الحقيقية (مشفرة بـ AES-256-GCM)
    
    public func loadSecretNotes(with key: SymmetricKey) {
        guard fileManager.fileExists(atPath: notesFileURL.path),
              let encryptedData = try? Data(contentsOf: notesFileURL) else {
            self.notes = []
            return
        }
        
        do {
            let decryptedData = try crypto.decrypt(combinedData: encryptedData, using: key)
            let decodedNotes = try JSONDecoder().decode([SecretNote].self, from: decryptedData)
            self.notes = decodedNotes
        } catch {
            print("فشل فك تشفير الملاحظات: \(error.localizedDescription)")
            self.notes = []
        }
    }
    
    public func saveSecretNotes(with key: SymmetricKey) {
        do {
            let rawData = try JSONEncoder().encode(notes)
            let encryptedData = try crypto.encrypt(data: rawData, using: key)
            
            // الكتابة مع التشفير العتادي وتأمين الملف عند قفل الجهاز
            try encryptedData.write(to: notesFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("خطأ في حفظ وتشفير الملاحظات: \(error.localizedDescription)")
        }
    }
    
    public func addNote(title: String, content: String, key: SymmetricKey) {
        let newNote = SecretNote(title: title, content: content)
        notes.insert(newNote, at: 0)
        saveSecretNotes(with: key)
    }
    
    public func deleteNote(at offsets: IndexSet, key: SymmetricKey) {
        notes.remove(atOffsets: offsets)
        saveSecretNotes(with: key)
    }
    
    // MARK: - الملاحظات الوهمية (Decoy Notes)
    // تبدو عادية جداً وتظهر فقط عند إدخال رمز الإكراه
    public func loadDecoyNotes() {
        if fileManager.fileExists(atPath: decoyNotesFileURL.path),
           let data = try? Data(contentsOf: decoyNotesFileURL),
           let decoded = try? JSONDecoder().decode([SecretNote].self, from: data) {
            self.decoyNotes = decoded
        } else {
            // بيانات أولية واقعية تظهر للمفتش
            self.decoyNotes = [
                SecretNote(title: "أغراض المنزل", content: "حليب، خبز، قهوة، مناديل، صابون غسيل."),
                SecretNote(title: "مواعيد الفحص", content: "فحص الأسنان يوم الخميس القادم الساعة 4 عصراً."),
                SecretNote(title: "ملاحظات الدورة", content: "مراجعة الفصل الثالث من أساسيات البرمجة.")
            ]
            saveDecoyNotes()
        }
    }
    
    public func saveDecoyNotes() {
        if let data = try? JSONEncoder().encode(decoyNotes) {
            try? data.write(to: decoyNotesFileURL, options: [.atomic, .completeFileProtection])
        }
    }
    
    public func addDecoyNote(title: String, content: String) {
        let note = SecretNote(title: title, content: content)
        decoyNotes.insert(note, at: 0)
        saveDecoyNotes()
    }
    
    public func deleteDecoyNote(at offsets: IndexSet) {
        decoyNotes.remove(atOffsets: offsets)
        saveDecoyNotes()
    }
}
