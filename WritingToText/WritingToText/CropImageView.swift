import SwiftUI
import SQLite3

struct CropImageView: View {
    var uiImage: UIImage
    @Binding var cropData: CropData
    var completion: (UIImage) -> Void
    @State private var geometrySize: CGSize = .zero
    @State private var circlePosLT: CGPoint = .zero
    @State private var circlePosRT: CGPoint = .zero
    @State private var circlePosLB: CGPoint = .zero
    @State private var circlePosRB: CGPoint = .zero
    @State private var LTDragged: Bool = false
    @State private var RTDragged: Bool = false
    @State private var LBDragged: Bool = false
    @State private var RBDragged: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let rectHeight = geometry.size.height / ratio
                let aspectRatio = uiImage.size.height / uiImage.size.width
                let imageHeight = geometry.size.height - rectHeight
                //+let imageHeight = geometry.size.height
                let imageWidth = imageHeight / aspectRatio
                let offset = rectHeight / 2
                let left = (geometry.size.width - imageWidth) / 2
                let LT = CGPoint(x:left, y:0)
                let RT = CGPoint(x:left+imageWidth, y:0)
                let LB = CGPoint(x:left, y: imageHeight)
                let RB = CGPoint(x: left + imageWidth, y: imageHeight)
                
                // Background Image
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: imageWidth, height: imageHeight)
                    .offset(y: -offset)
                   // .ignoresSafeArea(.all)
                
                DraggableCircle(position: $circlePosLT, initialPosition: LT, drag: $LTDragged)
                DraggableCircle(position: $circlePosRT, initialPosition: RT, drag: $RTDragged)
                DraggableCircle(position: $circlePosLB, initialPosition: LB, drag: $LBDragged)
                DraggableCircle(position: $circlePosRB, initialPosition: RB, drag: $RBDragged)
                
                
                
                CroppedShape(
                    LT: LTDragged ? circlePosLT : LT,
                    RT: RTDragged ? circlePosRT : RT,
                    LB: LBDragged ? circlePosLB : LB,
                    RB: RBDragged ? circlePosRB : RB
                )
                .fill(Color.yellow)
                .opacity(0.25)
            }
            .onAppear {
                geometrySize = geometry.size // Update geometrySize when the view appears
            }
        }
        .onDisappear(){
            if(geometrySize != .zero){
                // Update all corner positions based on whether they were dragged
                let rectHeight = geometrySize.height / ratio
                let aspectRatio = uiImage.size.height / uiImage.size.width
                let imageHeight = geometrySize.height - rectHeight
                let imageWidth = imageHeight / aspectRatio
                let offset = rectHeight / 2
                let left = (geometrySize.width - imageWidth) / 2
                let LT = CGPoint(x: left, y: 0)
                let RT = CGPoint(x: left + imageWidth, y: 0)
                let LB = CGPoint(x: left, y: imageHeight)
                let RB = CGPoint(x: left + imageWidth, y: imageHeight)
                
                // Assign positions for all corners
                circlePosLT = (LTDragged ? circlePosLT : LT) - CGPoint(x:left, y:-offset)
                circlePosRT = (RTDragged ? circlePosRT : RT) - CGPoint(x:left, y:-offset)
                circlePosLB = (LBDragged ? circlePosLB : LB) - CGPoint(x:left, y:-offset)
                circlePosRB = (RBDragged ? circlePosRB : RB) - CGPoint(x:left, y:-offset)
                
                let ratio = uiImage.size.width/imageWidth
                let minX = min(circlePosLT.x * ratio, circlePosLB.x * ratio)
                let maxX = max(circlePosRT.x * ratio, circlePosRB.x * ratio)
                let minY = min(circlePosLT.y * ratio, circlePosRT.y * ratio)
                let maxY = max(circlePosLB.y * ratio, circlePosRB.y * ratio)
                let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                
                let renderer = UIGraphicsImageRenderer(size: uiImage.size)
                let newImage = renderer.image { context in
                    let ctx = context.cgContext
                    
                    // Fill the background with white
                    ctx.setFillColor(UIColor.white.cgColor)
                    ctx.fill(CGRect(origin: .zero, size: uiImage.size))
                    
                    // Define the clipping path
                    let path = CGMutablePath()
                    path.move(to: CGPoint(x: circlePosLT.x * ratio, y: circlePosLT.y * ratio))
                    path.addLine(to: CGPoint(x: circlePosRT.x * ratio, y: circlePosRT.y * ratio))
                    path.addLine(to: CGPoint(x: circlePosRB.x * ratio, y: circlePosRB.y * ratio))
                    path.addLine(to: CGPoint(x: circlePosLB.x * ratio, y: circlePosLB.y * ratio))
                    path.closeSubpath()
                    
                    // Clip to the path
                    ctx.addPath(path)
                    ctx.clip()
                    
                    // Draw the image inside the clipped region
                    uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
                }
                completion(newImage)
            }
        }
    }
}

struct CropData {
    var circlePosLT: CGPoint = .zero
    var circlePosRT: CGPoint = .zero
    var circlePosLB: CGPoint = .zero
    var circlePosRB: CGPoint = .zero
    var LTDragged: Bool = false
    var RTDragged: Bool = false
    var LBDragged: Bool = false
    var RBDragged: Bool = false
}

struct DraggableCircle: View {
    // Binding to the position passed in
    @Binding var position: CGPoint
    var initialPosition: CGPoint
    @Binding var drag: Bool
    @State private var hasStartedDragging: Bool = false
    var body: some View {
        Circle()
                    .fill(Color.blue)
                    .frame(width: size, height: size)
                    .position(hasStartedDragging ? position : initialPosition) // Set initialPosition initially
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !hasStartedDragging {
                                    hasStartedDragging = true // Mark as started dragging
                                    drag = true
                                }
                                position = value.location // Update position during drag
                            }
                    )
    }
}

struct CroppedShape: Shape {
    var LT: CGPoint
    var RT: CGPoint
    var LB: CGPoint
    var RB: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: LT)
        path.addLine(to: RT)
        path.addLine(to: RB)
        path.addLine(to: LB)
        path.closeSubpath()
        return path
    }
}
