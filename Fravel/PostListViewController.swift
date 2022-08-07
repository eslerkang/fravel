//
//  PostListViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/29.
//

import UIKit
import FirebaseFirestore


class PostListViewController: UITableViewController {
    var postType: PostType?
    var cellIdentifier: String?
    var posts = [Post]()
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        
        getPosts()
    }
    
    private func configureTableView() {
        guard let postType = postType else {
            return
        }
        
        switch postType.name {
        case "공지사항":
            cellIdentifier = "NoticeTableViewCell"
            tableView.register(UINib(nibName: cellIdentifier!, bundle: nil), forCellReuseIdentifier: cellIdentifier!)
        default:
            cellIdentifier = "DefaultTableViewCell"
            tableView.register(UINib(nibName: cellIdentifier!, bundle: nil), forCellReuseIdentifier: cellIdentifier!)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.title = postType.name
    }
    
    private func getPosts() {
        guard let postType = postType else {
            return
        }
        
        let postTypeId = postType.id

        db.collection("posts")
            .whereField("type", isEqualTo: db.document("/types/\(postTypeId)"))
            .order(by: "createdAt", descending: true)
            .addSnapshotListener
        { [weak self] querySnapshot, error in
            guard let self = self else {return}
            
            if error != nil {
                print("ERROR: \(String(describing: error))")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("ERROR FireStore fetching document \(String(describing: error))")
                return
            }
            
            self.posts = documents.compactMap { doc -> Post? in
                let data = doc.data()
                let type = postTypeId
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
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}


extension PostListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let postType = postType,
              let cellIdentifier = cellIdentifier
        else {
            return UITableViewCell()
        }
        
        switch postType.name {
        case "공지사항":
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? NoticeTableViewCell else {return UITableViewCell()}
            cell.configurePost(post: posts[indexPath.row])
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? DefaultTableViewCell else {return UITableViewCell()}
            cell.configurePost(post: posts[indexPath.row])
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
