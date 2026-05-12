// StrikeSceneView.swift
// 全屏极简悬浮弥散风打击场景。

import SwiftUI

struct StrikeSceneView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var vm: StrikeSceneViewModel
    @StateObject private var hud = FloatingHUDViewModel()

    @State private var showCremation = false

    init(effigy: PaperEffigy) {
        let audio = AudioEngine()
        let haptic = HapticEngine()
        let storage = StorageService()
        let inc = IncantationSystem(audioEngine: audio, storage: storage)
        _vm = StateObject(wrappedValue: StrikeSceneViewModel(
            effigy: effigy,
            propSystem: PropSystem(),
            audioEngine: audio,
            hapticEngine: haptic,
            incantationSystem: inc
        ))
    }

    var body: some View {
        ZStack {
            DiffusedBackground(mode: env.backgroundSystem.current)

            VStack {
                Spacer()

                ZStack {
                    PaperEffigyView(
                        hitPart: vm.lastHitPart,
                        hitSalt: vm.hitSalt,
                        damage: vm.damageState
                    )
                    .allowsHitTesting(false)

                    GeometryReader { geo in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        vm.handleStrike(at: value.location, in: geo.frame(in: .local))
                                        hud.onStrike()
                                    }
                            )
                    }

                    StrikeParticleLayer(
                        strikeEvent: $vm.pendingParticleEvent,
                        renderTier: env.renderTier
                    )
                    .allowsHitTesting(false)
                }
                .frame(width: 300, height: 400)

                Spacer()

                if !vm.currentIncantationText.isEmpty {
                    Text(vm.currentIncantationText)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if vm.hintVisible {
                    Text("点击或滑动攻击小人不同部位")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                }

                propBar.padding(.bottom, 28)
            }

            HStack {
                VStack {
                    Spacer()
                    DamageMeterView(damage: vm.damageState)
                        .opacity(hud.opacity)
                        .frame(height: 180)
                    Spacer()
                }
                .padding(.leading, 16)
                Spacer()
            }

            VStack {
                HStack(spacing: 12) {
                    Spacer()
                    FloatingIconButton(
                        systemImage: vm.incantationModeIcon,
                        label: "咒语·" + vm.incantationModeLabel,
                        isActive: vm.incantationMode != .off
                    ) {
                        vm.cycleIncantationMode()
                        hud.onUserActivity()
                        if vm.incantationMode == .manual {
                            vm.playRandomIncantation()
                        }
                    }

                    FloatingIconButton(
                        systemImage: vm.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        label: "音效",
                        isActive: vm.isSoundEnabled
                    ) {
                        vm.toggleSound()
                        hud.onUserActivity()
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 12)
                .opacity(hud.opacity)
                Spacer()
            }

            VStack {
                HStack {
                    Button {
                        _ = vm.prepareForExit()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 16)
                    .padding(.top, 12)
                    .opacity(hud.opacity)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        _ = vm.prepareForExit()
                        showCremation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                            Text("进入焚化")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.orange.opacity(0.85)))
                        .foregroundStyle(.white)
                        .shadow(color: .orange.opacity(0.5), radius: 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 110)
                    .opacity(hud.opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.setServices(
                propSystem: env.propSystem,
                audioEngine: env.audioEngine,
                hapticEngine: env.hapticEngine,
                incantationSystem: env.incantationSystem,
                effigyManager: env.effigyManager,
                language: env.settingsService.settings.incantationLanguage
            )
            vm.isSoundEnabled = env.settingsService.settings.soundEnabled
            vm.isHapticEnabled = env.settingsService.settings.hapticEnabled
        }
        .background(
            NavigationLink(
                destination: cremationDestination,
                isActive: $showCremation
            ) { EmptyView() }.hidden()
        )
    }

    @ViewBuilder
    private var cremationDestination: some View {
        CremationSceneView(effigy: vm.prepareForExitPassive())
            .environmentObject(env)
    }

    private var propBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(Prop.allCases) { prop in
                    PropChipView(
                        prop: prop,
                        isSelected: vm.currentProp == prop
                    ) {
                        vm.switchProp(prop)
                        hud.onUserActivity()
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .opacity(hud.opacity)
    }
}
