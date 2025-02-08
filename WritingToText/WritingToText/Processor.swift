//
//  Processor.swift
//  WritingToText
//
//  Created by Omeed on 12/20/24.
//

import Dispatch
import Foundation
import UIKit
import CoreImage
import CoreGraphics
import Vision

struct Processor{
    var uiImage: UIImage
    init(i:UIImage){
        uiImage = i
    }
    func findNumInRows(cgImage: CGImage){
        guard let data = getPixelData(cgImage: cgImage) else { return }
        var matrix = Array(repeating: Array(repeating: UInt8(0), count: cgImage.width), count: cgImage.height)
        for row in 0..<cgImage.height {
            var count = 0
            for col in 0..<cgImage.width {
                matrix[row][col] = data[row * cgImage.width + col]
                if(matrix[row][col]==0){
                    count += 1
                }
            }
            print("row: " + String(describing: row) + " count: " + String(describing: count))
        }
    }
    func displayImage() -> UIImage?{
        /*guard let prevCgImage = uiImage.cgImage else { return nil }
        findNumInRows(cgImage: prevCgImage)
        print(" \nDONE WITH FIRST IMAGE \n")
        if let ui = prepareImage(image: uiImage){
            if let cgImage = ui.cgImage{
                findNumInRows(cgImage: cgImage)
            }
            return ui
        }
        else{
            return nil
        }*/
        return uiImage
    }
    func thresholdImage(_ ciImage: CIImage, threshold: CGFloat) -> CIImage? {
        // Create a custom filter or apply logic to threshold the image
        // A threshold typically sets pixels above the threshold to white (1) and below to black (0)
        let filter = CIFilter(name: "CIColorControls") // This will need to be replaced with a custom thresholding filter
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(threshold, forKey: "inputBrightness") // Custom logic for setting threshold
        
        return filter?.outputImage
    }
    func prepareImage(image: UIImage) -> UIImage? {
        // Convert UIImage to CIImage
        guard let cgImage = image.cgImage else { return nil }
        guard let grayscaleImage = MakeGrayScale(image: cgImage) else { return nil }
        
        // 2. Apply Noise Reduction
        guard let noiseReduction = CIFilter(name: "CINoiseReduction") else { return nil }
        noiseReduction.setValue(CIImage(cgImage: grayscaleImage), forKey: kCIInputImageKey)
        noiseReduction.setValue(0.02, forKey: "inputNoiseLevel") // Adjust level
        noiseReduction.setValue(0.40, forKey: "inputSharpness")
        let denoisedImage = noiseReduction.outputImage
        
        // 3. Sharpen Image
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(denoisedImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(1.0, forKey: "inputSharpness")
        guard let sharpenedImage = sharpenFilter.outputImage else { return nil }
        
        guard let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur") else { return nil }
        gaussianBlurFilter.setValue(sharpenFilter, forKey: kCIInputImageKey)
        gaussianBlurFilter.setValue(5, forKey: kCIInputRadiusKey)
        
        guard let blurredImage = gaussianBlurFilter.outputImage else { return nil }
        /// 4. Threshold to Binarize
       // guard let thresholdedImage = thresholdImage(sharpenedImage, threshold: 0.5) else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(sharpenedImage, from: sharpenedImage.extent) else { return nil }
        guard let temp = binarizeImage(cgImage: cgImage, threshold: UInt8(122)) else { return nil }
        return UIImage(cgImage: temp)
    }
    func MakeGrayScale(image: CGImage?) -> CGImage?{
        if let i = image{
            guard let context = CGContext(
                data:nil,
                width: i.width,
                height:i.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space:CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue) 
            else{ 
            print("\nerror creating context")
            return nil}
            
            context.draw(i, in: CGRect(x: 0,y: 0,width: CGFloat(i.width), height: CGFloat(i.height)))
            
            if let cg = context.makeImage(){
                return cg
            }
            else{ return nil}
        }
        else{
            print("\nimage is invalid")
            return nil
        }
    }
    func binarizeImage(cgImage: CGImage, threshold: UInt8) -> CGImage? {
        guard let image = MakeGrayScale(image: cgImage) else { return nil }
        guard let data = getPixelData(cgImage: image) else { return nil }
        let binaryData = data.map { $0 < threshold ? UInt8(0) : UInt8(255) }
        return setPixelData(pixelData: binaryData, cgImage: cgImage)
    }
/*
    func makeBinary() -> CGImage? {
        if let i = MakeGrayScale() {
            if var data = getPixelData(cgImage: i) {
                // Binarize the image
                for ind in 0..<data.count {
                    if data[ind] < 100 {
                        data[ind] = 0
                    } else {
                        data[ind] = 255
                    }
                }
                var matrix = Array(repeating: Array(repeating: UInt8(0), count: i.width), count: i.height)
                for row in 0..<i.height {
                    for col in 0..<i.width {
                        matrix[row][col] = data[row * i.width + col]
                    }
                }
                var updatedData = [UInt8](repeating: 0, count: data.count)
                var index = 0
                for row in 0..<matrix.count {
                    for col in 0..<matrix[0].count {
                        updatedData[index] = matrix[row][col]
                        index += 1
                    }
                }
                return setPixelData(pixelData: updatedData)
            } else {
                return nil
            }
        }
        return nil
    }*/
    
    func getPixelData(cgImage: CGImage) -> [UInt8]?{
        guard let dataP = cgImage.dataProvider, let cfData = dataP.data, let cfDataPointer = CFDataGetBytePtr(cfData) else{
            print("\nfailed accessing image data")
            return nil
        }
        let bytesPerRow = cgImage.bytesPerRow
        let height = cgImage.height
        let totalBytes = height*bytesPerRow
        let pixelData = Array(UnsafeBufferPointer(start: cfDataPointer, count: totalBytes))
        return pixelData
    }
    func setPixelData(pixelData: [UInt8], cgImage: CGImage) -> CGImage?{
        let i = cgImage
        return pixelData.withUnsafeBufferPointer { buffer in
                    // Create CGContext using a mutable copy of the raw pixel data
                    guard let context = CGContext(data: UnsafeMutableRawPointer(mutating: buffer.baseAddress),
                                                  width: i.width,
                                                  height: i.height,
                                                  bitsPerComponent: 8,
                                                  bytesPerRow: i.width,
                                                  space: CGColorSpaceCreateDeviceGray(),
                                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                        print("Failed to create CGContext.")
                        return nil
                    }
                    return context.makeImage()
                }
    }
}
