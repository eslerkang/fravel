//
//  LoginViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var googleLoginButton: UIButton!
    @IBOutlet weak var appleLoginButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureButtons() {
        let buttons = [googleLoginButton, appleLoginButton]
        buttons.forEach {
            $0?.layer.borderColor = UIColor.black.cgColor
            $0?.layer.borderWidth = 3
            $0?.layer.cornerRadius = 10
        }
    }
    
    @IBAction func tapGoogleLoginButton(_ sender: UIButton) {
        guard let tabBarController = storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? TabBarViewController else {return}
        tabBarController.modalPresentationStyle = .fullScreen
        self.present(tabBarController, animated: true)
    }
    
    @IBAction func tapAppleLoginButton(_ sender: UIButton) {
    }
}

