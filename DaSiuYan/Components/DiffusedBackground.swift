// DiffusedBackground.swift
// 全屏悬浮弥散背景：多个径向渐变光晕在底色上缓慢漂移。
// Requirement 12.2 / 12.3。

import SwiftUI

public struct DiffusedBackground: View {
    public let mode: BackgroundMode

    public init(mode: BackgroundMode) {
        self.mode = mode
    }

    public var body: some View {
        ZStack {
            switch mode {
            case .preset(let palette):
                LinearGradient(
                    colors: palette.stops,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                AnimatedGlows(tint: palette.glowTint)

            case .solid(let color):
                color.ignoresSafeArea()

            case .customImage(let url):
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 25)           // Requirement 12.13 自动高斯模糊
                            .overlay(Color.black.opacity(0.35))  // 半透明遮罩
                    default:
                        Color.black
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - 漂移光晕

private struct AnimatedGlows: View {
    let tint: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let time = context.date.timeIntervalSinceReferenceDate
                drawGlow(ctx, size: size, center: point(at: time * 0.07, in: size, seed: 0), radius: size.width * 0.6)
                drawGlow(ctx, size: size, center: point(at: time * 0.05, in: size, seed: 1.7), radius: size.width * 0.5)
                drawGlow(ctx, size: size, center: point(at: time * 0.09, in: size, seed: 3.3), radius: size.width * 0.45)
            }
            .blur(radius: 60)
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func point(at t: TimeInterval, in size: CGSize, seed: Double) -> CGPoint {
        let x = size.width * (0.5 + 0.35 * CGFloat(sin(t + seed)))
        let y = size.height * (0.5 + 0.35 * CGFloat(cos(t * 0.8 + seed * 0.5)))
        return CGPoint(x: x, y: y)
    }

    private func drawGlow(_ ctx: GraphicsContext, size: CGSize, center: CGPoint, radius: CGFloat) {
        let path = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        ctx.fill(path, with: .color(tint))
    }
}

#if DEBUG
struct DiffusedBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DiffusedBackground(mode: .preset(.warm))
                .previewDisplayName("Warm")
            DiffusedBackground(mode: .preset(.nightLamp))
                .previewDisplayName("NightLamp")
                .preferredColorScheme(.dark)
        }
    }
}
#endif
