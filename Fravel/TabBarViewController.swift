//
//  TabBarViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/30.
//

import UIKit

class TabBarViewController: UITabBarController {

    var preSelectedIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
}

extension TabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let currentIndex = tabBarController.selectedIndex
        if currentIndex == preSelectedIndex {
            
        }
        preSelectedIndex = currentIndex
    }
}
