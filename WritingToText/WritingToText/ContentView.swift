//
//  ContentView.swift
//  WritingToText
//
//  Created by Omeed on 12/19/24.
//



import SwiftUI
import VisionKit
import Combine
import Foundation
import PDFKit


struct ContentView: View {
    @State private var language = "CH"
    @State private var isPresentingScanner = false
    @State private var isCameraPresented = false
    @State private var isPhotoPresented = false
    @State private var isEditPresented = false
    @State private var isShareSheetPresented = false
    @State private var isTranslatePresented = false
    @State private var fileURL: URL? = nil
    @State private var processing = false
    private let rectSize = CGSize(width: 200, height: 150)
    
    @State private var images: [UIImage]? = nil
    @State private var pdfURL: URL? = nil
    
    //@Environment(\.dismiss) var dismiss
    var body: some View {
        GeometryReader{ geometry in
            var updatedURL: URL? = nil
            var cameraImage: UIImage? = nil
            var cameraImages: [UIImage]? = nil
            VStack {
                if(!processing){
                    HStack{
                        Menu {
                            Button("EN (English)") { language = "EN" }
                            Button("CH (Chinese)") { language = "CH" }
                        } label: {
                            ZStack{
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 50, height: 50)
                                Text(language)
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                    HStack{
                        Button(action: {
                            isPresentingScanner = true
                        }) {
                            Text("Scan Document")
                                .font(.system(size: 15))
                                .padding()
                                .frame(width: geometry.size.width/2, height: geometry.size.height/4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 5)
                        }
                        Button(action: {
                            isCameraPresented = true
                        }) {
                            Text("Take Photo")
                                .font(.system(size: 15))
                                .padding()
                                .frame(width: geometry.size.width/2, height: geometry.size.height/4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 5)
                        }
                    }
                }
                else {
                    Spacer()
                    HStack{
                        Spacer()
                        Text("Processing...")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                Spacer()
                Button(action: {
                    guard let pdfURL = Bundle.main.url(forResource: "PDFFile", withExtension: "pdf") else { return }
                    self.pdfURL = pdfURL
                    images = imagesFromPDF(pdfURL: pdfURL)
                }) {
                    Text("Retrieve PDF")
                        .font(.system(size: 15))
                        .padding()
                        .frame(width: geometry.size.width/2, height: geometry.size.height/4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                }
                
                .sheet(isPresented: $isCameraPresented) {
                    CameraPickerView { photo in
                        cameraImage = photo
                        isCameraPresented = false
                        isEditPresented = true
                    }
                }
                .sheet(isPresented: $isPresentingScanner) {
                    DocumentScannerView { photo in
                        processing = true
                        isPresentingScanner = false
                        cameraImages = photo
                        if let images = cameraImages {
                            var rectDatas: [EncryptData?] = Array(repeating: nil, count: images.count)
                            let dispatchGroup = DispatchGroup()
                            for i in 0..<images.count {
                                dispatchGroup.enter()
                                let processor = VisionProcessor(ui: images[i], language: "EN")
                                
                                processor.detectText() { data in
                                    if let d = data {
                                        rectDatas[i] = d
                                        
                                    } else {
                                        print("No text recognized.")
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                            dispatchGroup.notify(queue: .main) {
                                var datas: [EncryptData] = []
                                for data in rectDatas {
                                    if let d = data {
                                        datas.append(d)
                                    }
                                }
                                if let fileURL = createPDFWithPages(datas: datas, image: images[0]) {
                                    self.fileURL = fileURL
                                    DispatchQueue.main.async {
                                        isShareSheetPresented = true
                                        processing = false
                                        print("PDF created at: \(fileURL)")
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        processing = false
                                        print("Invalid PDF file.")
                                    }
                                }
                            }
                        }
                        
                    }
                }

                .sheet(isPresented: $isEditPresented) {
                    if let image = cameraImage {
                        EditImageView(uiImage: image, language: language) { photo in
                            isEditPresented = false
                            
                            // Check if photo was returned
                            if let photo = photo {
                                processing = true
                                
                                let processor = VisionProcessor(ui: photo.0, language: photo.1)
                                processor.performOCR() { recognizedText in
                                    if let text = recognizedText {
                                        // Process OCR and create PDF
                                        if let fileURL = createTextDocument(from: text) {
                                            DispatchQueue.main.async {
                                                self.fileURL = fileURL  // Update state on the main thread
                                                isShareSheetPresented = true  // Show share sheet
                                                processing = false
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                processing = false
                                                print("Invalid file")
                                            }
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            processing = false
                                            print("No text recognized.")
                                        }
                                    }
                                }
                            } else {
                                print("Invalid photo")
                            }
                        }
                    } else {
                        Text("Camera image is invalid.")
                    }
                }

                .sheet(isPresented: $isShareSheetPresented){
                    if let url = updatedURL ?? fileURL {
                        //Text("Sharing file: \(url)")
                        ActivityViewController(
                            activityItems: [url],
                            excludedActivityTypes: nil,
                            completionHandler: { completed in
                                processing = false
                                // When the share sheet is dismissed, set isShareSheetPresented to false
                                isShareSheetPresented = false
                                let fileManager = FileManager.default
                                do{
                                    if fileManager.fileExists(atPath: url.path){
                                        try fileManager.removeItem(at: url)
                                    }
                                }
                                catch{
                                    print("Error deleting file")
                                }
                                print(completed ? "Shared successfully" : "Sharing was canceled")
                                self.fileURL = nil
                            }
                        )
                        .onAppear(){
                            print("this view works")
                            self.fileURL = url
                        }
                    }
                    else{
                        Text("ERROR ")
                    }
                }
            }
            ZStack{
                if let image = images{
                    Image(uiImage: image[0])
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                }
            }
        }
        //.background(.white)
    }
    func imagesFromPDF(pdfURL: URL, size: CGSize? = nil) -> [UIImage] {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            print("Failed to load PDF.")
            return []
        }

        var images: [UIImage] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let pdfPage = pdfDocument.page(at: pageIndex) else {
                print("Failed to load page \(pageIndex).")
                continue
            }
            
            let pdfPageRect = pdfPage.bounds(for: .mediaBox)
            let renderSize = size ?? pdfPageRect.size
            
            // Create a UIGraphicsImageRenderer for the desired size
            let renderer = UIGraphicsImageRenderer(size: renderSize)
            
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Flip the context vertically
                cgContext.translateBy(x: 0, y: renderSize.height)
                cgContext.scaleBy(x: 1, y: -1)
                
                // Scale the context to handle the desired size
                let scale = CGSize(width: renderSize.width / pdfPageRect.width,
                                   height: renderSize.height / pdfPageRect.height)
                cgContext.scaleBy(x: scale.width, y: scale.height)
                
                // Render the PDF page into the context
                pdfPage.draw(with: .mediaBox, to: cgContext)
            }
            
            images.append(image)
        }
        
        return images
    }

    func createPDFWithPages(datas: [EncryptData], image: UIImage) -> URL? {
        // Step 1: Set PDF metadata
        let pdfMetaData = [
            kCGPDFContextCreator: "WritingToText",
            kCGPDFContextAuthor: "..."
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2 // 8.5 inches * 72 dpi
        let pageHeight = 841.8 // 11 inches * 72 dpi
        let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        print(String(describing: image.size.width) + " " + String(describing: image.size.height))
        let aspectRatio = CGFloat(min(pageWidth/image.size.width, pageHeight/image.size.height))
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentDirectory.appendingPathComponent("text.pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        do {
            try renderer.writePDF(to: fileURL, withActions: { context in
                for data in datas {
                    print("text: " + data.texts[0])
                    var scaledRects: [CGRect] = []
                    let centerPos = CGPoint(x: image.size.width/2, y: image.size.height/2)
                    for rect in data.lineRects {
                        let rectPos = rect.origin
                        let delta = (centerPos-rectPos) * aspectRatio
                        scaledRects.append(CGRect(x: rectPos.x * aspectRatio, y: rectPos.y * aspectRatio, width: rect.width * aspectRatio, height: rect.height * aspectRatio))
                    }
                    let string = data.texts
                    let lines = data.lines
                    let spacing = CGFloat((pageHeight-100)/Double(lines.count))
                    let lineWidth = pageWidth - 100
                    context.beginPage()
                    for i in 0..<lines.count {
                        //let textRect = CGRect(x: scaledRects[i].origin.x, y: scaledRects[i].origin.y, width: scaledRects[i].width, height: scaledRects[i].height)
                        //print(scaledRects[i])
                        var font = CGFloat(14);
                        while(!doesTextFitInRect(lines[i], rect: scaledRects[i], font: UIFont.systemFont(ofSize: font))){
                            font -= 1;
                        }
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: font),
                            .foregroundColor: UIColor.black
                        ]
                        lines[i].draw(in: scaledRects[i], withAttributes: attributes)
                        
                    }
                    //print("original: " + String(describing: data.lineRects))
                }
            })
            
            print("PDF created at: \(fileURL)")
            return fileURL
        } catch {
            print("Could not create PDF: \(error)")
            return nil
        }
    }
    
    func doesTextFitInRect(_ text: String, rect: CGRect, font: UIFont) -> Bool {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        
        let boundingRect = (text as NSString).boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                                                            options: .usesLineFragmentOrigin,
                                                            attributes: attributes,
                                                            context: nil)
        
        return boundingRect.width <= rect.width && boundingRect.height <= rect.height
    }
    
    func createTextDocument(from string: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentDirectory.appendingPathComponent("text.txt")
        
        do {
            try string.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File created at: \(fileURL)") 
            return fileURL
        } catch {
            print("Error writing text to file: \(error)")
            return nil
        }
    }

}
#Preview {
    ContentView()
}
