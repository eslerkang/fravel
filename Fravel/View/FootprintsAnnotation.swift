//
//  FootprintsAnnotation.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/09.
//

import UIKit
import MapKit

final class FootPrintsAnnotationView: MKAnnotationView {
    static let identifier = "FootPrintsAnnotation"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?){
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 50)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
    }
}

final class FootPrintsAnnotation: NSObject, MKAnnotation {
  let coordinate: CLLocationCoordinate2D

  init(
    coordinate: CLLocationCoordinate2D
  ) {
    self.coordinate = coordinate

    super.init()
  }
}



final class FootPrintsClusterAnnotationView: MKAnnotationView {
    static let identifier = "FootPrintsClusterAnnotationView"

    
    override var annotation: MKAnnotation? {
        didSet {
            guard annotation is MKClusterAnnotation else {return}
            displayPriority = .defaultHigh
        }
    }
}
