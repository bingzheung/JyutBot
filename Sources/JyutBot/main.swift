import Foundation
import ZEGBot
import Logging

let logger: Logger = Logger(label: "io.ososo.jyutbot")

guard let botToken: String = ProcessInfo.processInfo.environment["TELEGRAM_JYUT_BOT_TOKEN"] else {
        logger.error("TELEGRAM_JYUT_BOT_TOKEN not found.")
        fatalError("TELEGRAM_JYUT_BOT_TOKEN not found.")
}

let bot: ZEGBot = ZEGBot(token: botToken)

do {
        try bot.run { (updates, _) in
                _ = updates.map { newUpdate in
                        guard let sentDate: Int = newUpdate.message?.date else { return }
                        let distance: Double = Date().timeIntervalSince1970.distance(to: Double(sentDate))
                        guard abs(distance) < 60 else {
                                logger.notice("Dropped outdated message.")
                                return
                        }
                        if let newChatMember: User = newUpdate.message?.newChatMember {
                                bot.greet(user: newChatMember, update: newUpdate)
                        } else {
                                bot.handle(update: newUpdate)
                        }
                }
        }
} catch {
        logger.error("\(error.localizedDescription)")
}
