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
        self.commentTextLabel.text = "💬 0"
        self.likeTextLabel.text = "❤️ 0"
        self.selectionStyle = .none
        self.authorTextLabel.text = post.userDisplayName
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
}
