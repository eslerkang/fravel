//
//  LocationInfo.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/09.
//

import Foundation
import CoreLocation

struct LocationInfo: Codable {
    let latitude: String
    let longitude: String
    let id: Int?
    let timestamp: Date
}
