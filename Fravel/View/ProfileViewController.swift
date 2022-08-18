//
//  ProfileViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher


class ProfileViewController: UIViewController {
    @IBOutlet weak var editUserInfoButton: UIBarButtonItem!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileImageContainer: UIView!
    
    var user: User?
    
    let storage = Storage.storage()
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUser()
    }
    
    private func getUser() {
        guard let userId = Auth.auth().currentUser?.uid else {return}
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("ERROR: \(String(describing: error.localizedDescription))")
                return
            }
            
            guard let document = snapshot,
                  let data = document.data()
            else {
                print("ERROR: fetching \(userId) user information")
                return
            }
            
            let userId = document.documentID
            guard let displayname = data["displayname"] as? String,
                  let image = data["image"] as? String
            else {
                print("ERROR: Invalid User Info")
                return
            }
            
            let imageRef = self.storage.reference(forURL: image)
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("ERROR: \(String(describing: error.localizedDescription))")
                    return
                }
                guard let url = url else {
                    return
                }
                
                self.user = User(id: userId, displayname: displayname, image: url)
                
                self.configureView()
            }
        }
    }
    
    private func configureView() {
        guard let user = user else {
            return
        }
        
        profileImageView.kf.setImage(with: user.image)
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2.0
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        profileImageContainer.isHidden = false
    }
}
