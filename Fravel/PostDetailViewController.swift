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


class PostDetailViewController: UIViewController {
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var postType: PostType?
    var post: Post?
    
    var imageURLs = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        configurePage()
        
        getImages()
    }
    
    func configurePage() {
        guard let post = post,
              let postType = postType
        else {
            return
        }

        self.title = post.title
        self.contentTextView.text = post.content.replacingOccurrences(of: "\\n", with: "\n")
        
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
        let postRef = db.collection("posts").document(post!.id)
        postRef.collection("images").addSnapshotListener {[weak self] snapshot, error in
            guard let self = self else {return}
            if let error = error {
                print("ERROR: \(String(describing: error.localizedDescription))")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("ERROR: Error fetching images from firestore")
                return
            }
            
            documents.forEach {doc in
                let data = doc.data()
                
                guard let ref = data["url"] as? String else {
                    print("ERROR: Invalid Image")
                    return
                }
                
                let imageRef = self.storage.reference(forURL: ref)

                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("ERROR: \(String(describing: error.localizedDescription))")
                        return
                    }
                    guard let url = url else {
                        return
                    }
                    
                    self.imageURLs.append(url)
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
}


extension PostDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell

        cell.imageView.kf.setImage(with: imageURLs[indexPath.row])
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
        
        imageDetailViewController.imageURL = imageURLs[indexPath.row]
        self.present(imageDetailViewController, animated: true)
    }
}
