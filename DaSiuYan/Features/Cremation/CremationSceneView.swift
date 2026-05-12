// CremationSceneView.swift
// 焚化仪式：拖拽 → 火焰动画 → 持久化 → 完成总结。

import SwiftUI

struct CremationSceneView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var vm: CremationSceneViewModel
    @State private var censerRect: CGRect = .zero
    @State private var showSummary: Bool = false

    init(effigy: PaperEffigy) {
        let audio = AudioEngine()
        _vm = StateObject(wrappedValue: CremationSceneViewModel(
            effigy: effigy, audioEngine: audio
        ))
    }

    var body: some View {
        ZStack {
            DiffusedBackground(mode: .preset(.nightLamp))

            VStack(spacing: 20) {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.state == .animating)

                    Spacer()
                    Text("焚化送走")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if vm.state == .ready || vm.state == .dragging {
                    Text("将小人拖拽到香炉中焚化送走")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    ZStack {
                        if vm.state != .animating && vm.state != .completed {
                            PaperEffigyView(
                                hitPart: nil,
                                hitSalt: 0,
                                damage: vm.effigy.damageState
                            )
                            .frame(width: 220, height: 300)
                            .position(x: center.x + vm.dragOffset.width,
                                      y: center.y + vm.dragOffset.height)
                            .scaleEffect(vm.isOverCenser ? 0.85 : 1.0)
                            .opacity(vm.state == .animating ? 0 : 1)
                            .gesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        vm.onDragChanged(
                                            translation: value.translation,
                                            effigyCenter: center,
                                            censerRect: censerRect
                                        )
                                    }
                                    .onEnded { _ in
                                        vm.onDragEnded(effigyCenter: center, censerRect: censerRect)
                                    }
                            )
                        }
                        CremationParticleLayer(trigger: $vm.cremationTrigger)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 420)

                CenserView(isHighlighted: vm.isOverCenser)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { censerRect = proxy.frame(in: .global) }
                                .onChange(of: proxy.frame(in: .global)) { newValue in
                                    censerRect = newValue
                                }
                        }
                    )
                    .padding(.bottom, 40)
            }

            if vm.state == .persistFailed {
                retryOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.setServices(storage: env.storage, effigyManager: env.effigyManager)
        }
        .onChange(of: vm.state) { newState in
            if newState == .completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showSummary = true
                }
            }
        }
        .background(
            NavigationLink(
                destination: summaryDestination,
                isActive: $showSummary
            ) { EmptyView() }.hidden()
        )
    }

    @ViewBuilder
    private var summaryDestination: some View {
        if let blessing = vm.blessing {
            SummaryView(effigy: vm.effigy, blessing: blessing)
                .environmentObject(env)
        } else { EmptyView() }
    }

    private var retryOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            GlassmorphicCard(cornerRadius: 20) {
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange).font(.system(size: 32))
                    Text("保存失败").font(.system(size: 18, weight: .semibold))
                    Text(vm.errorMessage ?? "")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        vm.retryPersist()
                    } label: {
                        Text("重试")
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Capsule().fill(Color.orange))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .padding(40)
        }
    }
}

private struct CenserView: View {
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(isHighlighted ? 0.5 : 0.2),
                            Color.orange.opacity(0)
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 0.3), value: isHighlighted)

            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                    )
                Text("福")
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundStyle(Color.yellow.opacity(0.9))
            }
            .frame(width: 110, height: 110)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.orange.opacity(isHighlighted ? 0.9 : 0.35),
                                lineWidth: isHighlighted ? 3 : 1.5
                            )
                    )
            )
            .shadow(color: .orange.opacity(isHighlighted ? 0.6 : 0.2), radius: 16)
            .scaleEffect(isHighlighted ? 1.12 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
        }
    }
}
