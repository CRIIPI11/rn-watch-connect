//
//  ReceiverDelegate.swift
//  RnWatchConnect
//
//  Created by Cristhian Molina on 6/7/25.
//

import Foundation
import WatchConnectivity

extension RnWatchConnectManager: WCSessionDelegate {
    
    // MARK: - Private Functions
    // Function to update the activation state description
    private func updateActivationStateDescription() {
        self.stateQueue.async { [weak self] in
            self?.activationState = {
                switch WCSession.default.activationState {
                case .notActivated: return "notActivated"
                case .inactive: return "inactive"
                case .activated: return "activated"
                @unknown default: return "unknown"
                }
            }()
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
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
      DispatchQueue.main.async { [weak self] in
        self?.messageDataReceivedHandler?(messageData)
      }
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
      DispatchQueue.main.async { [weak self] in
        self?.messageDataWithReplyHandler?(messageData, replyHandler)
      }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.applicationContext = applicationContext
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
