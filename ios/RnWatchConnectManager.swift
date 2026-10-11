//
//  RnWatchConnectManager.swift
//  RnWatchConnect
//
//  Created by Cristhian Molina on 5/22/25.
//

import Foundation
import WatchConnectivity

// Outbound calls still on their way to the WatchSessionController (#3).
// Inbound traffic and Session activation already live there.
class RnWatchConnectManager: NSObject {
    static let shared: RnWatchConnectManager = RnWatchConnectManager()
    
    // MARK: - Functions
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        guard WCSession.default.isReachable else {
            errorHandler?(WatchConnectivityError.watchNotReachable)
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendDataMessage(
        _ data: Data,
        replyHandler: ((Data) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        guard WCSession.default.isReachable else {
            errorHandler?(WatchConnectivityError.watchNotReachable)
            return
        }
        
        WCSession.default.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func transferFile(
        _ file: String,
        metadata: [String : Any]?
    ) throws -> [String: Any] {
        guard let fileURL = URL(string: file) else {
            throw FileTransferError.invalidFileURL
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.relativePath) else {
            throw FileTransferError.fileNotFound
        }
        
        let transfer = WCSession.default.transferFile(fileURL, metadata: metadata)
        
        return [
            "id": String(ObjectIdentifier(transfer).hashValue),
            "isTransferring": transfer.isTransferring,
            "progress": [
                "total": transfer.progress.totalUnitCount,
                "completed": transfer.progress.completedUnitCount,
                "fractionCompleted": transfer.progress.fractionCompleted,
            ],
            "file": [
                "fileURL": transfer.file.fileURL.absoluteString,
                "metadata": transfer.file.metadata ?? [:],
            ],
        ]
    }

    
}
