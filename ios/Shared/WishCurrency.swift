import Foundation

enum WishCurrency: String, CaseIterable, Identifiable {
    case usd = "USD", cny = "CNY", hkd = "HKD", aud = "AUD", twd = "TWD"
    case eur = "EUR", jpy = "JPY", gbp = "GBP", cad = "CAD", sgd = "SGD"

    static let selectionKey = "statisticsCurrencyCode"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .usd: return "美元"
        case .cny: return "人民币"
        case .hkd: return "港币"
        case .aud: return "澳元"
        case .twd: return "台币"
        case .eur: return "欧元"
        case .jpy: return "日元"
        case .gbp: return "英镑"
        case .cad: return "加元"
        case .sgd: return "新加坡元"
        }
    }
    var symbol: String {
        switch self {
        case .usd: return "US$"
        case .cny: return "¥"
        case .hkd: return "HK$"
        case .aud: return "A$"
        case .twd: return "NT$"
        case .eur: return "€"
        case .jpy: return "JP¥"
        case .gbp: return "£"
        case .cad: return "CA$"
        case .sgd: return "S$"
        }
    }
    var fractionDigits: Int { self == .jpy ? 0 : 2 }

    static func symbol(for code: String) -> String {
        WishCurrency(rawValue: code)?.symbol ?? "\(code) "
    }

    static func format(_ amount: Double, code: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = WishCurrency(rawValue: code)?.fractionDigits ?? 2
        formatter.roundingMode = .halfUp
        return symbol(for: code) + (formatter.string(from: NSNumber(value: amount)) ?? "—")
    }

    static func inputText(_ amount: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 16
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }

    static func parseAmount(_ text: String, locale: Locale = .current) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let decimal = formatter.decimalSeparator ?? "."
        let grouping = formatter.groupingSeparator ?? ","
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        value = String(value.map { character in
            guard character.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }),
                  let digit = character.wholeNumberValue else { return character }
            return Character(String(digit))
        })
        if !grouping.isEmpty, grouping != decimal, value.contains(grouping) {
            let parts = value.components(separatedBy: decimal)
            guard parts.count <= 2, parts.count == 1 || !parts[1].contains(grouping) else { return nil }
            let integer = parts[0].hasPrefix("+") || parts[0].hasPrefix("-") ? String(parts[0].dropFirst()) : parts[0]
            let groups = integer.components(separatedBy: grouping)
            let primarySize = formatter.groupingSize
            let secondarySize = formatter.secondaryGroupingSize > 0 ? formatter.secondaryGroupingSize : primarySize
            guard primarySize > 0, let first = groups.first, !first.isEmpty, first.count <= secondarySize,
                  groups.last?.count == primarySize,
                  groups.dropFirst().dropLast().allSatisfy({ $0.count == secondarySize }) else { return nil }
            value = value.replacingOccurrences(of: grouping, with: "")
        }
        value = value.replacingOccurrences(of: decimal, with: ".")
        guard value.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
              let amount = Double(value), amount.isFinite else { return nil }
        return amount
    }

    static func orderedCodes(_ codes: [String]) -> [String] {
        let counts = Dictionary(grouping: codes, by: { $0 }).mapValues(\.count)
        return counts.keys.sorted {
            counts[$0] == counts[$1] ? $0 < $1 : counts[$0, default: 0] > counts[$1, default: 0]
        }
    }

    static func resolvedSelection(preferred: String?, availableCodes: [String]) -> String {
        if let preferred, availableCodes.contains(preferred) { return preferred }
        if availableCodes.contains("USD") { return "USD" }
        return availableCodes.first ?? "USD"
    }
}
