//
//  AnnotationView.swift
//  Cluster
//

import UIKit
import MapKit

final class CountClusterAnnotationView: ClusterAnnotationView {
    override func configure() {
        super.configure()

        guard let annotation = annotation as? ClusterAnnotation else { return }
        let count = annotation.annotations.count
        let diameter = radius(for: count) * 2
        frame.size = CGSize(width: diameter, height: diameter)
        layer.cornerRadius = frame.width / 2
        layer.masksToBounds = true
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.5
    }

    func radius(for count: Int) -> CGFloat {
        if count < 5 {
            return 12
        } else if count < 10 {
            return 16
        } else {
            return 20
        }
    }
}

final class ImageCountClusterAnnotationView: ClusterAnnotationView {
    lazy var once: Void = { [unowned self] in
        self.countLabel.frame.size.width -= 6
        self.countLabel.frame.origin.x += 3
        self.countLabel.frame.origin.y -= 6
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        _ = once
    }
}
