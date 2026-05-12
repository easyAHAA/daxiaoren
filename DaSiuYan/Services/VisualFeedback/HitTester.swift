// HitTester.swift
// 纸片人六部位命中检测。归一化坐标系 (0..1)。
// 对应 Requirement 4.2-4.4、Property 5。

import CoreGraphics

public struct EffigyBodyPartRegion: Equatable {
    public let part: EffigyBodyPart
    /// 归一化矩形（相对于纸片人视图边界）
    public let relativeRect: CGRect

    public init(part: EffigyBodyPart, relativeRect: CGRect) {
        self.part = part
        self.relativeRect = relativeRect
    }
}

public struct HitTester {
    /// 按优先级排序；头部优先级最高，四肢次之，躯干最低（兜底）
    public let regions: [EffigyBodyPartRegion]

    public init(regions: [EffigyBodyPartRegion]) {
        self.regions = regions
    }

    /// 默认纸片人分区模板（近似参考 UI 截图中展开姿态）
    public static let `default` = HitTester(regions: [
        // 头部（优先级最高，放在最前）
        EffigyBodyPartRegion(part: .head,     relativeRect: CGRect(x: 0.32, y: 0.02, width: 0.36, height: 0.24)),
        // 左右手臂（相对于观众视角的左右）
        EffigyBodyPartRegion(part: .leftArm,  relativeRect: CGRect(x: 0.00, y: 0.22, width: 0.30, height: 0.30)),
        EffigyBodyPartRegion(part: .rightArm, relativeRect: CGRect(x: 0.70, y: 0.22, width: 0.30, height: 0.30)),
        // 左右腿
        EffigyBodyPartRegion(part: .leftLeg,  relativeRect: CGRect(x: 0.22, y: 0.62, width: 0.28, height: 0.38)),
        EffigyBodyPartRegion(part: .rightLeg, relativeRect: CGRect(x: 0.50, y: 0.62, width: 0.28, height: 0.38)),
        // 躯干兜底（最后，命中检测时先其他部位后躯干）
        EffigyBodyPartRegion(part: .torso,    relativeRect: CGRect(x: 0.28, y: 0.24, width: 0.44, height: 0.40))
    ])

    /// 命中检测：返回 point（相对归一化坐标）所落入的第一个部位。
    public func resolvePart(normalizedPoint p: CGPoint) -> EffigyBodyPart? {
        regions.first(where: { $0.relativeRect.contains(p) })?.part
    }

    /// 便利方法：接受绝对坐标 + 容器 bounds，自动归一化
    public func resolvePart(point: CGPoint, in bounds: CGRect) -> EffigyBodyPart? {
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let normalized = CGPoint(x: point.x / bounds.width, y: point.y / bounds.height)
        // Property 5：点必须在 [0,1] x [0,1] 内才算有效落点
        guard (0...1).contains(normalized.x), (0...1).contains(normalized.y) else { return nil }
        return resolvePart(normalizedPoint: normalized)
    }
}
