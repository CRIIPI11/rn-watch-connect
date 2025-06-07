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
            self.manager.isSupported
        }
        
        Property("isWatchPaired") {
            self.manager.isPaired
        }
        
        Property("isWatchAppInstalled") {
            self.manager.isAppInstalled
        }
        
        Property("isWatchReachable") {
            self.manager.isReachable
        }
        
        Property("watchActivationState") {
            self.manager.activationState
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
            if let replyHandler = self.pendingReplies[replyId] {
                replyHandler(response)
                self.pendingReplies.removeValue(forKey: replyId)
            } else {
                promise.reject(MessageError.invalidReplyId)
            }
        }

        AsyncFunction("replyToDataMessage") { (replyId: String, response: String, promise: Promise) in
            if let replyHandler = self.pendingDataReplies[replyId] {
                let decodedData = try validateBase64(response)
                replyHandler(decodedData)
                self.pendingDataReplies.removeValue(forKey: replyId)
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
        
        // Events
        Events(
            "onWatchPairedChanged",
            "onWatchAppInstallChanged",
            "onReachabilityChanged",
            "onMessageReceived",
            "onMessageWithReply",
            "onDataMessageReceived",
            "onDataMessageWithReply"
        )
        
        OnStartObserving {
            
            manager.$isPaired
                .sink { self.sendEvent("onWatchPairedChanged", ["isPaired": $0]) }
                .store(in: &cancellables)
            
            manager.$isAppInstalled
                .sink { self.sendEvent("onWatchAppInstallChanged", ["isAppInstalled": $0]) }
                .store(in: &cancellables)
            
            manager.$isReachable
                .sink { self.sendEvent("onReachabilityChanged", ["isReachable": $0]) }
                .store(in: &cancellables)
            
            manager.messageReceivedHandler = { message in
                self.sendEvent("onMessageReceived", message)
            }
            
            manager.messageWithReplyHandler = { message, reply in
                let replyId = UUID().uuidString
                self.pendingReplies[replyId] = reply
                self.sendEvent("onMessageWithReply", [
                    "message": message,
                    "replyId": replyId
                ])
            }

            manager.messageDataReceivedHandler = { data in
                self.sendEvent("onDataMessageReceived", ["data": data.base64EncodedString()])
            }

            manager.messageDataWithReplyHandler = { data, reply in
                let replyId = UUID().uuidString
                self.pendingDataReplies[replyId] = reply
                self.sendEvent("onDataMessageWithReply", [
                    "data": data.base64EncodedString(),
                    "replyId": replyId
                ])
            }
        }
        
        OnStopObserving {
            cancellables.removeAll()
            manager.messageReceivedHandler = nil
            manager.messageWithReplyHandler = nil
            manager.messageDataReceivedHandler = nil
            manager.messageDataWithReplyHandler = nil
            self.pendingReplies.removeAll()
            self.pendingDataReplies.removeAll()
        }
    }
    
    private var cancellables: Set<AnyCancellable> = []
}
