import Foundation

/// Vision 风格的归一化矩形（原点左下）。
public struct NormalizedRect: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
    public var maxY: Double { y + height }
}

/// OCR 识别出的一行文本（按 Vision 的 boundingBox 保存位置，便于排序与字段定位）。
public struct OCRTextBlock: Codable, Equatable, Sendable {
    public var text: String
    public var confidence: Double
    public var boundingBox: NormalizedRect

    public init(text: String, confidence: Double = 0.9, boundingBox: NormalizedRect = NormalizedRect(x: 0, y: 0, width: 1, height: 1)) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// 从 OCR 文本解析出的结构化字段。所有字段都可能为空；不允许虚构。
public struct ParsedFields: Codable, Equatable, Sendable {
    public var name: String?
    public var company: String?
    public var jobTitle: String?
    public var mobiles: [String]
    public var phones: [String]
    public var faxes: [String]
    public var emails: [String]
    public var website: String?
    public var address: String?

    public init(name: String? = nil,
                company: String? = nil,
                jobTitle: String? = nil,
                mobiles: [String] = [],
                phones: [String] = [],
                faxes: [String] = [],
                emails: [String] = [],
                website: String? = nil,
                address: String? = nil) {
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.mobiles = mobiles
        self.phones = phones
        self.faxes = faxes
        self.emails = emails
        self.website = website
        self.address = address
    }

    public var isEmpty: Bool {
        name == nil && company == nil && jobTitle == nil
            && mobiles.isEmpty && phones.isEmpty && faxes.isEmpty
            && emails.isEmpty && website == nil && address == nil
    }
}

public struct BusinessCard: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var company: String
    public var jobTitle: String
    public var mobiles: [String]
    public var phones: [String]
    public var faxes: [String]
    public var emails: [String]
    public var website: String
    public var address: String
    public var tags: [String]
    public var notes: String
    public var originalImageFileName: String?
    public var processedImageFileName: String?
    public var rawOCRText: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
                name: String = "",
                company: String = "",
                jobTitle: String = "",
                mobiles: [String] = [],
                phones: [String] = [],
                faxes: [String] = [],
                emails: [String] = [],
                website: String = "",
                address: String = "",
                tags: [String] = [],
                notes: String = "",
                originalImageFileName: String? = nil,
                processedImageFileName: String? = nil,
                rawOCRText: String = "",
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.mobiles = mobiles
        self.phones = phones
        self.faxes = faxes
        self.emails = emails
        self.website = website
        self.address = address
        self.tags = tags
        self.notes = notes
        self.originalImageFileName = originalImageFileName
        self.processedImageFileName = processedImageFileName
        self.rawOCRText = rawOCRText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名名片" : trimmed
    }

    public var primaryPhone: String? { mobiles.first ?? phones.first }
    public var primaryEmail: String? { emails.first }

    public var subtitle: String {
        [jobTitle, company].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
