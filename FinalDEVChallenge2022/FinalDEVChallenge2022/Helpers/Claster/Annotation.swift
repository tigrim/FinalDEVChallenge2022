//
//  Annotation.swift
//  Cluster
//
//

import MapKit

class Annotation: MKPointAnnotation {
    var style: ClusterAnnotationStyle?
    var lightning: Lightning!
    
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init()
        self.coordinate = coordinate
    }

    convenience init(lightning: Lightning) {
        self.init()
        self.lightning = lightning
        self.coordinate = CLLocationCoordinate2D(latitude: lightning.lat, longitude: lightning.lon)
    }
}

final class ClusterAnnotation: Annotation {
    var annotations = [MKAnnotation]()
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ClusterAnnotation else { return false }
        
        if self === object {
            return true
        }
        
        if coordinate != object.coordinate {
            return false
        }
        
        if annotations.count != object.annotations.count {
            return false
        }
        
        return annotations.map { $0.coordinate } == object.annotations.map { $0.coordinate }
    }
}

/**
 The view associated with your cluster annotations.
 */
class ClusterAnnotationView: MKAnnotationView {
    lazy var countLabel: UILabel = {
        let label = UILabel()
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.backgroundColor = .clear
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        addSubview(label)
        return label
    }()
    
    override var annotation: MKAnnotation? {
        didSet {
            configure()
        }
    }
    
    func configure() {
        guard let annotation = annotation as? ClusterAnnotation else { return }
        let count = annotation.annotations.count
        countLabel.text = "\(count)"
    }
}

/**
 The style of the cluster annotation view.
 */
enum ClusterAnnotationStyle {
    /**
     Displays the annotations as a circle.
     
     - `color`: The color of the annotation circle
     - `radius`: The radius of the annotation circle
     */
    case color(UIColor, radius: CGFloat)
    
    /**
     Displays the annotation as an image.
     */
    case image(UIImage?)
}

/**
 A cluster annotation view that supports styles.
 */
final class StyledClusterAnnotationView: ClusterAnnotationView {
    
    /**
     The style of the cluster annotation view.
     */
    var style: ClusterAnnotationStyle
    
    /**
     Initializes and returns a new cluster annotation view.
     
     - Parameters:
     - annotation: The annotation object to associate with the new view.
     - reuseIdentifier: If you plan to reuse the annotation view for similar types of annotations, pass a string to identify it. Although you can pass nil if you do not intend to reuse the view, reusing annotation views is generally recommended.
     - style: The cluster annotation style to associate with the new view.
     
     - Returns: The initialized cluster annotation view.
     */
    init(annotation: MKAnnotation?, reuseIdentifier: String?, style: ClusterAnnotationStyle) {
        self.style = style
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure() {
        guard let annotation = annotation as? ClusterAnnotation else { return }
        
        switch style {
        case let .image(image):
            backgroundColor = .clear
            self.image = image
        case let .color(color, radius):
            let count = annotation.annotations.count
            backgroundColor = color
            var diameter = radius * 2
            switch count {
            case _ where count < 8:
                diameter *= 0.6
            case _ where count < 16:
                diameter *= 0.8
            default: break
            }
            frame = CGRect(origin: frame.origin, size: CGSize(width: diameter, height: diameter))
            countLabel.text = "\(count)"
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if case .color = style {
            layer.masksToBounds = true
            layer.cornerRadius = image == nil ? bounds.width / 2 : 0
            countLabel.frame = bounds
        }
    }
}
