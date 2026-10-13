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

enum MessageError: LocalizedError {
    
    case invalidBase64Format
    case invalidBase64Length
    case invalidBase64Padding
    case invalidBase64Decoding
    case invalidReplyId
    
    var errorDescription: String? {
        switch self {
        case .invalidBase64Format:
            return "String contains invalid base64 characters"
        case .invalidBase64Length:
            return "Base64 string length must be multiple of 4"
        case .invalidBase64Padding:
            return "Invalid base64 padding"
        case .invalidBase64Decoding:
            return "Failed to decode base64 string"
        case .invalidReplyId:
            return "Invalid reply ID"
        }
    }
}

enum UserInfoTransferError: LocalizedError {
    case invalidTransferId

    var errorDescription: String? {
        switch self {
            case .invalidTransferId:
                return "Invalid transfer ID"
        }
    }
}

enum FileTransferError: LocalizedError {
    case invalidFileURL
    case fileNotFound
    case invalidTransferId

    var errorDescription: String? {
        switch self {
        case .invalidFileURL:
            return "Invalid file URL"
        case .fileNotFound:
            return "File not found at the specified path"
        case .invalidTransferId:
            return "Invalid transfer ID"
        }
    }
}