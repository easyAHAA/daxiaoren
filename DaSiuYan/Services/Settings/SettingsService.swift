// SettingsService.swift
// 全局偏好（UserDefaults 持久化）。
// Requirement 13 / 17 / 3.4。

import Foundation
import SwiftUI
import Combine

public struct UserSettings: Codable, Equatable {
    public var soundEnabled: Bool = true
    public var hapticEnabled: Bool = true
    public var incantationLanguage: IncantationLanguage = .cantonese
    public var themeMode: ThemeMode = .system
    public var renderModeOverride: RenderOverride = .auto
    public var backgroundMode: PersistedBackgroundMode = .preset(.warm)
    public var iCloudSyncEnabled: Bool = false
    public var privacyAccepted: Bool = false
    public var culturalDisclaimerShown: Bool = false

    public init() {}
}

public enum RenderOverride: String, Codable, CaseIterable {
    case auto, full, lite
}

public enum PersistedBackgroundMode: Codable, Equatable {
    case preset(PresetPalette)
    case solid(HexColor)
    case customImage(String)
}

public struct HexColor: Codable, Equatable {
    public let r: Double
    public let g: Double
    public let b: Double
    public init(r: Double, g: Double, b: Double) {
        self.r = r; self.g = g; self.b = b
    }
    public var color: Color { Color(red: r, green: g, blue: b) }
    public static let defaultSolid = HexColor(r: 0.95, g: 0.88, b: 0.72)
}

public protocol SettingsServicing: AnyObject {
    var settings: UserSettings { get }
    var publisher: AnyPublisher<UserSettings, Never> { get }
    func update(_ change: (inout UserSettings) -> Void)
}

public final class SettingsService: SettingsServicing, ObservableObject {

    @Published public private(set) var settings: UserSettings

    private let defaults: UserDefaults
    private let key = "user_settings_v1"

    public var publisher: AnyPublisher<UserSettings, Never> {
        $settings.eraseToAnyPublisher()
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = UserSettings()
        }
    }

    public func update(_ change: (inout UserSettings) -> Void) {
        var copy = settings
        change(&copy)
        settings = copy
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
        defaults.set(settings.iCloudSyncEnabled, forKey: "icloud_sync_enabled")
    }
}
