import Foundation
import ZEGBot

extension ZEGBot {
        /*
        func greet(user: User, update: Update) {
                guard !(user.isBot) else { return }
                guard let message: Message = update.message else { return }

                let greeting: String = """
                歡迎 \(user.firstName)！
                💕🎊🎉👋😃
                撳 /help
                我就會即時出現
                """

                do {
                        try send(message: greeting, to: message.chat)
                } catch {
                        logger.error("\(error.localizedDescription)")
                }
        }
        */

        func handle(update: Update) {
                guard let message: Message = update.message else { return }

                // if let _ = message.groupChatCreated {}
                // if let leftChatMember: User = message.leftChatMember {}

                guard let text: String = message.text, !text.isEmpty else { return }

                if text.contains("/start") || text.contains("/help") {
                        handleStartHelp(message: message)
                } else if text.hasPrefix("/app") || text.hasPrefix("/ios") {
                        handleApp(message: message)
                } else if text.contains("/ping") {
                        handlePing(message: message, text: text)
                } else if text.hasPrefix("/add") {
                        handleAdd(message: message, text: text)
                } else if text.hasPrefix("/test") {
                        handleTest(message: message)
                } else if text.hasPrefix("/feedback") {
                        handleFeedback(message: message, text: text)
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

                發「/ping +要查嘅字詞」，
                我就會回覆相應嘅粵拼。

                發 「/add +要加嘅詞條」，
                可向我哋建議添加粵拼詞條。

                撳 /app 獲取
                粵拼輸入法 App Store 連結。

                發 「/feedback +你嘅反饋」，
                向 粵拼bot 提出反饋同建議
                """

                do {
                        try send(message: response, to: message.chat)
                } catch {
                        logger.error("Bot.handleStartHelp(): \(error.localizedDescription)")
                }
                
        }

        private func handleApp(message: Message) {
                let appInformation: String = """
                前往 App Store 下載 iOS 粵拼輸入法App：
                https://apps.apple.com/hk/app/id1509367629
                """
                do {
                        try send(message: appInformation, to: message.chat)
                } catch {
                        logger.error("Bot.handleApp(): \(error.localizedDescription)")
                }
        }

        private func handlePing(message: Message, text: String) {
                guard text.count < 10000 else {
                        reject(message: message)
                        return
                }
                let filteredText: String = filteredCJKV(text: text)
                guard !filteredText.isEmpty else {
                        logger.notice("Called ping() with no Cantonese.")
                        do {
                                try send(message: "/ping +粵語字詞", to: message.chat)
                        } catch {
                                logger.error("Bot.handlePing(): \(error.localizedDescription)")
                        }
                        return
                }
                let responseText: String = {
                        let matched = lookup(text: text)
                        if matched.romanizations.isEmpty {
                                let question: String = Array(repeating: "?", count: text.count).joined(separator: " ")
                                return text + "：\n" + question
                        } else {
                                let romanization: String = matched.romanizations.joined(separator: "\n")
                                return matched.text + "：\n" + romanization
                        }
                }()
                do {
                        try send(message: responseText, to: message.chat)
                } catch {
                        logger.error("Bot.handlePing(): \(error.localizedDescription)")
                }
        }
        private func handleAdd(message: Message, text: String) {
                guard text.count < 10000 else {
                        reject(message: message)
                        return
                }
                let phrase: String = String(text.dropFirst(4)).replacingOccurrences(of: "@jyut_bot", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !phrase.isEmpty else {
                        logger.notice("Called add() with no phrase.")
                        do {
                                try send(message: "/add +你想添加嘅詞條", to: message.chat)
                        } catch {
                                logger.error("Bot.handleAdd(): \(error.localizedDescription)")
                        }
                        return
                }
                logger.info("Received phrase suggestion: \(phrase)")
                let responseText: String = """
                收到詞條建議：
                「 \(phrase) 」
                我哋會儘快處理嘅嘞。
                多謝你嘅參與同貢獻！ 💖
                """
                do {
                        try send(message: responseText, to: message.chat)
                } catch {
                        logger.error("Bot.handleAdd(): \(error.localizedDescription)")
                }
                append(phrase: phrase)
        }
        private func handleTest(message: Message) {
                do {
                        try send(message: "absolutely", to: message.chat)
                } catch {
                        logger.error("Bot.handleTest(): \(error.localizedDescription)")
                }
        }
        private func handleFeedback(message: Message, text: String) {
                guard text.count < 10000 else {
                        reject(message: message)
                        return
                }
                let textContent: String = String(text.dropFirst(9)).trimmingCharacters(in: CharacterSet(charactersIn: " "))
                guard !(textContent.isEmpty || textContent == "@jyut_bot") else {
                        logger.notice("Called feedback() with no content.")
                        let response: String = #"/feedback +你嘅反饋"#
                        do {
                                try send(message: response, to: message.chat)
                        } catch {
                                logger.error("Bot.handleFeedback(): \(error.localizedDescription)")
                        }
                        return
                }
                let feedback: String = textContent.replacingOccurrences(of: "@jyut_bot", with: "")
                logger.info("Received feedback message: \(feedback)")
                save(feedback: feedback)
                let responseText: String = """
                收到，記低咗。
                多謝你嘅反饋同建議！
                我哋會繼續完善呢個bot嘅
                """
                do {
                        try send(message: responseText, to: message.chat)
                } catch {
                        logger.error("Bot.handleFeedback(): \(error.localizedDescription)")
                }
        }
        private func fallback(message: Message, text: String) {

                // group chat id < 0
                guard message.chat.id > 0 else {
                        logger.notice("Incomprehensible message from group chat.")
                        return
                }

                guard text.count < 10000 else {
                        reject(message: message)
                        return
                }

                guard text != "?" else {
                        handleStartHelp(message: message)
                        return
                }

                let filteredText: String = filteredCJKV(text: text)
                guard !filteredText.isEmpty else {
                        logger.notice("Incomprehensible message.")
                        do {
                                try send(message: "我聽毋明 😥", to: message.chat)
                        } catch {
                                logger.error("Bot.fallback(): \(error.localizedDescription)")
                        }
                        logger.info("Sent fallback() response back.")
                        return
                }

                let responseText: String = {
                        let matched = lookup(text: text)
                        if matched.romanizations.isEmpty {
                                let question: String = Array(repeating: "?", count: text.count).joined(separator: " ")
                                return text + "：\n" + question
                        } else {
                                let romanization: String = matched.romanizations.joined(separator: "\n")
                                return matched.text + "：\n" + romanization
                        }
                }()

                do {
                        try send(message: responseText, to: message.chat)
                } catch {
                        logger.error("Bot.handlePing(): \(error.localizedDescription)")
                }
        }

        private func reject(message: Message) {
                let response: String = #"毋好發咁長，我處理毋到 😥"#
                do {
                        try send(message: response, to: message.chat)
                } catch {
                        logger.error("Bot.reject(): \(error.localizedDescription)")
                }
                logger.notice("Rejected a very large message.")
        }

        private func filteredCJKV(text: String) -> String {
                return text.unicodeScalars.filter({ $0.properties.isIdeographic }).map({ String($0) }).joined()
        }
        private func ideographicBlocks(text: String) -> [(text: String, isIdeographic: Bool)] {
                var blocks: [(String, Bool)] = []
                var ideographicCache: String = ""
                var otherCache: String = ""
                var lastWasIdeographic: Bool = true
                for character in text {
                        let isIdeographic: Bool = character.unicodeScalars.first?.properties.isIdeographic ?? false
                        if isIdeographic {
                                if !lastWasIdeographic && !otherCache.isEmpty {
                                        let newElement: (String, Bool) = (otherCache, false)
                                        blocks.append(newElement)
                                        otherCache = ""
                                }
                                ideographicCache.append(character)
                                lastWasIdeographic = true
                        } else {
                                if lastWasIdeographic && !ideographicCache.isEmpty {
                                        let newElement: (String, Bool) = (ideographicCache, true)
                                        blocks.append(newElement)
                                        ideographicCache = ""
                                }
                                otherCache.append(character)
                                lastWasIdeographic = false
                        }
                }
                if !ideographicCache.isEmpty {
                        let newElement: (String, Bool) = (ideographicCache, true)
                        blocks.append(newElement)
                } else if !otherCache.isEmpty {
                        let newElement: (String, Bool) = (otherCache, false)
                        blocks.append(newElement)
                }
                return blocks
        }
        private func lookup(text: String) -> (text: String, romanizations: [String]) {
                let filtered: String = filteredCJKV(text: text)
                let search = Lookup.search(for: filtered)
                guard filtered != text else { return search }
                guard !(filtered.isEmpty) else { return search }
                let transformed = ideographicBlocks(text: text)
                var handledCount: Int = 0
                var combinedText: String = ""
                for item in transformed {
                        if item.isIdeographic {
                                let tail = search.text.dropFirst(handledCount)
                                let suffixCount = tail.count - item.text.count
                                let selected = tail.dropLast(suffixCount)
                                combinedText += selected
                                handledCount += item.text.count
                        } else {
                                combinedText += item.text
                        }
                }
                let combinedRomanizations = search.romanizations.map { romanization -> String in
                        let syllables: [String] = romanization.components(separatedBy: " ")
                        var index: Int = 0
                        var newRomanization: String = ""
                        var lastWasIdeographic: Bool = false
                        for character in text {
                                let isIdeographic: Bool = character.unicodeScalars.first?.properties.isIdeographic ?? false
                                if isIdeographic {
                                        newRomanization += (syllables[index] + " ")
                                        index += 1
                                        lastWasIdeographic = true
                                } else {
                                        if lastWasIdeographic {
                                                newRomanization = String(newRomanization.dropLast())
                                        }
                                        newRomanization.append(character)
                                        lastWasIdeographic = false
                                }
                        }
                        return newRomanization.trimmingCharacters(in: .whitespaces)
                }
                return (combinedText, combinedRomanizations)
        }
}

private extension ZEGBot {
        func append(phrase: String) {
                let path: String = "/srv/jyutbot/suggestions.txt"
                let url: URL = URL(fileURLWithPath: path, isDirectory: false)
                let content: String = phrase + "\n"
                guard FileManager.default.fileExists(atPath: url.path) else {
                        do {
                                try content.write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                                logger.error("Can not create suggestions.txt")
                                logger.error("Bot.append(): \(error.localizedDescription)")
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
                                logger.error("Bot.append() try handle.close(): \(error.localizedDescription)")
                        }
                        logger.info("Saved phrase to suggestions.txt")
                } else {
                        logger.error("Can not handle writing to suggestions.txt")
                }
        }
        func save(feedback: String) {
                let path: String = "/srv/jyutbot/feedback.txt"
                let url: URL = URL(fileURLWithPath: path, isDirectory: false)
                let head: String = "\(Date())\n"
                let content: String = head + feedback + "\n\n"
                guard FileManager.default.fileExists(atPath: url.path) else {
                        do {
                                try content.write(to: url, atomically: true, encoding: .utf8)
                        } catch {
                                logger.error("Can not create feedback.txt")
                                logger.error("Bot.save(): \(error.localizedDescription)")
                        }
                        logger.info("Created feedback.txt")
                        logger.info("Saved feedback message to feedback.txt")
                        return
                }
                guard let feedbackData: Data = content.data(using: .utf8) else {
                        logger.error("Can not convert feedback message to Data. message: \(feedback)")
                        return
                }
                if let handle: FileHandle = try? FileHandle(forWritingTo: url) {
                        handle.seekToEndOfFile()
                        handle.write(feedbackData)
                        do {
                                try handle.close()
                        } catch {
                                logger.error("Bot.save() try handle.close(): \(error.localizedDescription)")
                        }
                        logger.info("Saved feedback message to feedback.txt")
                } else {
                        logger.error("Can not handle writing to feedback.txt")
                }
        }
}
