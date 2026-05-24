import Foundation

enum Formatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 0
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        return f
    }()

    static let currencyDetailed: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 2
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        return f
    }()

    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 1
        f.multiplier = 1
        return f
    }()

    static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        return f
    }()

    static let dateShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    static let dateMedium: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    static func formatCurrency(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "₺0"
    }

    static func maskedCurrency(_ value: Double) -> String {
        UserDefaults.standard.bool(forKey: "hideBalances") ? "₺ ***" : formatCurrency(value)
    }

    static func formatCurrencyDetailed(_ value: Double) -> String {
        currencyDetailed.string(from: NSNumber(value: value)) ?? "₺0,00"
    }

    static func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(percent.string(from: NSNumber(value: value)) ?? "0%")"
    }

    static func formatDecimal(_ value: Double) -> String {
        decimal.string(from: NSNumber(value: value)) ?? "0"
    }

    static func formatDate(_ date: Date) -> String {
        dateShort.string(from: date)
    }
}
