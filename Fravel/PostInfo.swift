//
//  PostInfo.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/20.
//

import Foundation
import FirebaseFirestore
import FirebaseCore

struct Post {
    let id: String
    let title: String
    let content: String
    let userId: String
    let type: String
    let createdAt: Date
}


struct PostType {
    let id: String
    let name: String
}
