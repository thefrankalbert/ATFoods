import Foundation

/// Prices follow the restaurant's currency (tenants.currency: XAF, XOF, EUR…), French formatting.
public enum Money {
    private static let locale = Locale(identifier: "fr_FR")

    public static func format(_ amount: Decimal, currency: String) -> String {
        // Whole amounts without decimals ("15 €"), otherwise the currency's full precision ("12,50 €").
        let whole = amount == amount.rounded(scale: 0)
        let digits = whole ? 0 : fractionDigits(currency)
        return amount.formatted(.currency(code: currency).locale(locale).precision(.fractionLength(digits)))
    }

    /// Pre-fills the price field: rounded to the currency precision (iOS 17 decodes JSON decimals via
    /// Double, so 12.15 can arrive as 12.1499999…), French decimal comma, no trailing zeros.
    public static func inputText(_ amount: Decimal, currency: String) -> String {
        "\(amount.rounded(scale: fractionDigits(currency)))".replacingOccurrences(of: ".", with: ",")
    }

    /// Symbol shown next to the price field ("FCFA", "F CFA", "€").
    public static func symbol(_ currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = locale
        f.currencyCode = currency
        return f.currencySymbol
    }

    /// Max decimals for the currency (0 for FCFA, 2 for EUR).
    public static func fractionDigits(_ currency: String) -> Int {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        return f.maximumFractionDigits
    }

    /// Parses user input ("3 800", "12,50", "12.5"). nil if empty, invalid, negative or too many decimals.
    public static func parse(_ text: String, currency: String) -> Decimal? {
        let cleaned = text
            .filter { !$0.isWhitespace && $0 != "\u{202F}" && $0 != "\u{00A0}" }
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty,
              cleaned.allSatisfy({ $0.isNumber || $0 == "." }),
              cleaned.filter({ $0 == "." }).count <= 1,
              let value = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")),
              value >= 0 else { return nil }   // 0 is a real price on existing menus (free items)
        let decimals = cleaned.split(separator: ".", omittingEmptySubsequences: false).dropFirst().first?.count ?? 0
        guard decimals <= fractionDigits(currency) else { return nil }
        return value
    }
}

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var value = self, result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
