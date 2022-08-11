//
//  PostDetailViewController.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/29.
//

import UIKit
import FirebaseFirestore
import Kingfisher
import MapKit
import FirebaseStorage
import FirebaseAuth


class PostDetailViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var modifyStackView: UIStackView!
    let deleteAlertView = UIAlertController(title: "게시글 삭제", message: "정말 이 게시글을 삭제하시겠습니까?", preferredStyle: .alert)
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var postType: PostType?
    var post: Post?
    
    var images = [ImageInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title = ""

        collectionView.dataSource = self
        collectionView.delegate = self
        
        configurePage()
        configureModifyStackView()
        configureDeleteAlertView()
        
        getImages()
    }
    
    private func configureDeleteAlertView() {
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "삭제하기", style: .default) { _ in
            let loadingViewController = LoadingViewController()
            loadingViewController.modalPresentationStyle = .overCurrentContext
            loadingViewController.modalTransitionStyle = .crossDissolve
            self.present(loadingViewController, animated: true)
            
            guard let postId = self.post?.id else {return}
            self.images.forEach {
                let ref = self.storage.reference(forURL: $0.ref)
                ref.delete() { error in
                    if let error = error {
                        print("ERROR: \(String(describing: error.localizedDescription))")
                        return
                    }
                }
            }
            self.db.collection("posts").document(postId).delete() { error in
                if let error = error {
                    print("ERROR: \(String(describing: error.localizedDescription))")
                    return
                }
            }
            loadingViewController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        deleteAlertView.addAction(cancelAction)
        deleteAlertView.addAction(deleteAction)
    }
    
    private func configureModifyStackView() {
        guard let postUserId = post?.userId,
              let currentUserId = Auth.auth().currentUser?.uid
        else {
            return
        }
        
        if postUserId == currentUserId {
            modifyStackView.isHidden = false
        }
    }
    
    func configurePage() {
        guard let post = post,
              let postType = postType
        else {
            return
        }

        let titleView = UILabel()
        titleView.numberOfLines = 0
        titleView.textAlignment = .natural
        titleView.text = post.title
        titleView.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        self.navigationItem.titleView = titleView
        self.contentLabel.text = post.content.replacingOccurrences(of: "\\n", with: "\n")

        self.authorLabel.text = post.userDisplayName
        self.dateLabel.text = dateToString(date: post.createdAt)
        
        let likeButton = UIButton()
        likeButton.setTitle("좋아요", for: .normal)
        likeButton.setTitleColor(.black, for: .normal)
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .red
        
        let commentButton = UIButton()
        commentButton.setTitle("댓글", for: .normal)
        commentButton.setTitleColor(.black, for: .normal)
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = .green
        
        let likeBarButton = UIBarButtonItem(customView: likeButton)
        let commentBarButton = UIBarButtonItem(customView: commentButton)
        
        
        if postType.id != "notice" {
            navigationItem.rightBarButtonItems = [likeBarButton, commentBarButton]
        }
        
        if postType.id == "everyonesFoot" {
            collectionView.isHidden = true
            mapView.isHidden = false
        }
    }
    
    func getImages() {
        guard let images = post?.images else {
            collectionView.isHidden = true
            return
        }
        
        if images.isEmpty {
            collectionView.isHidden = true
            return
        }
            
        for (index, ref) in images.enumerated() {
            let imageRef = self.storage.reference(forURL: ref)
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("ERROR: \(String(describing: error.localizedDescription))")
                    return
                }
                guard let url = url else {
                    return
                }
                    
                self.images.append(ImageInfo(ref: ref, url: url, order: index))
                
                DispatchQueue.main.async {
                    self.images.sort {
                        $0.order < $1.order
                    }
                    self.collectionView.reloadData()
                }
            }
        }
    }

    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy.MM.dd\nHH시 mm분"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
    
    @IBAction func tapDeleteButton(_ sender: UIButton) {
        present(deleteAlertView, animated: true)
    }
}


extension PostDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell

        cell.imageView.kf.setImage(with: images[indexPath.row].url)
        cell.imageView.contentMode = .scaleAspectFit
        cell.layer.borderWidth = 2
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.cornerRadius = 5
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageDetailViewController = storyboard?.instantiateViewController(withIdentifier: "ImageDetailViewController") as! ImageDetailViewController
        
        imageDetailViewController.imageURL = images[indexPath.row].url
        self.present(imageDetailViewController, animated: true)
    }
}
