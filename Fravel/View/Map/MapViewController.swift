//
//  MapViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit
import MapKit
import FirebaseFirestore
import FirebaseAuth


enum RecordingStatus {
    case recording
    case paused
    case done
}


class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noInternetLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    let stopAlertView = UIAlertController(title: "여행 종료", message: "정말 나만의 발자국 기록을 종료하시겠습니까?\n종료 시 수정이 불가능합니다.", preferredStyle: .alert)
    let startAlertView = UIAlertController(title: "여행 시작", message: "이번 여행의 멋진 이름을 알려주세요!", preferredStyle: .alert)
    var mapNameTextField: UITextField?
    
    let locationManager = CLLocationManager()
    let db = Firestore.firestore()
    
    var mapRef: DocumentReference?
    
    var recordingStatus: RecordingStatus = .done
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        configureLocationManager()
        configureMapView()
        configureNotificationCenter()
        configureStopAlertView()
        configureStartAlertView()
        configureInitialButtons()
        
        getMap()
    }
    
    func getMap() {
        guard let userId = Auth.auth().currentUser?.uid else {return}
        let mapRef = db
            .collection("maps")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", in: ["paused", "recording"])
            .limit(to: 1)
        mapRef.getDocuments {[weak self] snapshot, error in
            guard let self = self else {return}
            if let error = error {
                print("ERROR: \(String(describing: error.localizedDescription))")
                self.setButtons()
                return
            }
            guard let documents = snapshot?.documents
            else {
                print("ERROR: Fetching Map failed")
                self.setButtons()
                return
            }
            if documents.isEmpty {
                self.setButtons()
                return
            }
            let data = documents[0].data()
            self.mapRef = documents[0].reference
            
            guard let status = data["status"] as? String,
                  let rawLocations = data["locations"] as? [NSDictionary]
            else {
                return
            }
            
            let locations = rawLocations.compactMap { data -> LocationInfo? in
                guard let latitudeString = data["latitude"] as? String,
                      let longitudeString = data["longitude"] as? String,
                      let createAt = (data["createdAt"] as? Timestamp)?.dateValue(),
                      let latitude = Double(latitudeString),
                      let longitude = Double(longitudeString)
                else {
                    return nil
                }
                let location = CLLocation(latitude: latitude, longitude: longitude)
                return LocationInfo(latitude: latitudeString, longitude: longitudeString, createdAt: createAt, location: location)
            }
            
            locations.forEach { locationInfo in
                self.setAnnotation(locationInfo.location)
            }
            
            switch status {
            case "paused":
                self.recordingStatus = .paused
            case "recording":
                self.locationManager.startUpdatingLocation()
                self.recordingStatus = .recording
            case "done":
                self.recordingStatus = .done
            default:
                self.recordingStatus = .done
            }
            
            self.setButtons()
        }
    }
    
    func configureStopAlertView() {
        stopAlertView.addAction(UIAlertAction(title: "종료하기", style: .destructive, handler: { _ in
            guard let mapRef = self.mapRef else {
                return
            }
            
            self.recordingStatus = .done
            self.setButtons()
            self.locationManager.stopUpdatingLocation()
            self.mapView.removeAnnotations(self.mapView.annotations)
            mapRef.updateData([
                "status": "done",
                "updatedAt": FieldValue.serverTimestamp()
            ])
            self.mapRef = nil
        }))
        stopAlertView.addAction(UIAlertAction(title: "cancel", style: .cancel))
    }
    
    func configureStartAlertView() {
        startAlertView.addTextField(configurationHandler: { textField in
            self.mapNameTextField = textField
            textField.placeholder = "여행 이름을 입력하세요"
        })
        startAlertView.addAction(UIAlertAction(title: "시작하기", style: .default, handler: { _ in
            if self.mapNameTextField!.text!.isEmpty {
                self.present(self.startAlertView, animated: true)
            } else {
                let userId = Auth.auth().currentUser!.uid
                let mapRef = self.db.collection("maps").document()
                mapRef.setData([
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "userId": userId,
                    "status": "recording",
                    "locations": [],
                    "name": self.mapNameTextField!.text!
                ])
                self.mapRef = mapRef
                self.recordingStatus = .recording
                self.setButtons()
                self.locationManager.startUpdatingLocation()
            }
        }))
        startAlertView.addAction(UIAlertAction(title: "cancel", style: .cancel))
    }
    
    func configureNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(isInternetConnectedNotification(_:)),
            name: NSNotification.Name("isInternetConnected"),
            object: nil
        )
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
    }
    
    func configureInitialButtons() {
        [startButton, pauseButton, stopButton].forEach {
            $0?.isEnabled = false
        }
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
    
    @IBAction func tapStartButton(_ sender: UIButton) {
        if recordingStatus == .done {
            present(startAlertView, animated: true)
        } else {
            guard let mapRef = mapRef else {
                return
            }
            
            recordingStatus = .recording
            setButtons()
            self.locationManager.startUpdatingLocation()
            mapRef.updateData([
                "status": "recording",
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    @IBAction func tapPauseButton(_ sender: UIButton) {
        guard let mapRef = mapRef else {
            return
        }
        
        recordingStatus = .paused
        setButtons()
        self.locationManager.stopUpdatingLocation()
        
        mapRef.updateData([
            "status": "paused",
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    @IBAction func tapStopButton(_ sender: UIButton) {
        self.present(stopAlertView, animated: true)
    }
    
    private func setButtons() {
        switch recordingStatus {
        case .recording:
            self.startButton.isEnabled = false
            self.pauseButton.isEnabled = true
            self.stopButton.isEnabled = true
        case .paused:
            self.pauseButton.isEnabled = false
            self.startButton.isEnabled = true
            self.stopButton.isEnabled = true
        case .done:
            self.startButton.isEnabled = true
            self.pauseButton.isEnabled = false
            self.stopButton.isEnabled = false
        }
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
        guard let lastLocation = locations.last,
              let mapRef = self.mapRef
        else {
            return
        }
        
        mapRef.updateData([
            "locations": FieldValue.arrayUnion([
                [
                    "createdAt": Date(),
                    "latitude": "\(lastLocation.coordinate.latitude)",
                    "longitude": "\(lastLocation.coordinate.longitude)"
                ]
            ]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
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
