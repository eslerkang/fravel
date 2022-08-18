//
//  WritePostViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/08/09.
//

import UIKit
import FirebaseFirestore
import PhotosUI
import FirebaseStorage
import FirebaseAuth


class WritePostViewController: UIViewController {
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var showTypePicker: ShowPicker!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var myFootPrintStackView: UIStackView!
    @IBOutlet weak var showMyFootPrintPicker: ShowPicker!
    let typePicker = UIPickerView()
    let myFootPrintPicker = UIPickerView()
    let toolBar = UIToolbar(
        frame: CGRect(x: 0, y: 0, width: 100, height: 44)
    )
    var imagePicker: PHPickerViewController?
    
    var postTypes = [PostType]()
    var maps = [Map]()
    var selectedPostType: PostType?
    var selectedMap: Map?
    var uploadedImages = [UIImage]()
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.topItem?.title = ""
        
        configureScrollView()
        configureTypePicker()
        configureContentTextView()
        configurePHPickerController()
        configureImageCollectionView()
        configureMyFootPrintPicker()
        configureTextFields()
        
        getPostTypes()
        getMaps()
    }
    
    private func getMaps() {
        guard let userId = Auth.auth().currentUser?.uid else {return}
        self.showMyFootPrintPicker.isEnabled = false
        db
            .collection("maps")
            .order(
                by: "updatedAt",
                descending: true
            )
            .whereField(
                "userId",
                isEqualTo: userId
            )
            .whereField(
                "status",
                isEqualTo: "done"
            )
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else {return}
                
                if error != nil {
                    print("ERROR: \(String(describing: error))")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ERROR FireStore fetching document \(String(describing: error))")
                    return
                }
                
                self.maps = documents.compactMap { doc -> Map? in
                    let data = doc.data()
                    let id = doc.documentID
                    guard let name = data["name"] as? String else {return nil}
                    return Map(id: id, name: name, locations: nil)
                }
                
                DispatchQueue.main.async {
                    self.myFootPrintPicker.reloadAllComponents()
                    self.showMyFootPrintPicker.isEnabled = true
                    self.showMyFootPrintPicker.text = self.maps.first?.name
                    self.selectedMap = self.maps.first
                }
            }
    }
    
    private func getPostTypes() {
        self.showTypePicker.isEnabled = false
        db
            .collection("types")
            .order(by: "order")
            .whereField(
                "editable",
                isEqualTo: true
            )
            .addSnapshotListener {[weak self] snapshot, error in
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
                    self.showTypePicker.text = self.postTypes.first?.name
                    self.selectedPostType = self.postTypes.first
                }
            }
    }
    
    private func configureScrollView() {
        scrollView.delegate = self
    }
    
    private func configureTextFields() {
        self.titleField.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
    }
    
    private func configureImageCollectionView() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
    }
    
    private func configurePHPickerController() {
        var imagePickerConfig = PHPickerConfiguration()
        imagePickerConfig.filter = .any(of: [.images])
        imagePickerConfig.selectionLimit = 3
        
        imagePicker = PHPickerViewController(configuration: imagePickerConfig)
        imagePicker?.delegate = self
    }
    
    private func configureTypePicker() {
        typePicker.delegate = self
        typePicker.dataSource = self
        
        showTypePicker.inputView = typePicker
        showTypePicker.tintColor = .clear
        
        let typeSelectButton = UIBarButtonItem(title: "확인", style: .plain, target: self, action: #selector(tapTypeSelectButton(_:)))
        toolBar.setItems([typeSelectButton], animated: true)
        toolBar.isUserInteractionEnabled = true
        
        showTypePicker.inputAccessoryView = toolBar
    }
    
    private func configureMyFootPrintPicker() {
        myFootPrintPicker.delegate = self
        myFootPrintPicker.dataSource = self
        
        showMyFootPrintPicker.inputView = myFootPrintPicker
        showMyFootPrintPicker.tintColor = .clear
                
        showMyFootPrintPicker.inputAccessoryView = toolBar
        
        self.myFootPrintStackView.isHidden = true
    }
    
    private func configureContentTextView() {
        self.contentTextView.delegate = self
        self.contentTextView.layer.borderWidth = 0.5
        self.contentTextView.layer.borderColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0).cgColor
        self.contentTextView.layer.cornerRadius = 5
    }
    
    @IBAction func tapPostButton(_ sender: UIButton) {
        let loadingViewController = LoadingViewController()
        loadingViewController.modalPresentationStyle = .overCurrentContext
        loadingViewController.modalTransitionStyle = .crossDissolve
        present(loadingViewController, animated: true)
        guard let title = titleField.text,
              let content = contentTextView.text,
              let userId = Auth.auth().currentUser?.uid,
              let type = selectedPostType?.id
        else {
            return
        }
        let typeRef = self.db.collection("types").document(type)
        var uploadedImageRefs = [String]()
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        if !uploadedImages.isEmpty {
            uploadedImages.forEach {
                let imageName = "\(UUID().uuidString).png"
                let ref = storage.reference().child("images").child(userId).child(imageName)
                guard let uploadData = $0.jpegData(compressionQuality: 0.5) else { return }
                let uploadTask = ref.putData(uploadData, metadata: metadata)
                uploadTask.observe(.success) { snapshot in
                    uploadedImageRefs.append("gs://\(ref.bucket)/\(ref.fullPath)")
                    if uploadedImageRefs.count == self.uploadedImages.count {
                        if type == "everyonesFoot" {
                            guard let map = self.selectedMap?.id else {return}
                            let mapRef = self.db.collection("maps").document(map)
                            self.db.collection("posts").addDocument(data: [
                                "title": title,
                                "content": content,
                                "userId": userId,
                                "images": uploadedImageRefs,
                                "type": typeRef,
                                "createdAt": Date(),
                                "map": mapRef
                            ])
                        } else {
                            self.db.collection("posts").addDocument(data: [
                                "title": title,
                                "content": content,
                                "userId": userId,
                                "images": uploadedImageRefs,
                                "type": typeRef,
                                "createdAt": Date()
                            ])
                        }
                        DispatchQueue.main.async {
                            loadingViewController.dismiss(animated: true) {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            }
        } else {
            if type == "everyonesFoot" {
                guard let map = self.selectedMap?.id else {return}
                let mapRef = self.db.collection("maps").document(map)
                self.db.collection("posts").addDocument(data: [
                    "title": title,
                    "content": content,
                    "userId": userId,
                    "type": typeRef,
                    "createdAt": Date(),
                    "map": mapRef
                ])
            } else {
                self.db.collection("posts").addDocument(data: [
                    "title": title,
                    "content": content,
                    "userId": userId,
                    "type": typeRef,
                    "createdAt": Date()
                ])
            }
            loadingViewController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
    @objc private func validateInputFields() {
        self.postButton.isEnabled = !(self.titleField.text?.isEmpty ?? true) && !self.contentTextView.text.isEmpty && !(self.showTypePicker.text?.isEmpty ?? true) && ((!myFootPrintStackView.isHidden && !(showMyFootPrintPicker.text?.isEmpty ?? true)) || myFootPrintStackView.isHidden)
    }
    
    @IBAction func tapImageUploadButton(_ sender: Any) {
        self.present(imagePicker!, animated: true)
    }
    
    @objc private func textFieldDidChanged(_ textField: UITextField) {
        self.validateInputFields()
    }
    
    @objc private func tapTypeSelectButton(_ uiBarButtonItem: UIBarButtonItem) {
        showTypePicker.resignFirstResponder()
        showMyFootPrintPicker.resignFirstResponder()
        self.validateInputFields()
    }
}


extension WritePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.validateInputFields()
    }
}

extension WritePostViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case typePicker:
            return postTypes.count
        case myFootPrintPicker:
            return maps.count
        default:
            return 0
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case typePicker:
            return postTypes[row].name
        case myFootPrintPicker:
            return maps[row].name
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case typePicker:
            selectedPostType = postTypes[row]
            showTypePicker.text = postTypes[row].name
            self.myFootPrintStackView.isHidden = selectedPostType?.id != "everyonesFoot"
        case myFootPrintPicker:
            selectedMap = maps[row]
            showMyFootPrintPicker.text = maps[row].name
        default:
            return
        }
    }
}


extension WritePostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        self.uploadedImages = []
        
        picker.dismiss(animated: true)
        
        results.forEach {
            let itemProvider = $0.itemProvider
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("ERROR: \(String(describing: error.localizedDescription))")
                        return
                    }
                    
                    guard let image = image as? UIImage else {
                        return
                    }
                    
                    self.uploadedImages.append(image)
                    DispatchQueue.main.async {
                        self.imageCollectionView.reloadData()
                    }
                }
            }
        }
    }
}


extension WritePostViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uploadedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageView.image = uploadedImages[indexPath.row]
        cell.imageView.contentMode = .scaleAspectFit
        cell.layer.borderWidth = 2
        cell.layer.borderColor = UIColor.lightGray.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageDetailViewController = storyboard?.instantiateViewController(withIdentifier: "ImageDetailViewController") as! ImageDetailViewController
        
        imageDetailViewController.image = uploadedImages[indexPath.row]
        self.present(imageDetailViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 200)
    }
}


extension WritePostViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
        self.validateInputFields()
    }
}
