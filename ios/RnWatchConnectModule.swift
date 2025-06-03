import Combine
import ExpoModulesCore
import WatchConnectivity

public class RnWatchConnectModule: Module {

    private let manager = RnWatchConnectManager.shared
    private var pendingReplies: [String: ([String: Any]) -> Void] = [:]

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

        //        Functions

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

        AsyncFunction("replyToMessage") { (replyId: String, response: [String: Any], promise: Promise) in
            if let replyHandler = self.pendingReplies[replyId] {
                replyHandler(response)
                self.pendingReplies.removeValue(forKey: replyId)
            } else {
                promise.reject(NSError(domain: "WatchReply", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid reply ID"]))
            }
        }

        // Events
        Events(
            "onWatchPairedChanged",
            "onWatchAppInstallChanged",
            "onReachabilityChanged",
            "onMessageReceived",
            "onMessageWithReply"
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
            
        }

        OnStopObserving {
            cancellables.removeAll()
            manager.messageReceivedHandler = nil
            manager.messageWithReplyHandler = nil
            self.pendingReplies.removeAll()
        }
    }

    private var cancellables: Set<AnyCancellable> = []
}
