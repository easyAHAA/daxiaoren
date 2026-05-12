// CoreLogicTests.swift
// 核心逻辑 smoke tests（纯函数验证，无需 UI / Core Data）。
// 若要启用：在 Xcode 中为 DaSiuYan target 添加 Unit Test target 并将此文件加入。
// 未来可升级为 SwiftCheck Property-Based Tests（见 design.md 的 18 条 Properties）。

import XCTest
@testable import DaSiuYan

final class CoreLogicTests: XCTestCase {

    // MARK: - Property 7: Damage_State 边界与单调性

    func testDamageStateMonotonicAndClamped() {
        var effigy = PaperEffigy(name: "测试")
        var last = effigy.damageState

        for _ in 0..<200 {
            effigy = effigy.registeringStrike(addDamage: Int.random(in: 1...5))
            XCTAssertGreaterThanOrEqual(effigy.damageState, last, "damage 必须单调非降")
            XCTAssertLessThanOrEqual(effigy.damageState, 100, "damage 不得超过 100")
            XCTAssertGreaterThanOrEqual(effigy.damageState, 0, "damage 不得小于 0")
            last = effigy.damageState
        }
        // 经过足够多次打击应当达到封顶
        XCTAssertEqual(effigy.damageState, 100)
    }

    // MARK: - Property 13: P(sacred) ≥ 0.80

    func testBlessingSacredProbability() {
        var rng = SystemRandomNumberGenerator()
        var sacredCount = 0
        let total = 2000

        for _ in 0..<total {
            let result = CremationSceneViewModel.generateBlessing(using: &rng)
            if result.dice == .sacred { sacredCount += 1 }
            XCTAssertGreaterThanOrEqual(result.text.count, 10)
            XCTAssertLessThanOrEqual(result.text.count, 100)
        }
        let ratio = Double(sacredCount) / Double(total)
        XCTAssertGreaterThanOrEqual(ratio, 0.80 - 0.03, "P(sacred) 需 ≥ 0.80（允许 ε=3% 统计抖动）")
    }

    // MARK: - Property 5: HitTester 正确性

    func testHitTesterResolvesCorrectPart() {
        let tester = HitTester.default
        // 头部中心
        XCTAssertEqual(tester.resolvePart(normalizedPoint: CGPoint(x: 0.5, y: 0.13)), .head)
        // 躯干中心
        XCTAssertEqual(tester.resolvePart(normalizedPoint: CGPoint(x: 0.5, y: 0.45)), .torso)
        // 左腿
        XCTAssertEqual(tester.resolvePart(normalizedPoint: CGPoint(x: 0.35, y: 0.85)), .leftLeg)
        // 落在完全超出区域
        XCTAssertNil(tester.resolvePart(normalizedPoint: CGPoint(x: 2.0, y: 2.0)))
    }

    // MARK: - Property 9: Haptic 映射一致性

    func testHapticProfileMappingBoundaries() {
        let system = PropSystem()
        let lightProps: [Prop] = [.slipper, .ruler]
        let heavyProps: [Prop] = [.oldShoe, .brick, .broom, .whiteTigerTalisman]

        for prop in lightProps {
            let p = system.profile(for: prop)
            XCTAssertGreaterThanOrEqual(p.hapticIntensity.lowerBound, 0.3)
            XCTAssertLessThanOrEqual(p.hapticIntensity.upperBound, 0.5)
            XCTAssertGreaterThanOrEqual(p.hapticDuration.lowerBound, 0.05)
            XCTAssertLessThanOrEqual(p.hapticDuration.upperBound, 0.15)
        }
        for prop in heavyProps {
            let p = system.profile(for: prop)
            XCTAssertGreaterThanOrEqual(p.hapticIntensity.lowerBound, 0.7)
            XCTAssertLessThanOrEqual(p.hapticIntensity.upperBound, 1.0)
            XCTAssertGreaterThanOrEqual(p.hapticDuration.lowerBound, 0.15)
            XCTAssertLessThanOrEqual(p.hapticDuration.upperBound, 0.30)
        }
    }

    // MARK: - Property 11: 内置咒语约束

    func testBuiltInIncantationsConstraints() {
        let all = BuiltInIncantations.all
        XCTAssertGreaterThanOrEqual(all.count, 6, "内置咒语应 ≥ 6 条")
        for inc in all {
            XCTAssertGreaterThanOrEqual(inc.cantoneseText.count, 4)
            XCTAssertLessThanOrEqual(inc.cantoneseText.count, 60)
            XCTAssertGreaterThanOrEqual(inc.mandarinText.count, 4)
            XCTAssertLessThanOrEqual(inc.mandarinText.count, 60)
        }
    }
}
