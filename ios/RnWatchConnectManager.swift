//
//  RnWatchConnectManager.swift
//  RnWatchConnect
//
//  Created by Cristhian Molina on 5/22/25.
//

import Foundation
import WatchConnectivity

class RnWatchConnectManager: NSObject {
    static let shared: RnWatchConnectManager = RnWatchConnectManager()
    let stateQueue = DispatchQueue(label: "com.rnwatchconnect.state", qos: .userInitiated)
    
    // MARK: - Published state
    @Published var activationState: String = "unknown"
    @Published var isPaired: Bool = false
    @Published var isAppInstalled: Bool = false
    @Published var isReachable: Bool = false
    
    var isSupported: Bool {
        WCSession.isSupported()
    }
    
    var messageReceivedHandler: (([String: Any]) -> Void)?
    var messageWithReplyHandler: (([String: Any], @escaping ([String: Any]) -> Void) -> Void)?
    var messageDataReceivedHandler: ((Data) -> Void)?
    var messageDataWithReplyHandler: ((Data, @escaping (Data) -> Void) -> Void)?
    
    // Initialization
    private override init() {
        super.init()
        activateSession()
    }
    
    deinit {
        messageReceivedHandler = nil
        messageWithReplyHandler = nil
        messageDataReceivedHandler = nil
        messageDataWithReplyHandler = nil
    }
    
    // MARK: - Private methods
    // Function to activate the session and set the delegate
    private func activateSession() {
        guard isSupported else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    
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
    
}
