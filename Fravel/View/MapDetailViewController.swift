//
//  MapDetailViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/08/16.
//

import UIKit
import MapKit

class MapDetailViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var showLocationPicker: ShowPicker!
    @IBOutlet weak var leftLocationButton: UIButton!
    @IBOutlet weak var rightLocationButton: UIButton!
    let locationPicker = UIPickerView()
    let toolBar = UIToolbar(
        frame: CGRect(x: 0, y: 0, width: 100, height: 44)
    )
    
    var locations = [LocationInfo]()
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMapView()
        configureLocationPicker()
    }
    
    private func configureLocationPicker() {
        locationPicker.delegate = self
        locationPicker.dataSource = self
        
        showLocationPicker.inputView = locationPicker
        showLocationPicker.tintColor = .clear
        
        let selectButton = UIBarButtonItem(
            title: "확인",
            style: .plain,
            target: self,
            action: #selector(tapSelectButton(_:))
        )
        toolBar.setItems([selectButton], animated: true)
        toolBar.isUserInteractionEnabled = true
        
        showLocationPicker.inputAccessoryView = toolBar
        
        guard let firstLocation = locations.first
        else {
            return
        }
        
        showLocationPicker.text = makeLocationName(0, firstLocation.createdAt)
    }
    
    private func configureMapView() {
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsScale = true
        
        locations.forEach {
            let annotation = FootPrintsAnnotation(
                coordinate: $0.location.coordinate
            )
            
            mapView.addAnnotation(annotation)
        }
        
        moveToSelectedLocation()
    }

    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy.MM.dd HH시 mm분"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
    
    private func makeLocationName(_ row: Int, _ date: Date) -> String {
        return "\(row + 1). \(dateToString(date: date))"
    }
    
    private func moveToSelectedLocation() {
        if selectedIndex == 0 {
            leftLocationButton.isEnabled = false
            rightLocationButton.isEnabled = true
        } else if selectedIndex == locations.count - 1 {
            leftLocationButton.isEnabled = true
            rightLocationButton.isEnabled = false
        } else {
            leftLocationButton.isEnabled = true
            rightLocationButton.isEnabled = true
        }
        
        let coordinate = locations[selectedIndex].location.coordinate
        
        mapView.setRegion(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.001,
                    longitudeDelta: 0.001
                )
            ),
            animated: true
        )
    }
    
    @IBAction func tapCloseButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func tapLeftLocationButton(_ sender: UIButton) {
        selectedIndex -= 1
        moveToSelectedLocation()
        showLocationPicker.text = makeLocationName(selectedIndex, locations[selectedIndex].createdAt)
        
    }
    
    @IBAction func tapRightLocationButton(_ sender: UIButton) {
        selectedIndex += 1
        moveToSelectedLocation()
        showLocationPicker.text = makeLocationName(selectedIndex, locations[selectedIndex].createdAt)
    }
    
    @objc private func tapSelectButton(_ uiBarButtonItem: UIBarButtonItem) {
        showLocationPicker.resignFirstResponder()
    }
}


extension MapDetailViewController: MKMapViewDelegate {
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


extension MapDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return locations.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return makeLocationName(row, locations[row].createdAt)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
        showLocationPicker.text = makeLocationName(
            row,
            locations[row].createdAt
        )
        moveToSelectedLocation()
    }
}
