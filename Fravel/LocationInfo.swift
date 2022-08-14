//
//  LocationInfo.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/09.
//

import Foundation
import CoreLocation

struct LocationInfo {
    let latitude: String
    let longitude: String
    let createdAt: Date
    let location: CLLocation
}

struct Map {
    let status: String
    let locations: [LocationInfo]
}
