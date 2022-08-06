//
//  DefaultTableViewCell.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/21.
//

import UIKit
import FirebaseFirestore


class DefaultTableViewCell: UITableViewCell {
    @IBOutlet weak var titleTextLabel: UILabel!
    @IBOutlet weak var authorTextLabel: UILabel!
    @IBOutlet weak var likeTextLabel: UILabel!
    @IBOutlet weak var commentTextLabel: UILabel!
    @IBOutlet weak var dateTextLabel: UILabel!
    
    let db = Firestore.firestore()
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configurePost(post: Post) {
        self.titleTextLabel.text = post.title
        self.dateTextLabel.text = dateToString(date: post.createdAt)
        self.commentTextLabel.text = "0"
        self.likeTextLabel.text = "0"
        
        guard let userId = post.userId else {
            setAuthorAsUnknown()
            return
        }
        
        getUserDisplayName(userId: userId)
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
    
    private func getUserDisplayName(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else {return}
            if let error = error {
                print("ERROR: \(String(describing: error.localizedDescription))")
                self.setAuthorAsUnknown()
                return
            }
            if let document = snapshot, document.exists {
                let data = document.data()
                guard let displayname = data?["displayname"] as? String else {
                    self.setAuthorAsUnknown()
                    return
                }
                self.authorTextLabel.text = displayname
            } else {
                print("ERROR: Document does not exist")
                self.setAuthorAsUnknown()
                return
            }
        }
    }
    
    private func setAuthorAsUnknown() {
        self.authorTextLabel.text = "(알수없음)"
    }
}
