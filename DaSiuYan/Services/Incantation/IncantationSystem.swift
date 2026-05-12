// IncantationSystem.swift
// 内置 + 自定义咒语池 + 随机抽取 + 语音播放。
// Requirement 8。

import Foundation
import Combine

public protocol IncantationSystemProtocol: AnyObject {
    var allBuiltIn: [Incantation] { get }
    var customIncantations: [CustomIncantation] { get }

    func refreshCustoms()
    func addCustom(text: String) throws
    func deleteCustom(id: UUID) throws

    func pickRandom() -> Incantation?
    func trigger(_ incantation: Incantation, language: IncantationLanguage)
}

@MainActor
public final class IncantationSystem: IncantationSystemProtocol, ObservableObject {

    public let allBuiltIn: [Incantation]
    @Published public private(set) var customIncantations: [CustomIncantation] = []

    private let audioEngine: AudioEngineProtocol
    private let storage: StorageServicing

    public init(audioEngine: AudioEngineProtocol, storage: StorageServicing) {
        self.allBuiltIn = BuiltInIncantations.all
        self.audioEngine = audioEngine
        self.storage = storage
        refreshCustoms()
    }

    public func refreshCustoms() {
        customIncantations = (try? storage.fetchCustomIncantations()) ?? []
    }

    public func addCustom(text: String) throws {
        _ = try storage.saveCustomIncantation(text: text)
        refreshCustoms()
    }

    public func deleteCustom(id: UUID) throws {
        try storage.deleteCustomIncantation(id: id)
        refreshCustoms()
    }

    public func pickRandom() -> Incantation? {
        var pool: [Incantation] = allBuiltIn
        pool.append(contentsOf: customIncantations.filter { $0.isInCurrentPool }.map {
            Incantation(id: $0.id, cantoneseText: $0.text, mandarinText: $0.text, isBuiltIn: false)
        })
        return pool.randomElement()
    }

    public func trigger(_ incantation: Incantation, language: IncantationLanguage) {
        audioEngine.speak(incantation, language: language)
    }
}
