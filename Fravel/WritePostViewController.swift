//
//  WritePostViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/08/09.
//

import UIKit
import FirebaseFirestore
import PhotosUI


class WritePostViewController: UIViewController {
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var showTypePicker: ShowTypePicker!
    @IBOutlet weak var scrollView: UIScrollView!
    let typePicker = UIPickerView()
    var imagePicker: PHPickerViewController?
    
    var postTypes = [PostType]()
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.topItem?.title = ""
        
        configureScrollView()
        configureTypePicker()
        configureContentTextView()
        configurePHPickerController()
        
        getPostTypes()
    }
    
    private func getPostTypes() {
        self.showTypePicker.isEnabled = false
        db.collection("types").order(by: "order").whereField("editable", isEqualTo: true).addSnapshotListener {[weak self] snapshot, error in
            guard let self = self else {return}
            
            if error != nil {
                print("ERROR: \(String(describing: error))")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("ERROR FireStore fetching document \(String(describing: error))")
                return
            }
                        
            self.postTypes = documents.compactMap { doc -> PostType? in
                let data = doc.data()
                let id = doc.documentID
                guard let name = data["name"] as? String else {return nil}
                return PostType(id: id, name: name)
            }
            
            DispatchQueue.main.async {
                self.typePicker.reloadAllComponents()
                self.showTypePicker.isEnabled = true
            }
        }
    }
    
    private func configurePHPickerController() {
        var imagePickerConfig = PHPickerConfiguration()
        imagePickerConfig.filter = .any(of: [.images, .livePhotos])
        imagePickerConfig.selectionLimit = 3
        
        imagePicker = PHPickerViewController(configuration: imagePickerConfig)
        imagePicker?.delegate = self
    }
    
    private func configureScrollView() {
        let touch = UITapGestureRecognizer(target: self, action: #selector(singleTapGestureCaptured(gesture:)))
        scrollView.addGestureRecognizer(touch)
    }
    
    private func configureTypePicker() {
        typePicker.delegate = self
        typePicker.dataSource = self
        
        showTypePicker.inputView = typePicker
        showTypePicker.tintColor = .clear
    }
    
    private func configureContentTextView() {
        self.contentTextView.delegate = self
        self.contentTextView.layer.borderWidth = 0.5
        self.contentTextView.layer.borderColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0).cgColor
        self.contentTextView.layer.cornerRadius = 5
    }
    
    @IBAction func tapPostButton(_ sender: UIBarButtonItem) {
        
    }
    
    private func validateInputFields() {
        self.postButton.isEnabled = !(self.titleField.text?.isEmpty ?? true) && !self.contentTextView.text.isEmpty
    }
    
    @objc func singleTapGestureCaptured(gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func tapImageUploadButton(_ sender: Any) {
        self.present(imagePicker!, animated: true)
    }
}


extension WritePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.validateInputFields()
    }
}

extension WritePostViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        postTypes.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return postTypes[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        showTypePicker.text = postTypes[row].name
    }
}


extension WritePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        imagePicker?.dismiss(animated: true)
        
        print(results)
    }
}
