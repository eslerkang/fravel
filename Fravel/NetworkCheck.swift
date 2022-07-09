//
//  NetworkCheck.swift
//  Fravel
//
//  Created by 강태준 on 2022/07/09.
//

import Foundation
import Network

final class NetworkCheck {
    static let shared = NetworkCheck()
    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor
    public private(set) var isConnected: Bool = false

    private init() {
        monitor = NWPathMonitor()
    }

    public func startMonitoring() {
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            var isInternetConnected = false
            
            self.isConnected = path.status == .satisfied

            if self.isConnected == true {
                isInternetConnected = true
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("isInternetConnected"), object: isInternetConnected)
        }
    }

    public func stopMonitoring() {
        monitor.cancel()
    }
}
