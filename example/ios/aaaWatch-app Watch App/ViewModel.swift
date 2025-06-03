//
//  ViewModel.swift
//  aaaWatch-app Watch App
//
//  Created by Cristhian Molina on 5/24/25.
//


import CoreMotion
import Foundation
import WatchConnectivity



class WatchConnectivityViewModel: NSObject, ObservableObject {
  
  static let shared = WatchConnectivityViewModel()
  
  @Published var isReachable: Bool = false
  @Published var message: String = "No message received"
  private override init() {
    super.init()
    activateSession()
  }
  
  private func activateSession() {
    if WCSession.isSupported() {
      let session = WCSession.default
      session.delegate = self
      session.activate()
    }
  }
  
  func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error) -> Void)? = nil) {
    guard WCSession.default.isReachable else {
      print("iPhone not reachable")
      errorHandler?(NSError(domain: "WatchConnectivity", code: 1, userInfo: [NSLocalizedDescriptionKey: "iPhone not reachable."]))
      return
    }
    
    WCSession.default.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
  }
  
}

// MARK: - WCSessionDelegate
extension WatchConnectivityViewModel: WCSessionDelegate {
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    print("WCSession activated with state: \(activationState)")
    if let error = error {
      print("Activation error: \(error.localizedDescription)")
    }
  }
  
  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async {
      self.isReachable = session.isReachable
    }
  }
  

  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    DispatchQueue.main.async {
      self.message = message["message"] as? String ?? "No message received"
    }
    replyHandler(["message": "Message received"])
  }
  
}
