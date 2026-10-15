import Foundation

/// نموذج الملاحظة السرية المشفرة
public struct SecretNote: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var content: String
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), title: String, content: String, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
    }
}

/// نموذج الملف السري المشفر (صور أو مستندات)
public struct SecretFileMetadata: Identifiable, Codable, Equatable {
    public let id: UUID
    public var fileName: String
    public var fileSize: Int
    public var createdAt: Date
    public var mimeType: String
    
    public init(id: UUID = UUID(), fileName: String, fileSize: Int, createdAt: Date = Date(), mimeType: String) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.mimeType = mimeType
    }
}
