import Foundation

/// 规则式字段解析：只从 OCR 文本抽取，不允许补全/虚构。
public struct FieldParser {
    public init() {}

    // MARK: - 公开入口

    public func parse(_ blocks: [OCRTextBlock]) -> ParsedFields {
        var lines: [Line] = []
        for block in blocks {
            let trimmed = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            lines.append(Line(text: trimmed, midY: block.boundingBox.midY, x: block.boundingBox.x))
        }
        lines.sort { lhs, rhs in
            if lhs.midY == rhs.midY { return lhs.x < rhs.x }
            return lhs.midY > rhs.midY
        }

        var fields = ParsedFields()
        var consumed = [Bool](repeating: false, count: lines.count)

        // 1. 邮箱
        for (index, line) in lines.enumerated() {
            let found = Self.matches(Self.emailPattern, in: line.text)
            if !found.isEmpty {
                fields.emails.append(contentsOf: found)
                consumed[index] = true
            }
        }

        // 2. 网站
        for (index, line) in lines.enumerated() where !consumed[index] {
            let withoutEmails = Self.replacing(Self.emailPattern, in: line.text, with: " ")
            if let url = Self.firstMatch(Self.urlPattern, in: withoutEmails, group: 1) {
                fields.website = url
                consumed[index] = true
            }
        }

        // 3. 电话 / 传真
        for (index, line) in lines.enumerated() where !consumed[index] {
            let parsed = Self.parsePhoneLine(line.text)
            if !parsed.mobiles.isEmpty || !parsed.phones.isEmpty || !parsed.faxes.isEmpty {
                fields.mobiles.append(contentsOf: parsed.mobiles)
                fields.phones.append(contentsOf: parsed.phones)
                fields.faxes.append(contentsOf: parsed.faxes)
                consumed[index] = true
            }
        }

        // 4. 地址（相邻行合并）
        var addressIndexes: [Int] = []
        for (index, line) in lines.enumerated() where !consumed[index] {
            if Self.looksLikeAddress(line.text) {
                addressIndexes.append(index)
            }
        }
        if !addressIndexes.isEmpty {
            var groups: [[Int]] = []
            for idx in addressIndexes {
                if let lastIndex = groups.last?.last, idx == lastIndex + 1 {
                    groups[groups.count - 1].append(idx)
                } else {
                    groups.append([idx])
                }
            }
            var bestGroup: [Int] = []
            var bestGroupLength = -1
            for group in groups {
                var length = 0
                for index in group { length += lines[index].text.count }
                if length > bestGroupLength {
                    bestGroupLength = length
                    bestGroup = group
                }
            }
            let addressText = bestGroup
                .map { Self.stripLabel(lines[$0].text, labels: ["地址", "Address", "Addr", "Add"]) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !addressText.isEmpty {
                fields.address = addressText
            }
            for idx in bestGroup { consumed[idx] = true }
        }

        // 5. 姓名
        let nameResult = Self.findName(lines: lines, consumed: consumed)
        if let nameResult {
            fields.name = nameResult.name
            consumed[nameResult.index] = true
        }

        // 6. 职位
        if let titleResult = Self.findJobTitle(lines: lines, consumed: consumed) {
            fields.jobTitle = titleResult.text
            consumed[titleResult.index] = true
        }

        // 7. 公司
        if let companyResult = Self.findCompany(lines: lines, consumed: consumed, nameIndex: nameResult?.index) {
            fields.company = companyResult.text
            consumed[companyResult.index] = true
        }

        // 8. 去重
        fields.emails = Self.unique(fields.emails)
        fields.mobiles = Self.unique(fields.mobiles)
        fields.phones = Self.unique(fields.phones)
        fields.faxes = Self.unique(fields.faxes)
        return fields
    }

    /// 纯文本兜底入口（用于批量 OCR 评测脚本和测试）。
    public func parse(rawText: String) -> ParsedFields {
        let rawLines = rawText.components(separatedBy: .newlines)
        let count = max(rawLines.count, 1)
        let blocks = rawLines.enumerated().map { index, text in
            OCRTextBlock(
                text: text,
                confidence: 0.5,
                boundingBox: NormalizedRect(
                    x: 0,
                    y: 1.0 - Double(index + 1) / Double(count),
                    width: 1,
                    height: 1.0 / Double(count)
                )
            )
        }
        return parse(blocks)
    }
}

// MARK: - 实现细节

extension FieldParser {
    private struct Line {
        let text: String
        let midY: Double
        let x: Double
    }

    private struct NameCandidate {
        let value: String
        let baseScore: Int
    }

    // MARK: Patterns

    private static let emailPattern = "[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
    private static let urlPattern = "(?i)\\b((?:https?://)?(?:www\\.)?[A-Za-z0-9][A-Za-z0-9\\-]{1,62}\\.(?:com|cn|net|org|edu|io|co|ai|dev|app|info|biz|me|cc|tv|xyz|top|tech|cloud|site)(?:/[^\\s]*)?)"
    private static let phoneTokenPattern = "(?:\\+?\\d[\\d\\s\\-()]{5,}\\d)"

    // MARK: Keywords

    private static let titleKeywords: [String] = [
        "professor", "associate professor", "assistant professor", "lecturer", "teacher",
        "manager", "director", "engineer", "developer", "designer", "analyst", "consultant",
        "specialist", "architect", "researcher", "scientist", "officer", "executive",
        "president", "founder", "co-founder", "ceo", "cto", "cfo", "coo", "cmo", "vp",
        "vice president", "head of", "head", "lead", "principal", "partner", "supervisor",
        "coordinator", "administrator", "editor", "producer", "prof.", "dr.",
        "教授", "副教授", "讲师", "老师", "经理", "总监", "主管", "主任", "工程师",
        "设计师", "分析师", "顾问", "专员", "总裁", "董事长", "总经理", "首席",
        "合伙人", "研究员", "院长", "校长", "部长", "组长", "科长", "处长",
        "秘书", "助理", "会计", "医生", "主任医师", "主编", "监制", "策划"
    ]

    private static let companyStrongKeywords: [String] = [
        "有限公司", "公司", "集团", "控股", "大学", "研究院", "研究所", "银行", "医院",
        "事务所", "inc", "corp", "corporation", "ltd", "limited", "llc", "company",
        "holdings", "university", "foundation", "association", "ministry"
    ]

    private static let companyMediumKeywords: [String] = [
        "school", "college", "institute", "department", "laboratory", "labs", "studio",
        "technologies", "technology", "solutions", "systems", "consulting", "partners",
        "agency", "center", "centre", "group", "学院", "中心", "科技", "技术", "网络",
        "信息", "传媒", "咨询", "工作室"
    ]

    private static let addressChineseKeywords: [String] = [
        "省", "市", "区", "县", "镇", "村", "路", "街", "道", "巷", "号", "楼", "层",
        "室", "栋", "座", "大厦", "广场", "园区", "开发区",
        "中国", "北京", "上海", "广州", "深圳", "天津", "杭州", "南京", "武汉", "成都", "西安", "重庆", "苏州"
    ]

    private static let addressEnglishKeywords: [String] = [
        "address", "road", "street", "avenue", "floor", "building", "district",
        "city", "province", "china", "lane", "plaza", "suite", "way"
    ]

    private static let mobileKeywords: [String] = ["手机", "mobile", "cell", "移动电话", "mob", "手机号"]
    private static let officeKeywords: [String] = ["电话", "座机", "tel", "office", "phone", "work", "办公"]
    private static let faxKeywords: [String] = ["传真", "fax", "f:"]

    // MARK: Name

    private static func findName(lines: [Line], consumed: [Bool]) -> (index: Int, name: String, score: Int)? {
        var best: (index: Int, name: String, score: Int)?
        for (index, line) in lines.enumerated() where !consumed[index] {
            guard let candidate = nameCandidate(line.text) else { continue }
            var score = candidate.baseScore
            if index == 0 { score += 3 } else if index == 1 { score += 2 } else if index == 2 { score += 1 }
            let lower = candidate.value.lowercased()
            if containsAny(lower, titleKeywords) { score -= 8 }
            if containsAny(lower, companyStrongKeywords + companyMediumKeywords) { score -= 8 }
            if looksLikeAddress(line.text) { score -= 5 }
            if line.text.count > 24 { score -= 2 }
            if let current = best {
                if score > current.score { best = (index, candidate.value, score) }
            } else {
                best = (index, candidate.value, score)
            }
        }
        guard let best, best.score >= 3 else { return nil }
        return best
    }

    private static func nameCandidate(_ raw: String) -> NameCandidate? {
        let text = stripHonorific(raw)
        guard !text.isEmpty else { return nil }
        let lower = text.lowercased()
        let labelWords = ["姓名", "名字", "name", "电话", "手机", "邮箱", "地址", "公司", "职位", "网址",
                          "title", "company", "email", "tel", "mobile", "fax", "address", "website"]
        if containsAny(lower, labelWords) { return nil }
        if text.contains("@") { return nil }
        if text.contains(where: { $0.isNumber }) { return nil }
        if isCJKName(text) { return NameCandidate(value: text, baseScore: 6) }
        if isEnglishName(text) { return NameCandidate(value: text, baseScore: 5) }
        return nil
    }

    private static func isCJK(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        return (0x4E00...0x9FFF).contains(scalar.value) || scalar.value == 0x00B7
    }

    private static func isCJKName(_ text: String) -> Bool {
        let characters = Array(text)
        guard characters.count >= 2, characters.count <= 4 else { return false }
        return characters.allSatisfy { isCJK($0) }
    }

    private static func isEnglishName(_ text: String) -> Bool {
        let words = text.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        guard words.count >= 2, words.count <= 3 else { return false }
        let blocked = Set([
            "inc", "corp", "corporation", "ltd", "llc", "company", "group", "university",
            "college", "institute", "technology", "technologies", "solutions", "systems",
            "consulting", "partners", "agency", "center", "centre", "school", "department",
            "laboratory", "studio", "bank", "hospital", "foundation", "association", "manager",
            "director", "professor", "engineer", "president", "founder", "ceo", "cto", "cfo",
            "coo", "vp", "head", "lead", "senior", "junior", "consultant", "specialist",
            "analyst", "architect", "designer", "researcher", "scientist", "officer",
            "executive", "partner", "owner", "chairman", "assistant", "coordinator",
            "supervisor", "administrator", "road", "street", "avenue", "floor", "room",
            "building", "district", "city", "province"
        ])
        for word in words {
            if blocked.contains(word.lowercased()) { return false }
            guard let first = word.first, first.isUppercase else { return false }
            guard word.count >= 2 else { return false }
            guard word.allSatisfy({ $0.isLetter || $0 == "-" || $0 == "'" || $0 == "." }) else { return false }
        }
        return true
    }

    private static func stripHonorific(_ text: String) -> String {
        let pattern = "^(?i)(dr|mr|mrs|ms|prof|professor|sir|madam)\\.?\\s+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, range: range), match.range.location == 0 else { return text }
        return ns.replacingCharacters(in: match.range, with: "").trimmingCharacters(in: .whitespaces)
    }

    // MARK: Job title / company

    private static func findJobTitle(lines: [Line], consumed: [Bool]) -> (index: Int, text: String)? {
        var best: (index: Int, text: String, score: Int)?
        for (index, line) in lines.enumerated() where !consumed[index] {
            // 姓名行（如 "Dr. David Chen"）不能被当成职位行
            if nameCandidate(line.text) != nil { continue }
            guard containsAny(line.text, titleKeywords) else { continue }
            var score = 10
            if index <= 2 { score += 2 }
            if containsAny(line.text, companyStrongKeywords) { score -= 3 }
            if looksLikeAddress(line.text) { score -= 4 }
            if line.text.count > 30 { score -= 1 }
            let text = stripLabel(line.text, labels: ["职位", "职务", "Title", "Position", "Job Title"])
            if let current = best {
                if score > current.score { best = (index, text, score) }
            } else {
                best = (index, text, score)
            }
        }
        guard let best, best.score >= 6 else { return nil }
        return (best.index, best.text)
    }

    private static func findCompany(lines: [Line], consumed: [Bool], nameIndex: Int?) -> (index: Int, text: String)? {
        var best: (index: Int, text: String, score: Int)?
        for (index, line) in lines.enumerated() where !consumed[index] {
            var score = 0
            if containsAny(line.text, companyStrongKeywords) { score += 10 }
            if containsAny(line.text, companyMediumKeywords) { score += 6 }
            guard score > 0 else { continue }
            if containsAny(line.text, titleKeywords) { score -= 6 }
            if looksLikeAddress(line.text) { score -= 3 }
            if let nameIndex, index > nameIndex { score += 1 }
            if line.text.count > 40 { score -= 2 }
            let text = stripLabel(line.text, labels: ["公司", "单位", "Company", "Organization", "Org"])
            if let current = best {
                if score > current.score { best = (index, text, score) }
            } else {
                best = (index, text, score)
            }
        }
        guard let best, best.score >= 4 else { return nil }
        return (best.index, best.text)
    }

    // MARK: Phone

    private static func parsePhoneLine(_ text: String) -> (mobiles: [String], phones: [String], faxes: [String]) {
        var mobiles: [String] = []
        var phones: [String] = []
        var faxes: [String] = []
        let numbers = matches(phoneTokenPattern, in: text)
        guard !numbers.isEmpty else { return ([], [], []) }
        let lower = text.lowercased()
        let hasFax = containsAny(lower, faxKeywords)
        let hasMobile = containsAny(lower, mobileKeywords)
        let hasOffice = containsAny(lower, officeKeywords)
        for number in numbers {
            let trimmed = number.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if hasMobile || hasOffice || hasFax {
                let prefix = contextBefore(text, number: number, maxLength: 20).lowercased()
                let isFax = containsAny(prefix, faxKeywords)
                    || (hasFax && !containsAny(prefix, mobileKeywords) && !containsAny(prefix, officeKeywords))
                let isMobile = containsAny(prefix, mobileKeywords)
                    || (!hasOffice && !hasFax && isCNMobile(trimmed))
                if isFax {
                    faxes.append(trimmed)
                } else if isMobile {
                    mobiles.append(trimmed)
                } else {
                    phones.append(trimmed)
                }
            } else if isCNMobile(trimmed) {
                mobiles.append(trimmed)
            } else {
                phones.append(trimmed)
            }
        }
        return (mobiles, phones, faxes)
    }

    private static func isCNMobile(_ value: String) -> Bool {
        let digits = value.filter { $0.isNumber }
        guard digits.count == 11, digits.first == "1" else { return false }
        let second = digits[digits.index(digits.startIndex, offsetBy: 1)]
        return second >= "3" && second <= "9"
    }

    private static func contextBefore(_ text: String, number: String, maxLength: Int) -> String {
        guard let range = text.range(of: number) else { return "" }
        let prefix = text[..<range.lowerBound]
        if prefix.count <= maxLength { return String(prefix) }
        return String(prefix.suffix(maxLength))
    }

    // MARK: Text helpers

    private static func regex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern)
    }

    private static func matches(_ pattern: String, in text: String) -> [String] {
        guard let regex = regex(pattern) else { return [] }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        return regex.matches(in: text, range: range).map { ns.substring(with: $0.range) }
    }

    private static func firstMatch(_ pattern: String, in text: String, group: Int = 0) -> String? {
        guard let regex = regex(pattern) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > group else { return nil }
        let matchRange = match.range(at: group)
        guard matchRange.location != NSNotFound else { return nil }
        return ns.substring(with: matchRange)
    }

    private static func replacing(_ pattern: String, in text: String, with replacement: String) -> String {
        guard let regex = regex(pattern) else { return text }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        let lower = text.lowercased()
        return keywords.contains { lower.contains($0.lowercased()) }
    }

    private static func stripLabel(_ text: String, labels: [String]) -> String {
        var result = text
        for label in labels {
            let pattern = "^\\s*" + NSRegularExpression.escapedPattern(for: label) + "\\s*[:：]?\\s*"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let ns = result as NSString
                let range = NSRange(location: 0, length: ns.length)
                result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looksLikeAddress(_ text: String) -> Bool {
        let lower = text.lowercased()
        if addressChineseKeywords.contains(where: { lower.contains($0) }) { return true }
        let words = lower.split(whereSeparator: { !$0.isLetter }).map(String.init)
        return addressEnglishKeywords.contains(where: { words.contains($0) })
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values {
            let key = value.lowercased()
            if seen.insert(key).inserted { result.append(value) }
        }
        return result
    }
}
