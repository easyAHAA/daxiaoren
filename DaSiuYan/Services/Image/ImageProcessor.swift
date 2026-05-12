// ImageProcessor.swift
// Vision 人像检测 + Core Image 纸扎风格化。
// Requirement 1.2–1.5。

import Foundation
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

public protocol ImageProcessing {
    func detectSubject(in image: UIImage) async throws -> CGRect?
    func crop(_ image: UIImage, to normalizedRect: CGRect) -> UIImage
    func applyPaperStyle(_ image: UIImage) async throws -> UIImage
}

public enum ImageProcessingError: Error {
    case filterFailed
}

public final class ImageProcessor: ImageProcessing {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    public init() {}

    public func detectSubject(in image: UIImage) async throws -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }

        async let faces = detectFaces(cgImage: cgImage)
        async let humans = detectHumans(cgImage: cgImage)
        let faceRects = (try? await faces) ?? []
        let humanRects = (try? await humans) ?? []
        let all = faceRects + humanRects
        return all.max(by: { $0.width * $0.height < $1.width * $1.height })
    }

    private func detectFaces(cgImage: CGImage) async throws -> [CGRect] {
        try await withCheckedThrowingContinuation { cont in
            let req = VNDetectFaceRectanglesRequest { request, error in
                if let error = error { cont.resume(throwing: error); return }
                let rects = (request.results as? [VNFaceObservation])?.map { $0.boundingBox } ?? []
                cont.resume(returning: rects)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([req]) } catch { cont.resume(throwing: error) }
        }
    }

    private func detectHumans(cgImage: CGImage) async throws -> [CGRect] {
        try await withCheckedThrowingContinuation { cont in
            let req = VNDetectHumanRectanglesRequest { request, error in
                if let error = error { cont.resume(throwing: error); return }
                let rects = (request.results as? [VNHumanObservation])?.map { $0.boundingBox } ?? []
                cont.resume(returning: rects)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([req]) } catch { cont.resume(throwing: error) }
        }
    }

    public func crop(_ image: UIImage, to normalizedRect: CGRect) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)

        let padding: CGFloat = 0.12
        let expanded = normalizedRect.insetBy(dx: -padding, dy: -padding)
        let clipped = expanded.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        // Vision 原点在左下，CGImage 在左上 — 翻转 y
        let rect = CGRect(
            x: clipped.origin.x * w,
            y: (1 - clipped.origin.y - clipped.height) * h,
            width: clipped.width * w,
            height: clipped.height * h
        )
        guard let cropped = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    public func applyPaperStyle(_ image: UIImage) async throws -> UIImage {
        return try await Task.detached(priority: .userInitiated) { [ciContext] in
            guard let input = CIImage(image: image) else { throw ImageProcessingError.filterFailed }

            // 1) 色调调整
            let controls = CIFilter.colorControls()
            controls.inputImage = input
            controls.saturation = 0.55
            controls.brightness = 0.04
            controls.contrast = 1.2
            guard var stage = controls.outputImage else { throw ImageProcessingError.filterFailed }

            // 2) 海报化（卡通感）
            if let posterize = CIFilter(name: "CIColorPosterize") {
                posterize.setValue(stage, forKey: kCIInputImageKey)
                posterize.setValue(6, forKey: "inputLevels")
                if let out = posterize.outputImage { stage = out }
            }

            // 3) 暖色叠加（纸黄感）
            let mono = CIFilter.colorMonochrome()
            mono.inputImage = stage
            mono.color = CIColor(red: 0.95, green: 0.86, blue: 0.70)
            mono.intensity = 0.25
            if let out = mono.outputImage { stage = out }

            // 4) 噪点叠加（纸纹理）
            let noise = CIFilter.randomGenerator()
            if let noiseOut = noise.outputImage?.cropped(to: stage.extent) {
                let processed = noiseOut.applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0,
                    kCIInputContrastKey: 0.3,
                    kCIInputBrightnessKey: 0.6
                ])
                let multiply = CIFilter.multiplyCompositing()
                multiply.inputImage = processed
                multiply.backgroundImage = stage
                if let out = multiply.outputImage { stage = out }
            }

            // 5) 边缘增强（毛边）
            let edges = CIFilter.edges()
            edges.inputImage = stage
            edges.intensity = 1.2
            if let edgeOut = edges.outputImage {
                let brightened = edgeOut.applyingFilter("CIColorControls", parameters: [kCIInputBrightnessKey: 0.1])
                let add = CIFilter.additionCompositing()
                add.inputImage = brightened
                add.backgroundImage = stage
                if let out = add.outputImage { stage = out }
            }

            guard let cg = ciContext.createCGImage(stage, from: stage.extent) else {
                throw ImageProcessingError.filterFailed
            }
            return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
        }.value
    }
}
