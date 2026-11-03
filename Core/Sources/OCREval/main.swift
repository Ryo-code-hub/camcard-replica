import Foundation
import ImageIO
import Vision
import CardCore

// macOS 命令行 OCR 评测：对 sample_data 里的合成名片跑 Vision OCR，
// 用 FieldParser 解析并与 ground truth 比对，输出字段准确率与“虚构字段”统计。

enum EvalError: Error {
    case imageLoadFailed(String)
    case badManifest
}

func normalized(_ value: String) -> String {
    value.lowercased()
        .replacingOccurrences(of: " ", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func digits(_ value: String) -> String {
    value.filter { $0.isNumber }
}

func matchesText(_ actual: String?, expected: String) -> Bool {
    guard let actual else { return false }
    return normalized(actual) == normalized(expected)
}

func containsNumber(_ actual: [String], expected: String) -> Bool {
    let target = digits(expected)
    guard !target.isEmpty else { return false }
    return actual.contains { digits($0) == target }
}

func containsText(_ actual: [String], expected: String) -> Bool {
    actual.contains { normalized($0) == normalized(expected) }
}

func runOCR(on url: URL) throws -> [OCRTextBlock] {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw EvalError.imageLoadFailed(url.lastPathComponent)
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["zh-Hans", "en-US"]
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
    try handler.perform([request])
    let observations = (request.results ?? []).sorted { lhs, rhs in
        if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.01 {
            return lhs.boundingBox.midY > rhs.boundingBox.midY
        }
        return lhs.boundingBox.minX < rhs.boundingBox.minX
    }
    return observations.compactMap { observation in
        guard let candidate = observation.topCandidates(1).first else { return nil }
        let box = observation.boundingBox
        return OCRTextBlock(
            text: candidate.string,
            confidence: Double(candidate.confidence),
            boundingBox: NormalizedRect(
                x: Double(box.minX),
                y: Double(box.minY),
                width: Double(box.width),
                height: Double(box.height)
            )
        )
    }
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("usage: OCREval <sample_data_dir> [output.json]")
    exit(1)
}
let sampleRoot = URL(fileURLWithPath: arguments[1], isDirectory: true)
let manifestURL = sampleRoot.appendingPathComponent("ground_truth.json")
let outputURL: URL? = arguments.count >= 3 ? URL(fileURLWithPath: arguments[2]) : nil

let manifestData = try Data(contentsOf: manifestURL)
guard let manifest = try JSONSerialization.jsonObject(with: manifestData) as? [[String: Any]] else {
    throw EvalError.badManifest
}

var perCard: [[String: Any]] = []
var fieldStats: [String: [Int]] = [:]  // field -> [correct, total]
var hallucinationCount = 0
let parser = FieldParser()

for entry in manifest {
    guard let id = entry["id"] as? String,
          let imageName = entry["image"] as? String,
          let groundTruth = entry["ground_truth"] as? [String: Any] else { continue }
    let imageURL = sampleRoot.appendingPathComponent("cards").appendingPathComponent(imageName)
    let blocks: [OCRTextBlock]
    do {
        blocks = try runOCR(on: imageURL)
    } catch {
        print("OCR failed for \(id): \(error)")
        continue
    }
    let rawText = blocks.map(\.text).joined(separator: "\n")
    let fields = parser.parse(blocks)

    var checks: [String: Bool] = [:]
    var detail: [String: [String: Any]] = [:]

    func checkText(_ key: String, actual: String?) {
        guard let expected = groundTruth[key] as? String, !expected.isEmpty else { return }
        let ok = matchesText(actual, expected: expected)
        checks[key] = ok
        detail[key] = ["expected": expected, "actual": actual ?? "", "ok": ok]
        var stat = fieldStats[key] ?? [0, 0]
        stat[1] += 1
        if ok { stat[0] += 1 }
        fieldStats[key] = stat
    }

    func checkMulti(_ key: String, actual: [String], groundTruthKey: String) {
        guard let expected = groundTruth[groundTruthKey] as? String, !expected.isEmpty else { return }
        let ok = key == "email" ? containsText(actual, expected: expected) : containsNumber(actual, expected: expected)
        checks[key] = ok
        detail[key] = ["expected": expected, "actual": actual.joined(separator: " | "), "ok": ok]
        var stat = fieldStats[key] ?? [0, 0]
        stat[1] += 1
        if ok { stat[0] += 1 }
        fieldStats[key] = stat
    }

    checkText("name", actual: fields.name)
    checkText("company", actual: fields.company)
    checkText("jobTitle", actual: fields.jobTitle)
    checkText("website", actual: fields.website)
    checkText("address", actual: fields.address)
    checkMulti("mobile", actual: fields.mobiles, groundTruthKey: "mobile")
    checkMulti("officePhone", actual: fields.phones, groundTruthKey: "officePhone")
    checkMulti("fax", actual: fields.faxes, groundTruthKey: "fax")
    checkMulti("email", actual: fields.emails, groundTruthKey: "email")

    // 虚构字段检测：ground truth 没有的字段，解析结果必须为空
    var hallucinations: [String] = []
    if groundTruth["website"] == nil, let website = fields.website, !website.isEmpty { hallucinations.append("website=\(website)") }
    if groundTruth["email"] == nil, !fields.emails.isEmpty { hallucinations.append("email=\(fields.emails.joined(separator: "|"))") }
    if groundTruth["mobile"] == nil, !fields.mobiles.isEmpty { hallucinations.append("mobile=\(fields.mobiles.joined(separator: "|"))") }
    hallucinationCount += hallucinations.count

    perCard.append([
        "id": id,
        "image": imageName,
        "rawText": rawText,
        "fields": [
            "name": fields.name ?? "",
            "company": fields.company ?? "",
            "jobTitle": fields.jobTitle ?? "",
            "mobile": fields.mobiles,
            "phones": fields.phones,
            "faxes": fields.faxes,
            "emails": fields.emails,
            "website": fields.website ?? "",
            "address": fields.address ?? ""
        ],
        "checks": detail,
        "hallucinations": hallucinations
    ])
}

var fieldAccuracy: [[String: Any]] = []
for (field, stat) in fieldStats.sorted(by: { $0.key < $1.key }) {
    let accuracy = stat[1] == 0 ? 0 : Double(stat[0]) / Double(stat[1])
    fieldAccuracy.append(["field": field, "correct": stat[0], "total": stat[1], "accuracy": accuracy])
}

var markdown = "# OCR / 字段解析评测（Vision + FieldParser）\n\n"
markdown += "| 字段 | 正确 / 总数 | 准确率 |\n| --- | --- | --- |\n"
for item in fieldAccuracy {
    let field = item["field"] as? String ?? ""
    let correct = item["correct"] as? Int ?? 0
    let total = item["total"] as? Int ?? 0
    let accuracy = item["accuracy"] as? Double ?? 0
    markdown += String(format: "| %@ | %d / %d | %.1f%% |\n", field, correct, total, accuracy * 100)
}
markdown += "\n虚构字段数（ground truth 不存在但解析出来）：\(hallucinationCount)\n"

var summary: [String: Any] = [
    "cards": perCard.count,
    "fieldAccuracy": fieldAccuracy,
    "hallucinationCount": hallucinationCount,
    "generatedAt": ISO8601DateFormatter().string(from: Date())
]
if let outputURL {
    summary["cases"] = perCard
    let directory = outputURL.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let data = try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: outputURL)
    let markdownURL = outputURL.deletingPathExtension().appendingPathExtension("md")
    try markdown.write(to: markdownURL, atomically: true, encoding: .utf8)
}

print(markdown)
print("\nJSON: \(outputURL?.path ?? "(not written)")")
