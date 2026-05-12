// DaSiuYanApp.swift
// 应用入口。

import SwiftUI

@main
struct DaSiuYanApp: App {
    @StateObject private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(env)
                .preferredColorScheme(colorScheme(for: env.settingsService.settings.themeMode))
        }
    }

    private func colorScheme(for mode: ThemeMode) -> ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var env: AppEnvironment

    var body: some View {
        HomeView()
            .id(env.navigationTrigger)
    }
}
