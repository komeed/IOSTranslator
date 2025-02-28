/**
 Why do I use draggesture to register clicks instead of using tapgesture or having each individual rectangle work as a button?
 1. If I use buttons instead of rectangles, I no longer will be able to drag and zoom the image. Instead, every time my finger comes across one of the buttons, the image will then be immovable because the button takes top priority, and there isn't a way to only prioritize button if it is tapped and released without moving.
 2. If I use a tapgesture instead of a draggesture, the code will be poorly written because I will then need to implement two simultaneous gestures instead of having one overall draggesture. Which leads into
 
 Benefits:
  Instead of having more than two simultaneous gestures (more than magnification and drag), I implemented the touch gesture into the drag gesture itself, making the gesture not only detect drag but also touch based on the minimum distance being zero (final position is equal to original position).
 
 Why do I use a message broadcaster when the current view is still a contentview?
 I don't know I should probably fix that
 
 Rect position: the original rect position without scaling or dragging. Use this when trying to find the current posiiton of the rect by using offsetposition
 ScaledRectPosition: One of the problems with magnification based on the center of the view is, if you've dragged and then magnified, the position will be distorted. so, we store the updated magnified position using scaledrectposition
 RealRectPosition: This is basically the overall rectposition after all dragging and scaling. It uses scaledrectposition and offset multiplied by scale to
 startOffsetPosition: measure the offsetposition before dragging to add this value to offsetposition to correctly determine the position of the image during dragging because In the .changed page we are measuring the change in position
 OffsetPosition: measure the offsetposition when dragging, and ultimately combine this with startOffsetPosition to calculate the final image offset position
 scale: Measure the final scale through magnifications, startScale: similar to offsetposition, measure the startscale before scaling to accurately determine the final scale
 
**/

import SwiftUI
import CoreGraphics
import Translation

struct TranslateImageView: View {
    var uiImage: UIImage
    var language: String
    
    @StateObject private var broadcaster = MessageBroadcaster()
    
    @State private var rects: [RectData] = [] // store all rects
    @State private var collectedRects: [RectData] = [] // store the rects that are currently selected using the select button
    @State private var giantRect: RectData? = nil // in the case of multiple rectangles, use the combineRects function to form 1 rect
    @State private var scale: CGFloat = 1.0
    @State private var startScale: CGFloat = 1
    @State private var offsetPosition: CGPoint = .zero
    @State private var startOffsetPosition: CGPoint = .zero
    
    @State private var indices: [Int] = []
    @State private var tempIndex: [Int] = []
    @State private var tapLocation: CGPoint = .zero
    @State private var sql = MySequel()
    @State private var data: ChineseData? = nil
    @State private var selectedModeOn = false
    @State private var openMenu = false
    
    @State private var showDefinitions: Bool = false
    @State private var byLine: Bool = false
    
    @State private var configuration: TranslationSession.Configuration?
    
    private let selectButtonSize = CGSize(width: 100, height: 50) // the select button
    private let rectSize = CGSize(width: 300, height: 200) // the popup window size

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                //show image
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(CGPoint(x: geometry.size.width/2, y: geometry.size.height/2) + offsetPosition)
                    .scaleEffect(scale)
                
                //showing each rect
                ForEach(rects.indices, id: \.self) { index in
                    let rect = rects[index].rect
                    let position = rects[index].rectPosition + offsetPosition
                    Rectangle()
                        .fill(Color.yellow.opacity(0.25))
                        .frame(width: rect.width, height: rect.height)
                        .position(position)
                        .scaleEffect(scale)
                }
                
                //showing the collected rects in red
                ForEach(collectedRects.indices, id: \.self){ index in
                    let rect = collectedRects[index].rect
                    let position = collectedRects[index].rectPosition + offsetPosition
                    Rectangle()
                        .fill(Color.red.opacity(0.25))
                        .frame(width: rect.width, height: rect.height)
                        .position(position)
                        .scaleEffect(scale)
                }
                
                //blank swiftui view to contain all the gestures and includes tapgesture from draggesture
                Color.clear
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .position(CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                    .contentShape(Rectangle())
                    .gesture(
                        !openMenu ? DragGesture(minimumDistance: 0) // make sure to only have these functionalities if the popup is closed
                            .onChanged() { value in
                                offsetPosition = startOffsetPosition + CGPoint(x:value.translation.width, y: value.translation.height)/scale
                            }
                            .onEnded() { value in
                                for i in 0..<rects.count {
                                    rects[i].realPosition = rects[i].scaledRectPosition + offsetPosition*scale
                                }
                                if(startOffsetPosition == offsetPosition){ // if the finger hasn't moved yet (you clicked it)
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
                                                        indices.append(contentsOf: tempIndex)
                                                        tempIndex.removeAll()
                                                        var line: String = ""
                                                        for rect in collectedRects {
                                                            line += rect.line
                                                        }
                                                        if let rect = combineRects(rects: collectedRects, line: line) {
                                                            data = sql.access(word: line)
                                                            openMenu = true
                                                            giantRect = rect
                                                        }
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
                        //what happens once you close out of the popup window below (only if the menu is open)
                        openMenu ? TapGesture()
                            .onEnded(){ value in
                                indices.removeAll()
                                openMenu = false
                                selectedModeOn = false
                                broadcaster.outputText = nil
                            }
                        : nil
                    )
                if(openMenu){
                    //show popup window
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
                        if let data = self.data {
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
                                        Text(byLine ? rect.line : rect.word)
                                            .font(.system(size: 24))
                                            .lineLimit(1) // Prevent overflow in the word
                                        Spacer()
                                        Text(data.pinyin)
                                            .font(.system(size: 24))
                                            .lineLimit(1) // Prevent overflow in the pinyin
                                        Spacer()
                                    }
                                    
                                    ScrollView {
                                        VStack(alignment: .leading) {
                                            Text("definitions:")
                                                .font(.system(size: 24))
                                                .frame(maxWidth: .infinity, alignment: .center)
                                            if let output = broadcaster.outputText {
                                            Text(output)
                                                .font(.system(size: 24))
                                             }
                                            if(showDefinitions){
                                                ForEach(defns.indices, id: \.self) { index in
                                                    Text(defns[index])
                                                        .font(.system(size: 14))
                                                        .frame(maxWidth: .infinity, alignment: .center) // Contain text inside VStack
                                                }
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
                            .onAppear() {
                                broadcaster.inputText = (byLine ? rect.line : rect.word);
                            }
                        }
                    }
                }
                VStack{
                    Spacer()
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geometry.size.width, height: selectButtonSize.height)
                }
                VStack{
                    Spacer()
                    HStack{
                        //Toggle to determine whether you want to select by character or by line
                        Toggle((byLine ? "By Line" : "By Character"), isOn: $byLine)
                            .toggleStyle(.button)
                            .contentTransition(.symbolEffect)
                        Spacer()
                        //Toggle to determine whether to use dictionary (mysql) definitions (will be more accurate for short words)
                        Toggle(isOn: $showDefinitions){
                            Text("Show Defns")
                                .strikethrough(!showDefinitions)
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(.button)
                        .contentTransition(.symbolEffect)
                        Spacer()
                        //select button
                        if (!openMenu && !byLine){
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
                Translator(broadcaster: broadcaster)
            }
            .onAppear {
                broadcaster.startedProcessing = true //make sure not to show "Camera Image invalid"
                let processor = VisionProcessor(ui: uiImage, language: language)
                
                processor.detectText { result in
                    guard let rects = result?.rects, let words = result?.texts, let lines = result?.lines, let map = result?.map else {
                        print("Invalid results from VisionProcessor")
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
                                                       word: words[i], line: lines[map[i] ?? 0]))
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
    func combineRects(rects: [RectData], line: String = "") -> RectData?{
        let boundingRect = CGRect.findBoundingRect(getRects(from: rects))
        guard let midpos1 = findMidpoint(of: getRectPositions(from: rects)) else { return nil }
        guard let midpos2 = findMidpoint(of: getScaledRectPositions(from: rects)) else { return nil }
        guard let midpos3 = findMidpoint(of: getRealPositions(from: rects)) else { return nil }
        var words = ""
        for rect in rects{
            words += rect.word
        }
        return RectData(rect: boundingRect, pos1: midpos1, pos2: midpos2, pos3: midpos3, word: words, line: line)
    }
}

struct RectData {
    var rect: CGRect
    var rectPosition: CGPoint
    var scaledRectPosition: CGPoint
    var realPosition: CGPoint
    var word: String
    var line: String
    
    init(rect: CGRect, pos: CGPoint, word: String, line: String){
        self.rect = rect
        self.rectPosition = pos
        self.scaledRectPosition = pos
        self.realPosition = pos
        self.word = word
        self.line = line
    }
    init(rect: CGRect, pos1: CGPoint, pos2: CGPoint, pos3: CGPoint, word: String, line: String){
        self.rect = rect
        self.rectPosition = pos1
        self.scaledRectPosition = pos2
        self.realPosition = pos3
        self.word = word
        self.line = line
    }
}
