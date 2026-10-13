import ExpoModulesCore

public class RnWatchConnectModule: Module {
    
    private let controller = WatchSessionController(port: WCWatchSessionAdapter())
    
    public func definition() -> ModuleDefinition {
        Name("RnWatchConnect")
        
        // Properties
        Property("isWatchSupported") {
            controller.isSupported
        }
        
        Property("isWatchPaired") {
            controller.isPaired
        }
        
        Property("isWatchAppInstalled") {
            controller.isWatchAppInstalled
        }
        
        Property("isWatchReachable") {
            controller.isReachable
        }
        
        Property("watchActivationState") {
            controller.activationState.rawValue
        }
        
        Property("applicationContext") {
            controller.applicationContext
        }
        
        Property("receivedApplicationContext") {
            controller.receivedApplicationContext
        }
        
        Property("outstandingUserInfoTransfers") {
            controller.outstandingUserInfoTransfers.map(Self.jsValue)
        }

        Property("outstandingFileTransfers") {
            controller.outstandingFileTransfers.map(Self.jsValue)
        }
        
        // Functions
        
        AsyncFunction("sendMessage") { (message: [String: Any], promise: Promise) in
            self.controller.sendMessage(
                message,
                replyHandler: { reply in
                    promise.resolve(reply)
                },
                errorHandler: { error in
                    promise.reject(error)
                }
            )
        }

        AsyncFunction("sendMessageWithoutReply") { (message: [String: Any]) in
            try self.controller.sendMessageWithoutReply(message)
        }
        
        AsyncFunction("replyToMessage") { (replyId: String, response: [String: Any]) in
            try self.controller.replyToMessage(replyId: replyId, reply: response)
        }

        AsyncFunction("replyToDataMessage") { (replyId: String, response: String) in
            let decodedData = try validateBase64(response)
            try self.controller.replyToDataMessage(replyId: replyId, reply: decodedData)
        }
        
        AsyncFunction("sendDataMessage") { (data: String, promise: Promise) in
            do {
                let decodedData = try validateBase64(data)
                
                self.controller.sendDataMessage(
                    decodedData,
                    replyHandler: { responseData in
                        promise.resolve(responseData.base64EncodedString())
                    },
                    errorHandler: { error in
                        promise.reject(error)
                    }
                )
            } catch {
                promise.reject(error)
            }
        }

        AsyncFunction("sendDataMessageWithoutReply") { (data: String) in
            let decodedData = try validateBase64(data)
            try self.controller.sendDataMessageWithoutReply(decodedData)
        }
        
        AsyncFunction("updateApplicationContext") { (applicationContext: [String: Any]) in
            try self.controller.updateApplicationContext(applicationContext)
        }

        Function("transferUserInfo") { (userInfo: [String: Any]) -> [String: Any] in
            Self.jsValue(self.controller.transferUserInfo(userInfo))
        }

        Function("cancelUserInfoTransfer") { (transferId: String) -> [String: Any] in
            try self.controller.cancelUserInfoTransfer(id: transferId)
            return ["id": transferId]
        }

        Function("transferFile") { (file: String, metadata: [String: Any]?) -> [String: Any] in
            Self.jsValue(try self.controller.transferFile(file, metadata: metadata))
        }
        
        Function("cancelFileTransfer") { (transferId: String) -> [String: Any] in
            try self.controller.cancelFileTransfer(id: transferId)
            return ["id": transferId]
        }

        // Events
        Events(
            "onWatchPairedChanged",
            "onWatchAppInstallChanged",
            "onReachabilityChanged",
            "onMessageReceived",
            "onMessageWithReply",
            "onDataMessageReceived",
            "onDataMessageWithReply",
            "onApplicationContextChanged",
            "onUserInfoReceived",
            "onFileReceived"
        )
        
        OnCreate {
            controller.onEvent = { [weak self] event in
                self?.send(event)
            }
            controller.activate()
        }
        
        // Runs once the last JS listener is removed: nobody is left to answer pending Replies.
        OnStopObserving {
            controller.dropPendingReplies()
        }
    }
    
    private func send(_ event: SessionEvent) {
        switch event {
        case let .pairedChanged(isPaired):
            sendEvent("onWatchPairedChanged", ["isWatchPaired": isPaired])
        case let .watchAppInstalledChanged(isAppInstalled):
            sendEvent("onWatchAppInstallChanged", ["isWatchAppInstalled": isAppInstalled])
        case let .reachabilityChanged(isReachable):
            sendEvent("onReachabilityChanged", ["isWatchReachable": isReachable])
        case let .message(message):
            sendEvent("onMessageReceived", message)
        case let .messageWithReply(message, replyId):
            sendEvent("onMessageWithReply", ["message": message, "replyId": replyId])
        case let .dataMessage(data):
            sendEvent("onDataMessageReceived", ["data": data.base64EncodedString()])
        case let .dataMessageWithReply(data, replyId):
            sendEvent("onDataMessageWithReply", ["data": data.base64EncodedString(), "replyId": replyId])
        case let .applicationContext(applicationContext):
            sendEvent("onApplicationContextChanged", applicationContext)
        case let .userInfo(userInfo):
            sendEvent("onUserInfoReceived", userInfo)
        case let .fileReceived(fileURL, metadata):
            sendEvent("onFileReceived", ["fileURL": fileURL.absoluteString, "metadata": metadata])
        }
    }
    
    // MARK: - JS shapes (OutstandingUserInfoTransfer, FileTransfer in RnWatchConnect.types.ts)
    
    private static func jsValue(_ transfer: UserInfoTransferSnapshot) -> [String: Any] {
        [
            "id": transfer.id,
            "isTransferring": transfer.isTransferring,
            "userInfo": transfer.userInfo,
        ]
    }
    
    private static func jsValue(_ transfer: FileTransferSnapshot) -> [String: Any] {
        [
            "id": transfer.id,
            "isTransferring": transfer.isTransferring,
            "progress": [
                "fractionCompleted": transfer.progress.fractionCompleted,
                "completedUnitCount": transfer.progress.completedUnitCount,
                "totalUnitCount": transfer.progress.totalUnitCount,
            ],
            "file": [
                "fileURL": transfer.fileURL.absoluteString,
                "metadata": transfer.metadata,
            ],
        ]
    }
}
