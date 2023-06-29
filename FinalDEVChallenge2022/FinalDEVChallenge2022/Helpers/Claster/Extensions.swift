//
//  Extensions.swift
//  Cluster
//
//

import Foundation
import MapKit

extension DateFormatter {
    static let shotFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        return df
    }()
}

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

extension UIView {
    class var nib: UINib {
        UINib(nibName: NSStringFromClass(self).components(separatedBy: ".").last!, bundle: nil)
    }
    class func initFromNib<T: UIView>() -> T {
        Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)![0] as! T
    }
}


extension UIImage {
    static let me = UIImage(named: "me")?.filled(with: .blue)

    func filled(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(CGBlendMode.normal)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let mask = cgImage else { return self }
        context.clip(to: rect, mask: mask)
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension MKMapView {
    func annotationView<T: MKAnnotationView>(of type: T.Type, annotation: MKAnnotation?, reuseIdentifier: String) -> T {
        guard let annotationView = dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? T else {
            return type.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        annotationView.annotation = annotation
        return annotationView
    }
}


extension MKMapRect {
    init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.init(x: minX, y: minY, width: abs(maxX - minX), height: abs(maxY - minY))
    }
    init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: MKMapPoint(x: x, y: y), size: MKMapSize(width: width, height: height))
    }
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        contains(MKMapPoint(coordinate))
    }
}

let CLLocationCoordinate2DMax = CLLocationCoordinate2D(latitude: 90, longitude: 180)
let MKMapPointMax = MKMapPoint(CLLocationCoordinate2DMax)

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension Double {
    var zoomLevel: Double {
        let maxZoomLevel = log2(MKMapSize.world.width / 256) // 20
        let zoomLevel = floor(log2(self) + 0.5) // negative
        return max(0, maxZoomLevel + zoomLevel) // max - current
    }
}

private let radiusOfEarth: Double = 6372797.6

extension CLLocationCoordinate2D {
    func coordinate(onBearingInRadians bearing: Double, atDistanceInMeters distance: Double) -> CLLocationCoordinate2D {
        let distRadians = distance / radiusOfEarth // earth radius in meters
        
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        location.distance(from: coordinate.location)
    }
}

extension Array where Element: MKAnnotation {
    func subtracted(_ other: [Element]) -> [Element] {
        filter { item in !other.contains { $0.isEqual(item) } }
    }
    mutating func subtract(_ other: [Element]) {
        self = subtracted(other)
    }
    mutating func add(_ other: [Element]) {
        append(contentsOf: other)
    }
    @discardableResult
    mutating func remove(_ item: Element) -> Element? {
        firstIndex { $0.isEqual(item) }.map { remove(at: $0) }
    }
}

extension MKPolyline {
    convenience init(mapRect: MKMapRect) {
        let points = [
            MKMapPoint(x: mapRect.minX, y: mapRect.minY),
            MKMapPoint(x: mapRect.maxX, y: mapRect.minY),
            MKMapPoint(x: mapRect.maxX, y: mapRect.maxY),
            MKMapPoint(x: mapRect.minX, y: mapRect.maxY),
            MKMapPoint(x: mapRect.minX, y: mapRect.minY)
        ]
        self.init(points: points, count: points.count)
    }
}

extension OperationQueue {
    static var serial: OperationQueue {
        let queue = OperationQueue()
        queue.name = "com.cluster.serialQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    func addBlockOperation(_ block: @escaping (BlockOperation) -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak operation] in
            guard let operation = operation else { return }
            block(operation)
        }
        self.addOperation(operation)
    }
}

extension MKMapView {
    func fitAll(_ annotations: [MKAnnotation]) {
        var zoomRect = MKMapRect.null

        for annotation in annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(
                x: annotationPoint.x,
                y: annotationPoint.y,
                width: 0.01,
                height: 0.01
            )
            if zoomRect.isNull {
                zoomRect = pointRect
            } else {
                zoomRect = zoomRect.union(pointRect)
            }
        }

        setVisibleMapRect(
            zoomRect,
            edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            animated: true
        )
    }
}

