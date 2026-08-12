import Foundation

struct WishReminderMessage: Equatable {
    let title: String
    let body: String
}

enum WishReminderMessageBuilder {
    static func make(
        title: String,
        priority: WishPriority,
        category: String,
        savedAmount: Double,
        targetAmount: Double?,
        language: AppLanguage
    ) -> WishReminderMessage {
        let priorityText = String(
            format: language.text("%@优先级"),
            language.text(priority.title)
        )
        let notificationTitle = "【\(priorityText)】\(title.trimmingCharacters(in: .whitespacesAndNewlines))"
        let decisionPrompt = language.text("再看一眼，它现在仍值得买吗？")

        if let targetAmount, targetAmount > 0 {
            let normalizedSavedAmount = min(max(savedAmount, 0), targetAmount)
            let remainingAmount = max(targetAmount - normalizedSavedAmount, 0)
            let progress = Int(((normalizedSavedAmount / targetAmount) * 100).rounded())
            let progressText = String(
                format: language.text("已存 %@ / %@（%d%%），还差 %@。"),
                moneyText(normalizedSavedAmount),
                moneyText(targetAmount),
                progress,
                moneyText(remainingAmount)
            )
            return WishReminderMessage(
                title: notificationTitle,
                body: progressText + sentenceSpacing(for: language) + decisionPrompt
            )
        }

        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackPrompt = language.text("回来看一眼，确认它是否仍值得留在清单里。")
        let body = trimmedCategory.isEmpty
            ? fallbackPrompt
            : trimmedCategory + sentenceEnd(for: language) + sentenceSpacing(for: language) + fallbackPrompt

        return WishReminderMessage(title: notificationTitle, body: body)
    }

    private static func sentenceEnd(for language: AppLanguage) -> String {
        switch language {
        case .zhHans, .zhHant, .ja:
            return "。"
        default:
            return "."
        }
    }

    private static func sentenceSpacing(for language: AppLanguage) -> String {
        switch language {
        case .zhHans, .zhHant, .ja:
            return ""
        default:
            return " "
        }
    }

    private static func moneyText(_ value: Double) -> String {
        "$\(value.formatted(.number.precision(.fractionLength(0...2))))"
    }
}
