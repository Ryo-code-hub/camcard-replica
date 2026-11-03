import Foundation
import CardCore

enum VCFService {
    static func temporaryFileURL(for cards: [BusinessCard]) throws -> URL {
        let exporter = VCFExporter()
        let content = exporter.export(cards: cards)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CamCardReplica-\(UUID().uuidString).vcf")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
