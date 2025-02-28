import Foundation
import SwiftUI
import Vision
import UIKit
import ImageIO
import NaturalLanguage

struct VisionProcessor {
    var image: UIImage
    var language: String
    
    init(ui: UIImage, language: String) {
        self.image = ui
        self.language = language
    }
    
    // Convert UIImageOrientation to CGImagePropertyOrientation
    private func cgImageOrientation(from uiImageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiImageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }/*
    func detectText(completion: @escaping (EncryptData?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil) // Invalid image
            return
        }

        // Text detection request
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(nil) // Handle errors or no results
                return
            }
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            // Extract bounding rectangles and texts based on the language
            var boundingRects: [CGRect] = []
            var lineBoundingRects: [CGRect] = []
            var storeIndecies: [Int,Int] = [:] // 1st Int: store char index, 2nd Int: store line index
            var texts: [String] = []
            var lines: [String] = []
            
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else {
                    continue // Skip if no candidate available
                }
                lines.append(candidate.string)
                // Handle language-specific processing
                if language == "CH" {
                    // Chinese: Process per character
                    var currentIndex = candidate.string.startIndex
                    for char in candidate.string {
                        if let range = candidate.string.range(of: String(char), range: currentIndex..<candidate.string.endIndex) {
                            // Get the bounding box for the character
                            if let charBox = try? candidate.boundingBox(for: range) {
                                let normalizedBox = charBox.boundingBox
                                let rect = CGRect(
                                    x: normalizedBox.origin.x * imageWidth,
                                    y: (1 - normalizedBox.origin.y - normalizedBox.height) * imageHeight,
                                    width: normalizedBox.width * imageWidth,
                                    height: normalizedBox.height * imageHeight
                                )
                                boundingRects.append(rect)
                            }
                            currentIndex = range.upperBound // Move the index forward
                        }
                        texts.append(String(char))
                    }
                } else if language == "EN" {
                    // English: Process per word
                    let words = candidate.string.split(separator: " ")
                    var wordRects: [CGRect] = []
                    var wordTexts: [String] = []

                    var currentIndex = candidate.string.startIndex
                    for word in words {
                        if let range = candidate.string.range(of: String(word), range: currentIndex..<candidate.string.endIndex) {
                            // Get the bounding box for the word
                            if let wordBox = try? candidate.boundingBox(for: range) {
                                let normalizedBox = wordBox.boundingBox
                                let rect = CGRect(
                                    x: normalizedBox.origin.x * imageWidth,
                                    y: (1 - normalizedBox.origin.y - normalizedBox.height) * imageHeight,
                                    width: normalizedBox.width * imageWidth,
                                    height: normalizedBox.height * imageHeight
                                )
                                wordRects.append(rect)
                            }
                            currentIndex = range.upperBound // Move the index forward
                        }
                        wordTexts.append(String(word))
                    }

                    // Append the word-level bounding boxes and texts
                    boundingRects.append(contentsOf: wordRects)
                    lineBoundingRects.append(CGRect.findBoundingRect(wordRects, true))
                    texts.append(contentsOf: wordTexts)
                }
            }
            
            completion(EncryptData(rects: boundingRects, texts: texts, lines: lines, map: storeIndecies)) // Return array of rectangles and texts
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"] // Chinese and English supported

        // Perform the request
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation(from: image.imageOrientation), options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Error performing text detection: \(error)")
                completion(nil)
            }
        }
     }*/
    func detectText(completion: @escaping (EncryptData?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil) // Invalid image
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(nil)
                return
            }
            
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            
            var boundingRects: [CGRect] = []
            //var lineBoundingRects: [CGRect] = []
            var texts: [String] = []
            var lines: [String] = []
            var storeIndecies: [Int:Int] = [:] // 1st Int: store char index, 2nd Int: store line index
            var wordIndex: Int = 0
            var charIndex: Int = 0
            
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else {
                    continue
                }
                let words = candidate.string.split(separator: " ")
                var currentIndex = candidate.string.startIndex
                for word in words {
                    var charRects: [CGRect] = []
                    for char in word {
                        if let range = candidate.string.range(of: String(char), range: currentIndex..<candidate.string.endIndex) {
                            // Get the bounding box for the character
                            if let charBox = try? candidate.boundingBox(for: range) {
                                let normalizedBox = charBox.boundingBox
                                let rect = CGRect(
                                    x: normalizedBox.origin.x * imageWidth,
                                    y: (1 - normalizedBox.origin.y - normalizedBox.height) * imageHeight,
                                    width: normalizedBox.width * imageWidth,
                                    height: normalizedBox.height * imageHeight
                                )
                                charRects.append(rect)
                            }
                            currentIndex = range.upperBound // Move the index forward
                        }
                        texts.append(String(char))
                        storeIndecies[charIndex] = wordIndex
                        charIndex += 1
                    }
                    boundingRects.append(contentsOf: charRects)
                    lines.append(String(word))
                    //let giantRect = CGRect.findBoundingRect(charRects)
                    //lineBoundingRects.append(giantRect)
                    wordIndex += 1
                }
            }
            completion(EncryptData(rects: boundingRects, texts: texts, lines: lines, map: storeIndecies))
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation(from: image.imageOrientation), options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Error performing text detection: \(error)")
                completion(nil)
            }
        }
    }
    
    // Perform OCR to extract text from the image
    func performOCR(completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil) // Invalid image
            return
        }
        
        // OCR request
        let textRecognitionRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(nil) // Handle errors or no results
                return
            }
            
            // Combine recognized text
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            completion(recognizedText.isEmpty ? nil : recognizedText)
        }
        
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
        
        // Perform the request
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImageOrientation(from: image.imageOrientation), options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([textRecognitionRequest])
            } catch {
                print("Error performing OCR: \(error)")
                completion(nil)
            }
        }
    }
}

struct EncryptData {
    var rects: [CGRect] = []
    var texts: [String] = []
    var lines: [String] = []
    var lineRects: [CGRect] = []
    var map: [Int: Int] = [:]
    
    init(rects: [CGRect], texts: [String], lines: [String], map: [Int: Int]) {
        self.rects = rects
        self.texts = texts
        self.lines = lines
        //self.lineRects = lineRects
        self.map = map
    }
}
