import CoreGraphics

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}

extension CGPoint {
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
}

extension CGPoint {
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
}

extension CGPoint {
    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x/right, y: left.y/right)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return sqrt(dx * dx + dy * dy)
    }
}

extension CGSize {
    static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }
}

extension CGSize {
    static func - (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width - right.width, height: left.height - right.height)
    }
}

extension CGSize {
    static func * (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }
}

extension CGRect {
    static func findBoundingRect(_ rects: [CGRect], _ useFirstHeight: Bool = false) -> CGRect {
        // Ensure the array isn't empty
        guard let firstRect = rects.first else {
            return CGRect.zero // Return zero rect if the array is empty
        }
        
        var minX = firstRect.minX
        var minY = firstRect.minY
        var maxX = firstRect.maxX
        var maxY = firstRect.maxY
        
        for rect in rects.dropFirst() {
            minX = min(minX, rect.minX)
            minY = min(minY, rect.minY)
            maxX = max(maxX, rect.maxX)
            maxY = max(maxY, rect.maxY)
        }
        if(useFirstHeight){
            return CGRect(x: rects[0].origin.x, y: rects[0].origin.y, width: maxX - minX, height: rects[0].height)
        }
        else{
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }
}

class CustomList<T>{
    private var data: [T?] = []
    init(_ count: Int){
        for _ in 0..<count{
            data.append(nil)
        }
    }
    func add(_ newElement: T){
        var foundSlot = false
        for ind in 0..<data.count{
            if(data[ind]==nil){
                data[ind] = newElement
                foundSlot = true
                break
            }
        }
        if(!foundSlot){
            data.append(newElement)
        }
    }
    func removeSlot(at ind: Int){
        data[ind] = nil
    }
}
