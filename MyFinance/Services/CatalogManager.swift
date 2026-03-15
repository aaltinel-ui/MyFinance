import SwiftUI

@Observable
class CatalogManager {
    static let shared = CatalogManager()

    private let kasaKey = "customKasaTips"
    private let tipKey = "customBirimTips"
    private let hiddenKasaKey = "hiddenKasaTips"
    private let hiddenTipKey = "hiddenBirimTips"

    var customKasaTips: [String] {
        didSet { save(customKasaTips, forKey: kasaKey) }
    }
    var customBirimTips: [String] {
        didSet { save(customBirimTips, forKey: tipKey) }
    }
    var hiddenKasaTips: Set<String> {
        didSet { save(Array(hiddenKasaTips), forKey: hiddenKasaKey) }
    }
    var hiddenBirimTips: Set<String> {
        didSet { save(Array(hiddenBirimTips), forKey: hiddenTipKey) }
    }

    private init() {
        customKasaTips = UserDefaults.standard.stringArray(forKey: kasaKey) ?? []
        customBirimTips = UserDefaults.standard.stringArray(forKey: tipKey) ?? []
        hiddenKasaTips = Set(UserDefaults.standard.stringArray(forKey: hiddenKasaKey) ?? [])
        hiddenBirimTips = Set(UserDefaults.standard.stringArray(forKey: hiddenTipKey) ?? [])
    }

    // All default kasa tips from enum
    var defaultKasaTips: [String] {
        KasaTip.allCases.map(\.rawValue)
    }

    // All default birim tips from enum
    var defaultBirimTips: [String] {
        BirimTip.allCases.map(\.rawValue)
    }

    // Active kasa tips (defaults + custom, minus hidden)
    var activeKasaTips: [String] {
        let all = defaultKasaTips + customKasaTips
        return all.filter { !hiddenKasaTips.contains($0) }
    }

    // Active birim tips (defaults + custom, minus hidden)
    var activeBirimTips: [String] {
        let all = defaultBirimTips + customBirimTips
        return all.filter { !hiddenBirimTips.contains($0) }
    }

    // All kasa tips including hidden (for settings UI)
    var allKasaTips: [(name: String, isDefault: Bool, isActive: Bool)] {
        let defaults = defaultKasaTips.map { (name: $0, isDefault: true, isActive: !hiddenKasaTips.contains($0)) }
        let customs = customKasaTips.map { (name: $0, isDefault: false, isActive: !hiddenKasaTips.contains($0)) }
        return defaults + customs
    }

    // All birim tips including hidden (for settings UI)
    var allBirimTips: [(name: String, isDefault: Bool, isActive: Bool)] {
        let defaults = defaultBirimTips.map { (name: $0, isDefault: true, isActive: !hiddenBirimTips.contains($0)) }
        let customs = customBirimTips.map { (name: $0, isDefault: false, isActive: !hiddenBirimTips.contains($0)) }
        return defaults + customs
    }

    func addKasaTip(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !defaultKasaTips.contains(trimmed),
              !customKasaTips.contains(trimmed) else { return }
        customKasaTips.append(trimmed)
    }

    func addBirimTip(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !defaultBirimTips.contains(trimmed),
              !customBirimTips.contains(trimmed) else { return }
        customBirimTips.append(trimmed)
    }

    func removeCustomKasaTip(_ name: String) {
        customKasaTips.removeAll { $0 == name }
        hiddenKasaTips.remove(name)
    }

    func removeCustomBirimTip(_ name: String) {
        customBirimTips.removeAll { $0 == name }
        hiddenBirimTips.remove(name)
    }

    func toggleKasaTip(_ name: String) {
        if hiddenKasaTips.contains(name) {
            hiddenKasaTips.remove(name)
        } else {
            hiddenKasaTips.insert(name)
        }
    }

    func toggleBirimTip(_ name: String) {
        if hiddenBirimTips.contains(name) {
            hiddenBirimTips.remove(name)
        } else {
            hiddenBirimTips.insert(name)
        }
    }

    private func save(_ array: [String], forKey key: String) {
        UserDefaults.standard.set(array, forKey: key)
    }
}
