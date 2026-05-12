// AudioEngine.swift
// 音效与咒语语音播放。
// Demo 阶段打击音效使用系统音效 SystemSoundID 占位；
// 咒语使用 AVSpeechSynthesizer 合成（Requirement 8.2）。
// 生产版应替换为 AVAudioPlayer + 打包的 .caf 文件。

import Foundation
import AVFoundation
import AudioToolbox

public protocol AudioEngineProtocol: AnyObject {
    var isEnabled: Bool { get set }
    func prepare()
    func playStrike(for prop: Prop)
    func playPaperTear()
    func playCremation() async
    func speak(_ incantation: Incantation, language: IncantationLanguage)
    func stopAll()
}

public final class AudioEngine: NSObject, AudioEngineProtocol, AVSpeechSynthesizerDelegate {

    public var isEnabled: Bool = true

    private let synthesizer = AVSpeechSynthesizer()
    private var cremationPlayer: AVAudioPlayer?

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func prepare() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // 静默，音频非致命
        }
    }

    // MARK: - 打击音效（Demo 用 SystemSound，真机可听到短促"tock"）

    public func playStrike(for prop: Prop) {
        guard isEnabled else { return }
        // 1104 = Tink (轻击), 1306 = PaperTear 近似, 1520 = 重击近似
        let soundID: SystemSoundID = prop.isHeavy ? 1520 : 1104
        AudioServicesPlaySystemSound(soundID)
    }

    public func playPaperTear() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1306)
    }

    /// 焚化持续音效（4 秒）。Demo 使用系统音循环；生产版替换为 crackle_fire.caf
    public func playCremation() async {
        guard isEnabled else { return }
        for _ in 0..<8 {
            AudioServicesPlaySystemSound(1307) // Tock 近似余烬声
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s 间隔，总计 4s
        }
    }

    // MARK: - 咒语语音（AVSpeechSynthesizer）

    public func speak(_ incantation: Incantation, language: IncantationLanguage) {
        guard isEnabled else { return }
        let text = incantation.text(for: language)
        let utterance = AVSpeechUtterance(string: text)

        // 粤语语音包可能未安装，降级为普通话（Requirement 8.11 的延伸）
        utterance.voice = AVSpeechSynthesisVoice(language: language.voiceLanguageCode)
            ?? AVSpeechSynthesisVoice(language: IncantationLanguage.mandarin.voiceLanguageCode)

        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        utterance.postUtteranceDelay = 0.2

        // 若当前正在朗读，打断后立即朗读新咒语
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }

    // MARK: - 全局停止（Requirement 7.6, 200ms 内）

    public func stopAll() {
        synthesizer.stopSpeaking(at: .immediate)
        cremationPlayer?.stop()
    }
}

private extension Prop {
    /// 延伸属性，避免在 AudioEngine 里重复 PropSystem 依赖
    var isHeavy: Bool {
        switch self {
        case .slipper, .ruler: return false
        case .oldShoe, .brick, .broom, .whiteTigerTalisman: return true
        }
    }
}
