import SwiftUI
import UIKit
import CoreGraphics

let ratio = CGFloat(14)
let size = CGFloat(25)

struct EditImageView: View {
    var uiImage: UIImage
    var language: String
    var completion: ((UIImage, String)?) -> Void
    @State private var updatedUIImage: UIImage? = nil
    @State private var showCropView = false
    @State private var showTranslateView = false
    @State private var cropData = CropData() 
    @State private var showDropdownMenu = false
    @State private var updatedLanguage:String? = nil

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    let rectHeight = geometry.size.height / ratio
                    let imageHeight = geometry.size.height - rectHeight
                    if let image = updatedUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: imageHeight)
                            .offset(y: -rectHeight / 2)
                    } else {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: imageHeight)
                            .offset(y: -rectHeight / 2)
                    }
                    
                    VStack {
                        HStack{
                            Menu {
                                Button("EN (English)") { updatedLanguage = "EN" }
                                Button("CH (Chinese)") { updatedLanguage = "CH" }
                            } label: {
                                ZStack{
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 50, height: 50)
                                    Text(updatedLanguage ?? language)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                                Spacer()
                            }
                        }
                        Spacer()
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: geometry.size.width, height: rectHeight)
                            .opacity(0.75)
                    }
                    
                    VStack {
                        Spacer()
                        Menu("Done") {
                            Button("Save"){
                                if let image = updatedUIImage {
                                    completion((image, updatedLanguage ?? language))
                                }
                                else{
                                    completion((uiImage, updatedLanguage ?? language))
                                }
                            }
                            Button("Delete"){
                                completion(nil)
                            }
                        }
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    VStack{
                        Spacer()
                        HStack {
                            Button("Translate"){
                                showTranslateView = true
                            }
                            Spacer()
                            Button("Crop Image") {
                                showCropView = true
                            }
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .navigationTitle("Edit Image")
                .navigationBarHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showCropView) {
                    CropImageView(uiImage: uiImage, cropData: $cropData) { croppedImage in
                        showCropView = false
                        updatedUIImage = croppedImage
                    }
                    .interactiveDismissDisabled(true)
                }
                .navigationDestination(isPresented: $showTranslateView){
                    TranslateImageView(uiImage:updatedUIImage ?? uiImage, language: updatedLanguage ?? language)
                    .interactiveDismissDisabled(true)
                    //TestTranslateImageView(uiImage: uiImage){ photo in
                    //}
                    //.interactiveDismissDisabled(true)
                   // Test(uiImage: uiImage){ photo in
                    //}
                    //.interactiveDismissDisabled(true)
                    //stupid()
                    
                }
            }
        }
    }
}





