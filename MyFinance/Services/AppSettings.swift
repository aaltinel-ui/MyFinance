import SwiftUI

enum FontSizeOption: String, CaseIterable, Identifiable {
    case small = "Küçük"
    case medium = "Orta"
    case large = "Büyük"
    case extraLarge = "Çok Büyük"

    var id: String { rawValue }

    var scale: Double {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        }
    }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "Sistem"
    case light = "Açık"
    case dark = "Koyu"
    case midnight = "Gece Mavisi"
    case forest = "Orman Yeşili"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .midnight, .forest: return .dark
        }
    }

    var backgroundColor: Color {
        switch self {
        case .system, .light: return Color(.systemBackground)
        case .dark: return Color(.systemBackground)
        case .midnight: return Color(red: 0.05, green: 0.05, blue: 0.15)
        case .forest: return Color(red: 0.05, green: 0.12, blue: 0.08)
        }
    }

    var cardColor: Color {
        switch self {
        case .system, .light, .dark: return Color(.secondarySystemBackground)
        case .midnight: return Color(red: 0.1, green: 0.1, blue: 0.25)
        case .forest: return Color(red: 0.1, green: 0.18, blue: 0.12)
        }
    }
}

struct AppSettingsKey {
    static let fontSize = "appFontSize"
    static let theme = "appTheme"
}

struct ScaledFont: ViewModifier {
    @AppStorage(AppSettingsKey.fontSize) private var fontSizeRaw = FontSizeOption.medium.rawValue

    private var scale: Double {
        (FontSizeOption(rawValue: fontSizeRaw) ?? .medium).scale
    }

    func body(content: Content) -> some View {
        content
            .environment(\.dynamicTypeSize, dynamicSize)
    }

    private var dynamicSize: DynamicTypeSize {
        switch FontSizeOption(rawValue: fontSizeRaw) ?? .medium {
        case .small: return .medium
        case .medium: return .xLarge
        case .large: return .xxLarge
        case .extraLarge: return .xxxLarge
        }
    }
}

struct ThemedBackground: ViewModifier {
    @AppStorage(AppSettingsKey.theme) private var themeRaw = ThemeOption.system.rawValue

    private var theme: ThemeOption {
        ThemeOption(rawValue: themeRaw) ?? .system
    }

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(theme.colorScheme)
    }
}

extension View {
    func applyAppFont() -> some View {
        modifier(ScaledFont())
    }

    func applyTheme() -> some View {
        modifier(ThemedBackground())
    }
}
