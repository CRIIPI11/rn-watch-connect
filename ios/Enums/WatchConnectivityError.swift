//
//  WatchConnectivityError.swift
//  RnWatchConnect
//
//  Created by Cristhian Molina on 5/24/25.
//

import Foundation

/// Errors that can occur during Watch Connectivity operations
enum WatchConnectivityError: LocalizedError {
    case watchNotReachable
    case sessionNotActivated
    case messageSendFailed(Error)
    
    var errorDescription: String? {
        switch self {
            case .watchNotReachable:
                return "Watch is not reachable at the moment"
            case .sessionNotActivated:
                return "Watch connectivity session is not activated"
            case .messageSendFailed(let error):
                return "Failed to send message: \(error.localizedDescription)"
        }
    }
    
    var errorCode: Int {
        switch self {
            case .watchNotReachable:
                return 1001
            case .sessionNotActivated:
                return 1002
            case .messageSendFailed:
                return 1003
        }
    }
} 
