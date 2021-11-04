import Foundation
import SQLite3

struct LookupData {

        private static let database: OpaquePointer? = {
                let path: String = "/srv/jyutbot/lookup.sqlite3"
                var db: OpaquePointer?
                if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                        return db
                } else {
                        return nil
                }
        }()

        /// Search Romanization for word
        /// - Parameter text: word
        /// - Returns: Array of Romanization matched the input word
        static func search(for text: String) -> [String] {
                guard !text.isEmpty else { return [] }
                if let matched: String = match(for: text) {
                        let romanizations: [String] = matched.components(separatedBy: ".")
                        return romanizations
                } else if text.count == 1 {
                        return []
                } else {
                        var chars: String = text
                        var fetches: [String] = []
                        while !chars.isEmpty {
                                let leading = fetchLeading(for: chars)
                                if let romanization: String = leading.romanization {
                                        fetches.append(romanization)
                                        let length: Int = max(1, leading.charCount)
                                        chars = String(chars.dropFirst(length))
                                } else {
                                        fetches.append("?")
                                        chars = String(chars.dropFirst())
                                }
                        }
                        guard !fetches.isEmpty else { return [] }
                        let suggestion: String = fetches.joined(separator: " ")
                        return [suggestion]
                }
        }

        private static func fetchLeading(for word: String) -> (romanization: String?, charCount: Int) {
                var chars: String = word
                var romanization: String? = nil
                var matchedCount: Int = 0
                while romanization == nil && !chars.isEmpty {
                        romanization = match(for: chars)
                        matchedCount = chars.count
                        chars = String(chars.dropLast())
                }
                guard let matched: String = romanization else {
                        return (nil, 0)
                }
                guard let fetched: String = matched.components(separatedBy: ".").first, !(fetched.isEmpty) else {
                        return (nil, 0)
                }
                return (fetched, matchedCount)
        }

        private static func match(for text: String) -> String? {
                let queryString = "SELECT romanization FROM lookuptable WHERE word = '\(text)';"
                var queryStatement: OpaquePointer? = nil
                defer {
                        sqlite3_finalize(queryStatement)
                }
                if sqlite3_prepare_v2(database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        if sqlite3_step(queryStatement) == SQLITE_ROW {
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                return romanization
                        }
                }
                return nil
        }
}
