import Foundation

enum ParsedInputDecoder {
    enum Error: Swift.Error { case noJSONFound }

    static func decode(_ raw: String) throws -> ParsedInputResult {
        let cleaned = stripFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw Error.noJSONFound }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ParsedInputResult.self, from: data)
    }

    private static func stripFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNewline = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNewline)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        guard let start = t.firstIndex(of: "{"), let end = t.lastIndex(of: "}") else { return t }
        return String(t[start...end])
    }
}
