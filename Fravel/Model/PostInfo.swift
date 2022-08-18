//
//  PostInfo.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/20.
//

import Foundation
import FirebaseFirestore

struct Post {
    let id: String
    let title: String
    let content: String
    let userId: String?
    let type: String
    let createdAt: Date
    var userDisplayName: String?
    let images: [String]?
    let map: DocumentReference?
    
    mutating func changeDisplayName(displayname: String) {
        userDisplayName = displayname
    }
}


struct PostType {
    let id: String
    let name: String
}


struct ImageInfo {
    let ref: String
    let url: URL
    let order: Int
}
