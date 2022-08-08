//
//  MainViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/06/29.
//

import UIKit
import FirebaseFirestore

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var hiddenSections = Set<Int>()
    var tableViewData = [[Post]]()
    
    let noticeCellId = "NoticeTableViewCell"
    let defaultCellId = "DefaultTableViewCell"
        
    let db = Firestore.firestore()
    
    var postTypes = [PostType]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        db.collection("types").order(by: "order").addSnapshotListener { querySnapshot, error in
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
                let id = doc.documentID
                guard let name = data["name"] as? String else {return nil}
                return PostType(id: id, name: name)
            }
            
            self.tableViewData = []
            
            for (index, postType) in self.postTypes.enumerated() {
                self.tableViewData.append([])
                
                let id = postType.id
                
                self.db.collection("posts").whereField("type", isEqualTo: self.db.document("/types/\(id)")).order(by: "createdAt", descending: true).limit(to: 5).addSnapshotListener { querySnapshot, error in
                    if error != nil {
                        print("ERROR: \(String(describing: error))")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("ERROR FireStore fetching document \(String(describing: error))")
                        return
                    }
                    
                    let posts = documents.compactMap { doc -> Post? in
                        let data = doc.data()
                        let type = id
                        let id = doc.documentID
                        
                        guard
                            let title = data["title"] as? String,
                            let content = data["content"] as? String,
                            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                        else {
                            print("ERROR: Invalid Post")
                            return nil
                        }
                        
                        let userId = data["userId"] as? String

                        return Post(id: id, title: title, content: content, userId: userId, type: type, createdAt: createdAt)
                    }
                    
                    self.tableViewData[index] = posts
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        setupTableView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: noticeCellId, bundle: nil), forCellReuseIdentifier: noticeCellId)
        tableView.register(UINib(nibName: defaultCellId, bundle: nil), forCellReuseIdentifier: defaultCellId)
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.postTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = self.tableViewData[indexPath.section][indexPath.row]
        switch self.postTypes[indexPath.section].id {
        case "notice":
            guard let cell = tableView.dequeueReusableCell(withIdentifier: noticeCellId, for: indexPath) as? NoticeTableViewCell else {return UITableViewCell()}
            cell.configurePost(post: post)
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellId, for: indexPath) as? DefaultTableViewCell else {return UITableViewCell()}
            cell.configurePost(post: post)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hiddenSections.contains(section) {
            return 0
        }
        return self.tableViewData[section].count
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
        let post = tableViewData[indexPath.section][indexPath.row]
        guard let postDetailViewController = storyboard?.instantiateViewController(withIdentifier: "PostDetailViewController") as? PostDetailViewController else {return}
        postDetailViewController.post = post
        postDetailViewController.postType = postType
        show(postDetailViewController, sender: nil)
    }
    
    @objc
    private func hideSection(sender: UIButton) {
        let section = sender.tag
        
        func indexPathForSection() -> [IndexPath] {
            var indexPaths = [IndexPath]()
            
            for row in 0..<self.tableViewData[section].count {
                indexPaths.append(IndexPath(row: row, section: section))
            }
            
            return indexPaths
        }
        
        if self.hiddenSections.contains(section) {
            self.hiddenSections.remove(section)
            self.tableView.insertRows(at: indexPathForSection(), with: .fade)
        } else {
            self.hiddenSections.insert(section)
            self.tableView.deleteRows(at: indexPathForSection(), with: .fade)
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
