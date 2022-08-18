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
    @IBOutlet weak var editUserInfoButtonItem: UIBarButtonItem!
    @IBOutlet weak var editUserInfoButton: UIButton!
    @IBOutlet weak var cancelEditUserInfoButtonItem: UIBarButtonItem!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileImageContainer: UIView!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var postTableView: UITableView!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var likeTableView: UITableView!
    @IBOutlet weak var wrotePostStackView: UIStackView!
    
    let storage = Storage.storage()
    let db = Firestore.firestore()

    let defaultCellId = "DefaultTableViewCell"
    
    var hiddenSections = Set<Int>()
    var idEditing = false
    var posts = [[Post]]()
    var postTypes = [PostType]()
    var currentDisplayName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUser()
        getWrotePosts()
        
        configureScrollView()
        configureTextField()
        configureTableView()
        configureNavigationItems()
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
            self.currentDisplayName = displayname
            
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
                    
                    self.editUserInfoButtonItem.isEnabled = true
                    
                    self.getWrotePosts()
                }
            }
        }
        
 
    }
    
    private func getWrotePosts() {
        guard let userId = Auth.auth().currentUser?.uid,
              let displayname = currentDisplayName
        else {
            return
            
        }
        db.collection("types").whereField("editable", isEqualTo: true).order(by: "order").addSnapshotListener { querySnapshot, error in
            if error != nil {
                print("ERROR: \(String(describing: error))")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("ERROR FireStore fetching document \(String(describing: error))")
                return
            }
                        
            self.postTypes = documents.compactMap { doc -> PostType? in
                let data = doc.data()
                let typeId = doc.documentID
                guard let name = data["name"] as? String else {return nil}
                return PostType(id: typeId, name: name)
            }
                        
            for (index, postType) in self.postTypes.enumerated() {
                self.posts.append([])
                
                let typeId = postType.id
                
                self.db.collection("posts")
                    .whereField(
                        "type",
                        isEqualTo: self.db.document("/types/\(typeId)"))
                    .whereField(
                        "userId",
                        isEqualTo: userId
                    )
                    .order(
                        by: "createdAt",
                        descending: true
                    )
                    .addSnapshotListener { querySnapshot, error in
                        self.posts[index] = []
                        if error != nil {
                            print("ERROR: \(String(describing: error))")
                            return
                        }
                        
                        guard let documents = querySnapshot?.documents else {
                            print("ERROR FireStore fetching document \(String(describing: error))")
                            return
                        }
                                                
                        documents.forEach { doc in
                            let data = doc.data()
                            let type = typeId
                            let id = doc.documentID
                            
                            guard
                                let title = data["title"] as? String,
                                let content = data["content"] as? String,
                                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                            else {
                                print("ERROR: Invalid Post")
                                return
                            }
                            
                            let images = data["images"] as? [String]
                            let map = data["map"] as? DocumentReference
                            
                            let post = Post(
                                id: id,
                                title: title,
                                content: content,
                                userId: userId,
                                type: type,
                                createdAt: createdAt,
                                userDisplayName: displayname,
                                images: images,
                                map: map
                            )
                            
                            self.posts[index].append(post)
                            
                            DispatchQueue.main.async {
                                self.postTableView.reloadData()
                                self.wrotePostStackView.isHidden = false
                            }
                        }
                    }
            }
        }
    }
    
    private func configureTableView() {
        postTableView.delegate = self
        postTableView.dataSource = self
        postTableView.register(UINib(nibName: defaultCellId, bundle: nil), forCellReuseIdentifier: defaultCellId)

        commentTableView.delegate = self
        commentTableView.dataSource = self
        
        likeTableView.delegate = self
        likeTableView.dataSource = self
    }
    
    private func configureTextField() {
        displayNameField.isEnabled = false
    }
    
    private func configureScrollView() {
        self.scrollView.delegate = self
    }
    
    private func configureNavigationItems() {
        editUserInfoButtonItem.isEnabled = false
        cancelEditUserInfoButtonItem.customView?.isHidden = true
    }
    
    private func setNavigationButtonAsDoneButton() {
        editUserInfoButton.setTitle("저장", for: .normal)
        editUserInfoButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        editUserInfoButtonItem.isEnabled = false
    }
    
    private func setNavigationButtonAsEditButton() {
        editUserInfoButton.setTitle("수정", for: .normal)
        editUserInfoButton.setImage(UIImage(systemName: "person"), for: .normal)
        editUserInfoButtonItem.isEnabled = true
    }
    
    @IBAction func tapEditButton(_ sender: UIButton) {
        self.view.endEditing(true)
        if isEditing {
            guard let userId = Auth.auth().currentUser?.uid,
                  let displayname = displayNameField.text
            else {
                return
            }
            setNavigationButtonAsEditButton()
            cancelEditUserInfoButtonItem.customView?.isHidden = true
            displayNameField.isEnabled = false
            
            db.collection("users").document(userId).updateData([
                "displayname": displayname
            ])
            currentDisplayName = displayname
            
            posts = posts.map { postArray -> [Post] in
                return postArray.map { post -> Post in
                    var modifiedPost = post
                    modifiedPost.changeDisplayName(displayname: displayname)
                    return modifiedPost
                }
            }

            self.postTableView.reloadData()
            
        } else {
            setNavigationButtonAsDoneButton()
            cancelEditUserInfoButtonItem.customView?.isHidden = false
            displayNameField.isEnabled = true
        }
        
        isEditing = !isEditing
    }

    @IBAction func tapCancelButton(_ sender: UIButton) {
        self.view.endEditing(true)
        isEditing = false
        setNavigationButtonAsEditButton()
        cancelEditUserInfoButtonItem.customView?.isHidden = true
        displayNameField.isEnabled = false
        displayNameField.text = currentDisplayName!
    }
    
    @IBAction func endEditingTextField(_ sender: UITextField) {
        self.view.endEditing(true)
    }
    
    @IBAction func changedTextField(_ sender: UITextField) {
        editUserInfoButtonItem.isEnabled = !(displayNameField.text?.isEmpty ?? true)
    }
    
    @objc
    private func hideSection(sender: UIButton) {
        let section = sender.tag
        
        func indexPathForSection() -> [IndexPath] {
            var indexPaths = [IndexPath]()
            
            for row in 0..<self.posts[section].count {
                indexPaths.append(IndexPath(row: row, section: section))
            }
            
            return indexPaths
        }
        
        if self.hiddenSections.contains(section) {
            self.hiddenSections.remove(section)
            self.postTableView.insertRows(at: indexPathForSection(), with: .fade)
        } else {
            self.hiddenSections.insert(section)
            self.postTableView.deleteRows(at: indexPathForSection(), with: .fade)
        }
    }
    
    @objc
    private func moveToSectionBoard(sender: UIButton) {
        guard let postListViewController = self.storyboard?.instantiateViewController(withIdentifier: "PostListViewController") as? PostListViewController else {
            return
        }
        let postType = self.postTypes[sender.tag] as PostType
        postListViewController.postType = postType
        self.show(postListViewController, sender: nil)
    }
}

extension ProfileViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}


extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hiddenSections.contains(section) {
            return 0
        }
        return posts[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case postTableView:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellId) as? DefaultTableViewCell
            else {
                return UITableViewCell()
            }
            
            cell.configurePost(post: posts[indexPath.section][indexPath.row])
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.backgroundColor = .systemMint
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layer.cornerRadius = 15
        
        let sectionButton = UIButton()
        sectionButton.setTitle(String(postTypes[section].name), for: .normal)
        sectionButton.contentHorizontalAlignment = .left
        sectionButton.tag = section
        sectionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        sectionButton.addTarget(self, action: #selector(hideSection(sender:)), for: .touchUpInside)
        
        
        let moreButton = UIButton()
        moreButton.setTitle("더보기", for: .normal)
        moreButton.sizeToFit()
        moreButton.contentHorizontalAlignment = .right
        moreButton.tag = section
        moreButton.addTarget(self, action: #selector(moveToSectionBoard(sender:)), for: .touchUpInside)
        moreButton.titleLabel?.font = .systemFont(ofSize: 16)
        
        stackView.addArrangedSubview(sectionButton)
        stackView.addArrangedSubview(moreButton)
        
        return stackView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let postType = postTypes[indexPath.section]
        let post = posts[indexPath.section][indexPath.row]
        guard let postDetailViewController = storyboard?.instantiateViewController(withIdentifier: "PostDetailViewController") as? PostDetailViewController else {return}
        postDetailViewController.post = post
        postDetailViewController.postType = postType
        show(postDetailViewController, sender: nil)
    }
}
