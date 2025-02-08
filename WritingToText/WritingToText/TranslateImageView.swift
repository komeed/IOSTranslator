import SwiftUI
import CoreGraphics

struct TranslateImageView: View {
    var uiImage: UIImage
    var language: String
    
    @State private var rects: [RectData] = []
    @State private var collectedRects: [RectData] = []
    @State private var giantRect: RectData? = nil
    @State private var scale: CGFloat = 1.0
    @State private var startScale: CGFloat = 1
    @State private var offsetPosition: CGPoint = .zero
    @State private var startOffsetPosition: CGPoint = .zero
    
    @State private var indices: [Int] = []
    @State private var tempIndex: [Int] = []
    @State private var tapLocation: CGPoint = .zero
    @State private var sql = MySequel()
    @State private var selectedModeOn = false
    @State private var openMenu = false

    private let selectButtonSize = CGSize(width: 100, height: 50)
    private let rectSize = CGSize(width: 300, height: 200)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(CGPoint(x: geometry.size.width/2, y: geometry.size.height/2) + offsetPosition)
                    .scaleEffect(scale)
                ForEach(rects.indices, id: \.self) { index in
                    let rect = rects[index].rect
                    let position = rects[index].rectPosition + offsetPosition
                    Rectangle()
                        .fill(Color.yellow.opacity(0.25))
                        .frame(width: rect.width, height: rect.height)
                        .position(position)
                        .scaleEffect(scale)
                }
                ForEach(collectedRects.indices, id: \.self){ index in
                    let rect = collectedRects[index].rect
                    let position = collectedRects[index].rectPosition + offsetPosition
                    Rectangle()
                        .fill(Color.red.opacity(0.25))
                        .frame(width: rect.width, height: rect.height)
                        .position(position)
                        .scaleEffect(scale)
                }
                Color.clear
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                    .contentShape(Rectangle())
                    .gesture(
                        !openMenu ? DragGesture(minimumDistance: 0)
                            .onChanged() { value in
                                offsetPosition = startOffsetPosition + CGPoint(x:value.translation.width, y: value.translation.height)/scale
                            }
                            .onEnded() { value in
                                for i in 0..<rects.count {
                                    rects[i].realPosition = rects[i].scaledRectPosition + offsetPosition*scale
                                }
                                if(startOffsetPosition == offsetPosition){
                                    tapLocation = value.location
                                    if(self.indices.count == 0){
                                        for i in 0..<rects.count {
                                            let rect = rects[i].rect
                                            let position = rects[i].realPosition
                                            if(tapLocation.x < position.x + (rect.width*scale/2) && tapLocation.x > position.x - (rect.width*scale/2) && tapLocation.y < position.y + (rect.height*scale/2) && tapLocation.y > position.y - (rect.height*scale/2)){
                                                var check = false;
                                                for index in 0..<tempIndex.count{
                                                    if i == tempIndex[index] {
                                                        tempIndex.remove(at: index)
                                                        collectedRects.remove(at: index)
                                                        check = true
                                                        break;
                                                    }
                                                }
                                                if(!check){
                                                    self.tempIndex.append(i)
                                                    self.collectedRects.append(rects[i])
                                                    if(!selectedModeOn){
                                                        openMenu = true
                                                        indices.append(contentsOf: tempIndex)
                                                        tempIndex.removeAll()
                                                        print(collectedRects.count)
                                                        giantRect = combineRects(rects: collectedRects)
                                                        collectedRects.removeAll()
                                                    }
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                                startOffsetPosition = offsetPosition
                            }
                        : nil
                    )
                    .simultaneousGesture(
                        !openMenu ? MagnificationGesture()
                            .onChanged(){ value in
                                scale = value*startScale
                            }
                            .onEnded(){ value in
                                for i in 0..<rects.count {
                                    let delta2 = (rects[i].rectPosition - CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)) * scale
                                    rects[i].scaledRectPosition = delta2 + CGPoint(x:geometry.size.width/2, y: geometry.size.height/2)
                                    rects[i].realPosition = rects[i].scaledRectPosition + offsetPosition * scale
                                }
                                startScale = scale
                            }
                        : nil
                    )
                    .simultaneousGesture(
                        openMenu ? TapGesture()
                            .onEnded(){ value in
                                indices.removeAll()
                                openMenu = false
                                selectedModeOn = false
                            }
                        : nil
                    )
                if(openMenu){
                    if let rect = giantRect {
                        let posOffsetX = max(0, rectSize.width/2 - rect.realPosition.x)
                        let negOffsetX = min(0, geometry.size.width-rect.realPosition.x - rectSize.width/2)
                        let size = rect.rect.size * scale
                        let position = CGPoint(
                            x: rect.realPosition.x + posOffsetX + negOffsetX,
                            y: rectSize.height + size.height/2 - rect.realPosition.y < 0
                            ? rect.realPosition.y - (size.height / 2) - rectSize.height / 2
                            : rect.realPosition.y + (size.height / 2) + rectSize.height / 2
                        )
                        let topPos = CGPoint(x: position.x, y: position.y - rectSize.height/2)
                        if let data = sql.access(word: rect.word, language: language) {
                            let defns = data.def
                            ZStack {
                                VStack {
                                    HStack{
                                        Spacer()
                                        Text("Chinese")
                                            .font(.title)
                                        //.padding(.top, 10)
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        Text(rect.word)
                                            .font(.system(size: 24))
                                            .lineLimit(1) // Prevent overflow in the word
                                        Spacer()
                                        Text(data.pinyin)
                                            .font(.system(size: 24))
                                            .lineLimit(1) // Prevent overflow in the pinyin
                                        Spacer()
                                    }
                                    //.padding([.leading, .trailing], 10)
                                    
                                    ScrollView {
                                        VStack(alignment: .leading) {
                                            Text("definitions:")
                                                .font(.system(size: 14))
                                                .frame(maxWidth: .infinity, alignment: .center)
                                            ForEach(defns.indices, id: \.self) { index in
                                                Text(defns[index])
                                                    .font(.system(size: 12))
                                                    .frame(maxWidth: .infinity, alignment: .center) // Contain text inside VStack
                                            }
                                        }
                                        //.padding([.leading, .trailing], 10)
                                    }
                                    //.frame(maxHeight: 100) // Limit the height for scrolling
                                    .padding(.leading, 10) // Add padding to the left side of the ScrollView
                                    .padding(.bottom, 10)
                                }
                                .frame(width: rectSize.width, height: rectSize.height) // Make the width slightly smaller for padding
                                .position(position)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 30/255, green: 30/255, blue: 30/255).opacity(0.9))
                                        .frame(width: rectSize.width, height: rectSize.height)
                                        .position(position)
                                )
                            }
                        }
                    }
                }
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        if (!openMenu){
                            if(!selectedModeOn){
                                Button(action: {
                                    selectedModeOn = true
                                }) {
                                    Text("Select")
                                        .font(.system(size: 15))
                                        .padding() // Add padding around the text
                                        .frame(width: selectButtonSize.width, height: selectButtonSize.height) // Make the button fill horizontally and have a minimum height
                                        .background(Color.blue) // Background color of the button
                                        .foregroundColor(.white) // Text color
                                        .cornerRadius(selectButtonSize.height/2) // Round the corners of the button
                                        .shadow(radius: 5) // Add a shadow effect to the button
                                }
                            }
                            else{
                                Button(action: {
                                    selectedModeOn = false
                                    tempIndex.removeAll()
                                    collectedRects.removeAll()
                                }) {
                                    Text("X")
                                        .font(.system(size: 15))
                                        .padding() // Add padding around the text
                                        .frame(width: selectButtonSize.width/2, height: selectButtonSize.height) // Make the button fill horizontally and have a minimum height
                                        .background(Color.red) // Background color of the button
                                        .foregroundColor(.white) // Text color
                                        .cornerRadius(selectButtonSize.height/2) // Round the corners of the button
                                        .shadow(radius: 5) // Add a shadow effect to the button
                                }
                                Button(action: {
                                    selectedModeOn = false
                                    if(tempIndex.count != 0){
                                        indices.append(contentsOf: tempIndex)
                                        tempIndex.removeAll()
                                        giantRect = combineRects(rects: collectedRects)
                                        collectedRects.removeAll()
                                        openMenu = true
                                    }
                                }) {
                                    Text("Done")
                                        .font(.system(size: 15))
                                        .padding() // Add padding around the text
                                        .frame(width: 3*selectButtonSize.width/4, height: selectButtonSize.height) // Make the button fill horizontally and have a minimum height
                                        .background(Color.green) // Background color of the button
                                        .foregroundColor(.white) // Text color
                                        .cornerRadius(selectButtonSize.height/2) // Round the corners of the button
                                        .shadow(radius: 5) // Add a shadow effect to the button
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                let processor = VisionProcessor(ui: uiImage, language: language)
                
                processor.detectText { result in
                    guard let rects = result?.rects else {
                        print("Invalid rects")
                        return
                    }
                    guard let words = result?.texts else {
                        print("Invalid texts")
                        return
                    }
                    // Calculate scaling factors
                    let scale = min(geometry.size.width/uiImage.size.width, geometry.size.height/uiImage.size.height)
                    let aspectRatio = uiImage.size.height / uiImage.size.width
                    let imageHeight = geometry.size.height
                    let imageWidth = imageHeight / aspectRatio
                    let left = (geometry.size.width - imageWidth) / 2
                    
                    let scaledRects = rects.map { rect in
                        CGRect(
                            x: rect.origin.x * scale + left,
                            y: rect.origin.y * scale,
                            width: rect.width * scale,
                            height: rect.height * scale
                        )
                    }
                    
                    DispatchQueue.main.async {
                        for i in 0..<rects.count{
                            self.rects.append(RectData(rect: scaledRects[i],
                                                       pos: CGPoint(x: scaledRects[i].midX, y: scaledRects[i].midY),
                                                       word: words[i]))
                        }
                    }
                }
            }
        }
    }
    func findMidpoint(of points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else {
            // Return nil if the array is empty
            return nil
        }
        
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        
        // Sum up the x and y coordinates of all points
        for point in points {
            sumX += point.x
            sumY += point.y
        }
        
        // Calculate the midpoint by averaging the x and y coordinates
        let midpoint = CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
        
        return midpoint
    }
    func getRects(from rectDataArray: [RectData]) -> [CGRect] {
        return rectDataArray.map { $0.rect }
    }
    func getRectPositions(from rectDataArray: [RectData]) -> [CGPoint] {
        return rectDataArray.map { $0.rectPosition }
    }
    func getScaledRectPositions(from rectDataArray: [RectData]) -> [CGPoint] {
        return rectDataArray.map { $0.scaledRectPosition }
    }
    func getRealPositions(from rectDataArray: [RectData]) -> [CGPoint] {
        return rectDataArray.map { $0.realPosition }
    }
    func combineRects(rects: [RectData]) -> RectData?{
        let boundingRect = CGRect.findBoundingRect(getRects(from: rects))
        guard let midpos1 = findMidpoint(of: getRectPositions(from: rects)) else { return nil }
        guard let midpos2 = findMidpoint(of: getScaledRectPositions(from: rects)) else { return nil }
        guard let midpos3 = findMidpoint(of: getRealPositions(from: rects)) else { return nil }
        var words = ""
        for rect in rects{
            words += rect.word
        }
        return RectData(rect: boundingRect, pos1: midpos1, pos2: midpos2, pos3: midpos3, word: words)
    }
    /*func translate(word: String) async -> String?{
        do{
            let translator = Translator("https://libretranslate.de")
            let translation = try await translator.translate(word, from: "en", to: "zh")
            return translation
        }
        catch {
            print(error)
            return nil
        }
    }*/
}

struct RectData {
    var rect: CGRect
    var rectPosition: CGPoint
    var scaledRectPosition: CGPoint
    var realPosition: CGPoint
    var word: String
    init(rect: CGRect, pos: CGPoint, word: String){
        self.rect = rect
        self.rectPosition = pos
        self.scaledRectPosition = pos
        self.realPosition = pos
        self.word = word
    }
    init(rect: CGRect, pos1: CGPoint, pos2: CGPoint, pos3: CGPoint, word: String){
        self.rect = rect
        self.rectPosition = pos1
        self.scaledRectPosition = pos2
        self.realPosition = pos3
        self.word = word
    }
}

/*struct TranslateImageView_Previews: PreviewProvider {
    static var previews: some View {
        TranslateImageView(uiImage: UIImage(named: "exampleImage")!, langauge: langauge) { _ in }
    }
 }*/
