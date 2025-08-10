// MARK: - App Fonts
import SwiftUI
import UIKit

enum AppFontWeight {
    case regular
    case medium
    case semibold
    case bold
}

private enum AppFontFamily: String, CaseIterable {
    // Preferred first; app default is Montserrat
    case montserrat = "Montserrat"
    case inter = "Inter"
}

private struct AppFontResolver {
    static let shared = AppFontResolver()

    private let availableFamily: AppFontFamily

    private init() {
        if Self.fontExists(named: "Montserrat-Regular") {
            availableFamily = .montserrat
        } else if Self.fontExists(named: "Inter-Regular") || Self.fontExists(named: "Inter_24pt-Regular") || Self.fontExists(named: "Inter_18pt-Regular") {
            availableFamily = .inter
        } else {
            availableFamily = .montserrat // default preference
        }
        #if DEBUG
        Self.debugLogAvailableFamilies()
        #endif
    }

    func fontName(for weight: AppFontWeight) -> String {
        switch availableFamily {
        case .montserrat:
            switch weight {
            case .regular: return "Montserrat-Regular"
            case .medium: return "Montserrat-Medium"
            case .semibold: return "Montserrat-SemiBold"
            case .bold: return "Montserrat-Bold"
            }
        case .inter:
            // Try common Inter PS names; some distributions include size in PS name
            switch weight {
            case .regular: return Self.firstExisting(["Inter-Regular", "Inter_24pt-Regular", "Inter_18pt-Regular"]) ?? "Inter-Regular"
            case .medium: return Self.firstExisting(["Inter-Medium", "Inter_24pt-Medium", "Inter_18pt-Medium"]) ?? "Inter-Medium"
            case .semibold: return Self.firstExisting(["Inter-SemiBold", "Inter_24pt-SemiBold", "Inter_18pt-SemiBold"]) ?? "Inter-SemiBold"
            case .bold: return Self.firstExisting(["Inter-Bold", "Inter_24pt-Bold", "Inter_18pt-Bold"]) ?? "Inter-Bold"
            }
        }
    }

    static func fontExists(named postScriptName: String) -> Bool {
        UIFont(name: postScriptName, size: 12) != nil
    }

    static func firstExisting(_ names: [String]) -> String? {
        for n in names { if fontExists(named: n) { return n } }
        return nil
    }

    #if DEBUG
    static func debugLogAvailableFamilies() {
        let families = UIFont.familyNames.sorted()
        print("[AppFonts] Available font families: \(families)")
        if families.contains("Inter") {
            print("[AppFonts] Inter fonts: \(UIFont.fontNames(forFamilyName: "Inter"))")
        }
        if families.contains("Montserrat") {
            print("[AppFonts] Montserrat fonts: \(UIFont.fontNames(forFamilyName: "Montserrat"))")
        }
    }
    #endif
}

struct AppFonts {
    // Public semantic fonts
    static func largetitle() -> Font { make(size: 32, weight: .regular) }
    static func title() -> Font { make(size: 21, weight: .regular) }
    static func headline() -> Font { make(size: 17, weight: .regular) }
    static func subheadline() -> Font { make(size: 16, weight: .regular) }
    static func body() -> Font { make(size: 15, weight: .regular) }
    static func caption() -> Font { make(size: 13, weight: .regular) }

    // Core factory that safely falls back to system font if custom not found
    private static func make(size: CGFloat, weight: AppFontWeight) -> Font {
        let name = AppFontResolver.shared.fontName(for: weight)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        } else {
            // Fallback to system
            switch weight {
            case .regular: return .system(size: size, weight: .regular)
            case .medium: return .system(size: size, weight: .medium)
            case .semibold: return .system(size: size, weight: .semibold)
            case .bold: return .system(size: size, weight: .bold)
            }
        }
    }
}

