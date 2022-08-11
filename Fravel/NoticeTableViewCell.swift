//
//  NoticeTableViewCell.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/01.
//

import UIKit

class NoticeTableViewCell: UITableViewCell {
    @IBOutlet weak var titleTextLabel: UILabel!
    @IBOutlet weak var dateTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configurePost(post: Post) {
        self.titleTextLabel.text = post.title
        self.dateTextLabel.text = dateToString(date: post.createdAt)
        self.selectionStyle = .none
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
}
