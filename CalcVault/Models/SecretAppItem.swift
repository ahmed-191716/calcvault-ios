import Foundation

/// عنصر التطبيق أو الرابط السري داخل الخزانة
public struct SecretAppItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var urlString: String
    public var iconSymbol: String
    public var isWebLink: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        urlString: String,
        iconSymbol: String = "app.fill",
        isWebLink: Bool = false
    ) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.iconSymbol = iconSymbol
        self.isWebLink = isWebLink
    }
}
