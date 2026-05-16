import Foundation

/// `.iso8601` is strict and rejects ASP.NET's fractional-second timestamps
/// (e.g. `2026-05-16T10:30:00.1234567Z`). This decoder accepts both, plus a
/// timezone-less local form, so we don't have to fight the server's serializer.
nonisolated enum FlexibleDate {
    static let decodingStrategy: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let date = parse(raw) { return date }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unrecognised date format: \(raw)"
        )
    }

    static func parse(_ raw: String) -> Date? {
        for formatter in formatters {
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }

    private static let formatters: [DateFormatter] = {
        let patterns = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]
        return patterns.map { pattern in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.dateFormat = pattern
            return f
        }
    }()
}
