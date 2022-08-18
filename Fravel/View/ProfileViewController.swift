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
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let storage = Storage.storage()
    let db = Firestore.firestore()
    
    var idEditing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUser()
        configureScrollView()
        configureTextField()
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
            
            guard let displayname = data["displayname"] as? String,
                  let image = data["image"] as? String
            else {
                print("ERROR: Invalid User Info")
                return
            }
            
            self.displayNameField.text = displayname
            
            let imageRef = self.storage.reference(forURL: image)
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("ERROR: \(String(describing: error.localizedDescription))")
                    return
                }
                guard let url = url else {
                    return
                }
                                
                DispatchQueue.main.async {
                    self.profileImageView.kf.setImage(with: url)
                    
                    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.width / 2.0
                    self.profileImageView.layer.masksToBounds = true
                    self.profileImageView.contentMode = .scaleAspectFill
                }
            }
        }
    }
    
    private func configureTextField() {
        displayNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged
        )
    }
    
    private func configureScrollView() {
        self.scrollView.delegate = self
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        editUserInfoButton.isEnabled = !(displayNameField.text?.isEmpty ?? true)
    }
    
    @IBAction func tapEditButton(_ sender: UIButton) {
    }
    
    @IBAction func tapProfileImageEditButton(_ sender: UIButton) {
    }
}

extension ProfileViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}
