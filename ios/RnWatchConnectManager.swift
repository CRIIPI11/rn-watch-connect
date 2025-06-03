//
//  RnWatchConnectManager.swift
//  RnWatchConnect
//
//  Created by Cristhian Molina on 5/22/25.
//

import Foundation
import WatchConnectivity

final class RnWatchConnectManager: NSObject, WCSessionDelegate {
    static let shared: RnWatchConnectManager = RnWatchConnectManager()
    
    private let stateQueue = DispatchQueue(label: "com.rnwatchconnect.state", qos: .userInitiated)
    
    // MARK: - Published state
    @Published private(set) var activationState: String = "unknown"
    @Published private(set) var isPaired: Bool = false
    @Published private(set) var isAppInstalled: Bool = false
    @Published private(set) var isReachable: Bool = false
    
    var isSupported: Bool {
        WCSession.isSupported()
    }
    
    var messageReceivedHandler: (([String: Any]) -> Void)?
    var messageWithReplyHandler: (([String: Any], @escaping ([String: Any]) -> Void) -> Void)?
    
    // Initialization
    private override init() {
        super.init()
        activateSession()
    }
    
    deinit {
        messageReceivedHandler = nil
        messageWithReplyHandler = nil
    }
    
    // MARK: - Private methods
    // Function to activate the session and set the delegate
    private func activateSession() {
        guard isSupported else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()  
    }

    // Function to update the activation state description
    private func updateActivationStateDescription() {
        stateQueue.async { [weak self] in
            guard let self = self else { return }
            self.activationState = {
                switch WCSession.default.activationState {
                case .notActivated: return "notActivated"
                case .inactive: return "inactive"
                case .activated: return "activated"
                @unknown default: return "unknown"
                }
            }()
        }
    }
    
    // MARK: - Functions
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        guard WCSession.default.activationState == .activated else {
            errorHandler?(WatchConnectivityError.sessionNotActivated)
            return
        }
        
        guard WCSession.default.isReachable else {
            errorHandler?(WatchConnectivityError.watchNotReachable)
            return
        }
        
        WCSession.default.sendMessage(message) { reply in
            replyHandler?(reply)
        } errorHandler: { error in
            errorHandler?(WatchConnectivityError.messageSendFailed(error))
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("Session activation failed with error: \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }   
            self.updateActivationStateDescription()
            self.isPaired = session.isPaired
            self.isAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPaired = session.isPaired
            self.isAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.messageReceivedHandler?(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.messageWithReplyHandler?(message, replyHandler)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
        stateQueue.async { [weak self] in
            self?.updateActivationStateDescription()
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate the session
        WCSession.default.activate()
    }
}
