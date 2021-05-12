import Foundation
import SQLite3

struct JyutpingProvider {
        private static let database: OpaquePointer? = {
                let path: String = "/srv/jyutbot/jyutping.sqlite3"
                var db: OpaquePointer?
                if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                        return db
                } else {
                        logger.error("Can not open SQLite database.")
                        return nil
                }
        }()
        static func match(for text: String) -> [String] {
                var jyutpings: [String] = []
                let queryString = "SELECT jyutping FROM jyutpingtable WHERE word = '\(text)';"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let jyutping: String = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
                                jyutpings.append(jyutping)
                        }
                }
                sqlite3_finalize(queryStatement)
                return jyutpings.deduplicated()
        }
}

private extension Array where Element: Hashable {
        func deduplicated() -> [Element] {
                var set: Set<Element> = Set<Element>()
                return filter { set.insert($0).inserted }
        }
}
