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

    // MARK: - Published state
    @Published private(set) var activationState: String = "unknown"
    @Published private(set) var isPaired: Bool = false
    @Published private(set) var isAppInstalled: Bool = false
    @Published private(set) var isReachable: Bool = false
    var isSupported: Bool {
        WCSession.isSupported()
    }

    // Initialization
    private override init() {
        super.init()
        activateSession()
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
        print("function", WCSession.default.activationState)
        self.activationState = {
            switch WCSession.default.activationState {
            case .notActivated: return "notActivated"
            case .inactive: return "inactive"
            case .activated: return "activated"
            @unknown default: return "unknown"
            }
        }()
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.updateActivationStateDescription()
            self.isPaired = session.isPaired
            self.isAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isAppInstalled = session.isWatchAppInstalled
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { /*…*/  }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
