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
            controller.outstandingUserInfoTransfers.map(JSEvents.value)
        }

        Property("outstandingFileTransfers") {
            controller.outstandingFileTransfers.map(JSEvents.value)
        }
        
        // Functions
        
        AsyncFunction("sendMessage") { (message: [String: Any], promise: Promise) in
            self.controller.sendMessage(
                message,
                replyHandler: { reply in
                    promise.resolve(reply)
                },
                errorHandler: { error in
                    promise.reject(WatchConnectException(error))
                }
            )
        }

        AsyncFunction("sendMessageWithoutReply") { (message: [String: Any]) in
            try withErrorCodes { try self.controller.sendMessageWithoutReply(message) }
        }
        
        AsyncFunction("replyToMessage") { (replyId: String, response: [String: Any]) in
            try withErrorCodes { try self.controller.replyToMessage(replyId: replyId, reply: response) }
        }

        AsyncFunction("replyToDataMessage") { (replyId: String, response: String) in
            try withErrorCodes {
                let decodedData = try validateBase64(response)
                try self.controller.replyToDataMessage(replyId: replyId, reply: decodedData)
            }
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
                        promise.reject(WatchConnectException(error))
                    }
                )
            } catch {
                promise.reject(WatchConnectException(error))
            }
        }

        AsyncFunction("sendDataMessageWithoutReply") { (data: String) in
            try withErrorCodes {
                let decodedData = try validateBase64(data)
                try self.controller.sendDataMessageWithoutReply(decodedData)
            }
        }
        
        AsyncFunction("updateApplicationContext") { (applicationContext: [String: Any]) in
            try withErrorCodes { try self.controller.updateApplicationContext(applicationContext) }
        }

        Function("transferUserInfo") { (userInfo: [String: Any]) -> [String: Any] in
            JSEvents.value(self.controller.transferUserInfo(userInfo))
        }

        Function("cancelUserInfoTransfer") { (transferId: String) -> [String: Any] in
            try withErrorCodes { try self.controller.cancelUserInfoTransfer(id: transferId) }
            return ["id": transferId]
        }

        Function("transferFile") { (file: String, metadata: [String: Any]?) -> [String: Any] in
            JSEvents.value(try withErrorCodes { try self.controller.transferFile(file, metadata: metadata) })
        }
        
        Function("cancelFileTransfer") { (transferId: String) -> [String: Any] in
            try withErrorCodes { try self.controller.cancelFileTransfer(id: transferId) }
            return ["id": transferId]
        }

        // Events
        Events(JSEvents.names)
        
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
        let jsEvent = JSEvents.event(for: event)
        sendEvent(jsEvent.name, jsEvent.body)
    }
}
