//
//  ProfileViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let user = Auth.auth().currentUser else {return}
        let name = user.displayName ?? user.email ??  "사용자"
        nameLabel.text = name
    }
    
    @IBAction func tapLogoutButton(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("ERROR: \(signOutError.debugDescription)")
        }
        
        dismiss(animated: true)
    }
}
