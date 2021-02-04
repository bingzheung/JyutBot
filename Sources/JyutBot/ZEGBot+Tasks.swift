import Foundation
import ZEGBot

extension ZEGBot {
        func greet(user: User, update: Update) {
                guard !(user.isBot) else { return }
                guard let message: Message = update.message else { return }

                let greeting: String = """
                歡迎 \(user.firstName)！
                💕🎊🎉👋😃
                發送 /help
                我就會即時出現
                """
                
                do {
                        try send(message: greeting, to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
        }
        
        func handle(update: Update) {
                guard let message: Message = update.message else { return }
                
                // if let _ = message.groupChatCreated {}
                // if let leftChatMember: User = message.leftChatMember {}
                
                guard let text: String = message.text, !text.isEmpty else { return }
                
                if text.contains("/start") || text.contains("/help") || text == "?" {
                        handleStartHelp(message: message)
                } else if text.hasPrefix("/app") {
                        handleApp(message: message)
                } else if text.contains("/ping") {
                        handlePing(message: message, text: text)
                } else if text.hasPrefix("/add") {
                        handleAdd(message: message, text: text)
                } else if text.hasPrefix("/test") {
                        handleTest(message: message)
                } else {
                        fallback(message: message, text: text)
                }
        }
        
        private func handleStartHelp(message: Message) {
                guard let from: User = message.from else { return }
                
                let response: String = """
                你好， \(from.firstName)！
                我係一個粵拼bot，
                有咩可以幫到你？😃
                
                發送「/ping 字詞」，
                我就會回覆相應嘅粵拼。

                發送 「/add 詞條」，
                可向我哋建議添加相應嘅粵拼詞條。
                """
                
                do {
                        try send(message: response, to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
                
        }
        
        private func handleApp(message: Message) {
                let appInformation: String = """
                前往 App Store 下載粵拼輸入法：
                https://apps.apple.com/app/id1509367629
                """

                do {
                        try send(message: appInformation, to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
        }
        
        private func handlePing(message: Message, text: String) {
                let specials: String = #"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ_0123456789-:;.,?~!@#$%^&*/\<>{}[]()+=`'"’“•。，；？！、：～（）〈〉《》「」『』〔〕〖〗【】"#
                let text: String = text.filter { !specials.contains($0) }
                guard !(text.isEmpty) else {
                        logger.notice("Called ping() with no Cantonese.")
                        do {
                                try send(message: "/ping +粵語字詞", to: message.chat)
                        } catch {
                                logger.error("\(error.localizedDescription)")
                        }
                        return
                }
                var responseText: String = "\(text)："
                let matchedJyutpings: [String] = JyutpingProvider.match(for: text)
                if !(matchedJyutpings.isEmpty) {
                        let allJyutpings: String = matchedJyutpings.reduce("") { $0 + "\n" + $1 }
                        responseText += allJyutpings
                } else {
                        var chars: String = text
                        var suggestion: String = "\n"
                        while !(chars.isEmpty) {
                                let leadingMatch = fetchLeadingJyutping(for: chars)
                                suggestion += leadingMatch.jyutping + " "
                                chars = String(chars.dropFirst(leadingMatch.charCount))
                        }
                        suggestion = String(suggestion.dropLast())
                        responseText += (suggestion.isEmpty ? "__NULL__" : suggestion)
                }
                
                do {
                        try send(message: responseText, to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
        }
        private func fetchLeadingJyutping(for words: String) -> (jyutping: String, charCount: Int) {
                var chars: String = words
                var jyutpings: [String] = []
                var matchedCount: Int = 0
                while !chars.isEmpty && jyutpings.isEmpty {
                        jyutpings = JyutpingProvider.match(for: chars)
                        matchedCount = chars.count
                        chars = String(chars.dropLast())
                }
                return (jyutpings.first ?? "?", matchedCount)
        }
        private func handleAdd(message: Message, text: String) {
                let phrase: String = String(text.dropFirst(4)).trimmingCharacters(in: CharacterSet(charactersIn: " \n"))
                guard !phrase.isEmpty else {
                        logger.notice("Called add() with no phrase.")
                        do {
                                try send(message: "/add +你想添加嘅詞條", to: message.chat)
                        } catch {
                                logger.error("\(error.localizedDescription)")
                        }
                        return
                }
                logger.info("Recived phrase suggestion: \(phrase)")
                let responseText: String = """
                收到詞條建議：
                「 \(phrase) 」
                我哋會盡快處理嘅嘞。
                多謝你嘅參與！ 💖
                """

                do {
                        try send(message: responseText, to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
                append(phrase: phrase)
        }
        private func handleTest(message: Message) {
                do {
                        try send(message: "absolutely", to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
        }
        
        private func fallback(message: Message, text: String) {
                do {
                        logger.notice("Incomprehensible message.")
                        if message.chat.id > 0 || text.contains("@jyut_bot") {
                                try send(message: "我聽唔明😔", to: message.chat)
                                logger.info("Called fallback()")
                        }
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
        }

        private func append(phrase: String) {
                let path: String = "/srv/jyutbot/suggestions.txt"
                let url: URL = URL(fileURLWithPath: path, isDirectory: false)
                let content: String = phrase + "\n"
                guard FileManager.default.fileExists(atPath: url.path) else {
                        do {
                                try content.write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                                logger.error("\(error.localizedDescription)")
                        }
                        logger.info("Created suggestions.txt")
                        logger.info("Saved phrase to suggestions.txt")
                        return
                }
                guard let phraseData: Data = content.data(using: .utf8) else {
                        logger.error("Can not convert phrase content to Data. phrase: \(phrase)")
                        return
                }
                if let handle: FileHandle = try? FileHandle(forWritingTo: url) {
                        handle.seekToEndOfFile()
                        handle.write(phraseData)
                        do {
                                try handle.close()
                        } catch {
                                logger.error("\(error.localizedDescription)")
                        }
                        logger.info("Saved phrase to suggestions.txt")
                } else {
                        logger.error("Can not handle writing to suggestions.txt")
                }
        }
}
