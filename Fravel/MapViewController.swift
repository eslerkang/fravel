//
//  MapViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit

class MapViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.delegate = self
    }
}

extension MapViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController == self {
            // my location
        }
    }
}
