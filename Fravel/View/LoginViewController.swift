//
//  LoginViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit
import CryptoKit
import AuthenticationServices

import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore


class LoginViewController: UIViewController {
    @IBOutlet weak var googleLoginButton: GIDSignInButton!
    @IBOutlet weak var appleLoginButton: UIButton!
    private lazy var sexSelectAlertController: UIAlertController = {
        let alertController = UIAlertController(title: "성별 선택", message: "당신과 함꼐할 아바타의 성별을 선택하세요!", preferredStyle: .actionSheet)
        
        guard let user = Auth.auth().currentUser,
              let tabBarController = storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? TabBarViewController
        else {
            return alertController
        }
        let displayname = user.displayName ?? user.email ?? "사용자"
        tabBarController.modalPresentationStyle = .fullScreen
        
        let male = UIAlertAction(title: "남성", style: .default, handler: { _ in
            self.db.collection("users").document(user.uid).setData([
                "displayname": displayname,
                "isMale": true,
                "image": self.maleDefaultAvatar
            ]) { error in
                print("ERROR: \(String(describing: error?.localizedDescription))")
            }
            self.present(tabBarController, animated: true)
        })
        let female = UIAlertAction(title: "여성", style: .default, handler: { _ in
            self.db.collection("users").document(user.uid).setData([
                "displayname": displayname,
                "isMale": false,
                "image": self.femaleDefaultAvatar
            ]) { error in
                print("ERROR: \(String(describing: error?.localizedDescription))")
            }
            self.present(tabBarController, animated: true)
        })
        
        alertController.addAction(male)
        alertController.addAction(female)
        
        return alertController
    }()
    private let maleDefaultAvatar = "gs://fravel-1c38a.appspot.com/avatars/vadim-bogulov-qGDSeP0CGCk-unsplash.jpg"
    private let femaleDefaultAvatar = "gs://fravel-1c38a.appspot.com/avatars/vadim-bogulov-rdHrrFA1KKg-unsplash.jpg"

    fileprivate var currentNonce: String?
    
    let db = Firestore.firestore()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !NetworkCheck.shared.isNetworkConnected() {
            showMessagePrompt("인터넷 연결을 확인해주세요.", { _ in
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    exit(0)
                }
            })
        }
        
        if let _ = Auth.auth().currentUser {
            self.moveToTabBarController()
        }
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
        guard let clientID = FirebaseApp.app()?.options.clientID else {return}
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            guard let self = self else {return}
            if let error = error {
                self.showMessagePrompt("ERROR: \(error.localizedDescription)", nil)
                return
            }
            
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else {return}
                if let error = error {
                    self.showMessagePrompt("ERROR: \(error.localizedDescription)", nil)
                    return
                }
                self.moveToTabBarController()
            }
        }
    }
    
    @IBAction func tapAppleLoginButton(_ sender: UIButton) {
        startSignInWithAppleFlow()
    }
    
    func showMessagePrompt(_ message: String, _ handler: ((UIAlertAction) -> Void)?) {
      let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      let okAction = UIAlertAction(title: "OK", style: .default, handler: handler)
      alert.addAction(okAction)
      present(alert, animated: false, completion: nil)
    }
    
    func moveToTabBarController() {
        guard let user = Auth.auth().currentUser else {return}
        db.collection("users").document(user.uid).getDocument {[weak self] document, error in
            guard let self = self else {return}
            if let error = error {
                print("ERROR: \(String(describing: error.localizedDescription))")
                return
            }
            if document?.data() == nil {
                self.present(self.sexSelectAlertController, animated: true)
            } else {
                DispatchQueue.main.async {
                    guard let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? TabBarViewController else {return}
                    tabBarController.modalPresentationStyle = .fullScreen
                    self.present(tabBarController, animated: true)
                }
            }
        }

    }
}


// Apple Login
extension LoginViewController {
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
          String(format: "%02x", $0)
      }.joined()
        return hashString
    }
    
    @available(iOS 13, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}


extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let self = self else {return}
                if let error = error {
                    self.showMessagePrompt("ERROR: \(error.localizedDescription)", nil)
                    return
                }
                self.moveToTabBarController()
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }
}


extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
