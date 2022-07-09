//
//  MapViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit
import MapKit


class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noInternetLabel: UILabel!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        configureLocationManager()
        configureMapView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(isInternetConnectedNotification(_:)), name: NSNotification.Name("isInternetConnected"), object: nil)
    }
    
    @objc
    func isInternetConnectedNotification(_ notification: NSNotification) {
        guard let isInternetConnected = notification.object as? Bool else {return}
        
        DispatchQueue.main.async {
            self.noInternetLabel.isHidden = isInternetConnected
        }
    }
    
    func configureMapView() {
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        showCurrentLocation()
    }
    
    func getLocationUsagePermission() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func configureLocationManager() {
        self.locationManager.delegate = self

        getLocationUsagePermission()
        
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.distanceFilter = 10
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        self.locationManager.startUpdatingLocation()
    }
    
    func showCurrentLocation() {
        guard let location = locationManager.location else {
            getLocationUsagePermission()
            return
        }
        let center = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        mapView.setRegion(
            MKCoordinateRegion(
                center: center,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ),
            animated: true
        )
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
}


extension MapViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController == self {
            showCurrentLocation()
        }
    }
}


extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted, .notDetermined:
            getLocationUsagePermission()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {return}
        setAnnotation(lastLocation)
    }
    
    func setAnnotation(_ location: CLLocation) {
        let annotation = FootPrintsAnnotation(coordinate: location.coordinate)
        mapView.addAnnotation(annotation)
    }
}


extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? FootPrintsAnnotation {
            let annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: FootPrintsAnnotationView.identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: FootPrintsAnnotationView.identifier)
                        
            annotationView.annotation = annotation
            
            let footPrintsImage: UIImage!
            
            footPrintsImage = UIImage(named: "footprints")
            
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 15, height: 15)).image(actions: {_ in
                footPrintsImage.draw(in: CGRect(x: 0, y: 0, width: 15, height: 15))
            })
            annotationView.image = resizedImage
            annotationView.clusteringIdentifier = FootPrintsClusterAnnotationView.identifier
            
            return annotationView
        } else if let cluster = annotation as? MKClusterAnnotation {
            let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: FootPrintsClusterAnnotationView.identifier) ?? MKAnnotationView(annotation: cluster, reuseIdentifier: FootPrintsClusterAnnotationView.identifier)
            
            clusterView.annotation = cluster
            
            let footPrintsImage: UIImage!
            
            footPrintsImage = UIImage(named: "footprints")
            
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 15, height: 15)).image(actions: {_ in
                footPrintsImage.draw(in: CGRect(x: 0, y: 0, width: 15, height: 15))
            })
            clusterView.image = resizedImage
            
            return clusterView
        } else {
            return nil
        }
    }
}
