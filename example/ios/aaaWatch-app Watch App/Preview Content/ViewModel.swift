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
  
  
}
