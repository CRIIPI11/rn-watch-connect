import Combine
import ExpoModulesCore
import WatchConnectivity

public class RnWatchConnectModule: Module {
    
    private let manager = RnWatchConnectManager.shared
    private var pendingReplies: [String: ([String: Any]) -> Void] = [:]
    private var pendingDataReplies: [String: (Data) -> Void] = [:]
    
    public func definition() -> ModuleDefinition {
        Name("RnWatchConnect")
        
        // Properties
        Property("isWatchSupported") {
            manager.isSupported
        }
        
        Property("isWatchPaired") {
            manager.isPaired
        }
        
        Property("isWatchAppInstalled") {
            manager.isAppInstalled
        }
        
        Property("isWatchReachable") {
            manager.isReachable
        }
        
        Property("watchActivationState") {
            manager.activationState
        }
        
        Property("applicationContext") {
            WCSession.default.applicationContext
        }
        
        Property("receivedApplicationContext") {
            WCSession.default.receivedApplicationContext
        }
        
        Property("outstandingUserInfoTransfers") {
            var transfers: [Any] = []
            for transfer in WCSession.default.outstandingUserInfoTransfers {
                transfers.append([
                    "id": String(ObjectIdentifier(transfer).hashValue),
                    "userInfo": transfer.userInfo,
                    "isTransferring": transfer.isTransferring
                ])
            }
            return transfers
        }

        Property("outstandingFileTransfers") {
            var transfers: [Any] = []
            for transfer in WCSession.default.outstandingFileTransfers {
                transfers.append([
                    "id": String(ObjectIdentifier(transfer).hashValue),
                    "isTransferring": transfer.isTransferring,
                    "progress": [
                        "fractionCompleted": transfer.progress.fractionCompleted,
                        "completedUnitCount": transfer.progress.completedUnitCount,
                        "totalUnitCount": transfer.progress.totalUnitCount
                    ],
                    "file": [
                        "fileURL": transfer.file.fileURL.absoluteString,
                        "metadata": transfer.file.metadata ?? [:]
                    ]
                ])
            }
            return transfers
        }
        
        // Functions
        
        AsyncFunction("sendMessage") { (message: [String: Any], promise: Promise) in
            RnWatchConnectManager.shared.sendMessage(
                message,
                replyHandler: { reply in
                    promise.resolve(reply)
                },
                errorHandler: { error in
                    promise.reject(error)
                }
            )
        }

        AsyncFunction("sendMessageWithoutReply") { (message: [String: Any], promise: Promise) in
            RnWatchConnectManager.shared.sendMessage(
                message,
                replyHandler: nil,
                errorHandler: { error in
                    promise.reject(error)
                }
            )
        }
        
        AsyncFunction("replyToMessage") { (replyId: String, response: [String: Any], promise: Promise) in
            if let replyHandler = pendingReplies[replyId] {
                replyHandler(response)
                pendingReplies.removeValue(forKey: replyId)
            } else {
                promise.reject(MessageError.invalidReplyId)
            }
        }

        AsyncFunction("replyToDataMessage") { (replyId: String, response: String, promise: Promise) in
            if let replyHandler = pendingDataReplies[replyId] {
                let decodedData = try validateBase64(response)
                replyHandler(decodedData)
                pendingDataReplies.removeValue(forKey: replyId)
            } else {
                promise.reject(MessageError.invalidReplyId)
            }
        }
        
        AsyncFunction("sendDataMessage") { (data: String, promise: Promise) in
            do {
                
                let decodedData = try validateBase64(data)
                
                RnWatchConnectManager.shared.sendDataMessage(
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

        AsyncFunction("sendDataMessageWithoutReply") { (data: String, promise: Promise) in
            do {
                let decodedData = try validateBase64(data)
                RnWatchConnectManager.shared.sendDataMessage(decodedData, replyHandler: nil, errorHandler: { error in
                    promise.reject(error)
                })
            } catch {   
                promise.reject(error)
            }
        }
        
        AsyncFunction("updateApplicationContext") { (applicationContext: [String: Any], promise: Promise) in
            
            do {
                try WCSession.default.updateApplicationContext(applicationContext)
            } catch {
                print("❌ Failed to update application context: \(error.localizedDescription)")
                promise.reject(error)
            }
        }

        Function("transferUserInfo") { (userInfo: [String: Any]) in
           let transfer = WCSession.default.transferUserInfo(userInfo)
            print(transfer.userInfo)
            return [
                "id": String(ObjectIdentifier(transfer).hashValue),
                "isTransferring": transfer.isTransferring
            ]
        }

        AsyncFunction("cancelUserInfoTransfer") { (transferId: String, promise: Promise) in
            guard let transfer = WCSession.default.outstandingUserInfoTransfers.first(where: { String(ObjectIdentifier($0).hashValue) == transferId }) else {
                promise.reject(UserInfoTransferError.invalidTransferId)
                return
            }
            transfer.cancel()
            promise.resolve(nil)
        }

        Function("transferFile") { (file: String, metadata: [String: Any]?) in
            return RnWatchConnectManager.shared.transferFile(file, metadata: metadata)
        }
        
        Function("cancelFileTransfer") { (transferId: String) in
            guard let transfer = WCSession.default.outstandingFileTransfers.first(where: { String(ObjectIdentifier($0).hashValue) == transferId }) else {
                return [
                    "error": "Invalid transfer ID"
                ]
            }
            transfer.cancel()
            return [
                "id": transferId
            ]
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
        
        OnStartObserving {
            
            manager.$isPaired
                .sink { [weak self] value in
                    self?.sendEvent("onWatchPairedChanged", ["isPaired": value])
                }
                .store(in: &cancellables)
            
            manager.$isAppInstalled
                .sink { [weak self] value in
                    self?.sendEvent("onWatchAppInstallChanged", ["isAppInstalled": value])
                }
                .store(in: &cancellables)
            
            manager.$isReachable
                .sink { [weak self] value in
                    self?.sendEvent("onReachabilityChanged", ["isReachable": value])
                }
                .store(in: &cancellables)
            
            manager.messageReceivedHandler = { [weak self] message in
                self?.sendEvent("onMessageReceived", message)
            }
            
            manager.messageWithReplyHandler = { [weak self] message, reply in
                let replyId = UUID().uuidString
                self?.pendingReplies[replyId] = reply
                self?.sendEvent("onMessageWithReply", [
                    "message": message,
                    "replyId": replyId
                ])
            }

            manager.messageDataReceivedHandler = { [weak self] data in
                self?.sendEvent("onDataMessageReceived", ["data": data.base64EncodedString()])
            }

            manager.messageDataWithReplyHandler = { [weak self] data, reply in
                let replyId = UUID().uuidString
                self?.pendingDataReplies[replyId] = reply
                self?.sendEvent("onDataMessageWithReply", [
                    "data": data.base64EncodedString(),
                    "replyId": replyId
                ])
            }

            manager.$applicationContext.sink { [weak self] applicationContext in
                self?.sendEvent("onApplicationContextChanged", applicationContext)
            }
            .store(in: &cancellables)

            manager.$userInfo.sink { [weak self] userInfo in
                self?.sendEvent("onUserInfoReceived", userInfo)
            }
            .store(in: &cancellables)

            manager.$receivedFile.sink { [weak self] file in
                self?.sendEvent("onFileReceived", file)
            }
            .store(in: &cancellables)
        }
        
        OnStopObserving {
            cancellables.removeAll()
            manager.messageReceivedHandler = nil
            manager.messageWithReplyHandler = nil
            manager.messageDataReceivedHandler = nil
            manager.messageDataWithReplyHandler = nil
            pendingReplies.removeAll()
            pendingDataReplies.removeAll()
        }
    }
    
    private var cancellables: Set<AnyCancellable> = []
}
