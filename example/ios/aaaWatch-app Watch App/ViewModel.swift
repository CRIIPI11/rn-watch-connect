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
  @Published var data: String = "No data received"
  @Published var applicationContext: [String: Any] = [:]  
  @Published var userInfo: [String: Any] = [:]
  
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

  func sendMessageWithoutReply(_ message: [String: Any]) {
    guard WCSession.default.isReachable else {
      print("iPhone not reachable")
      return
    }
    WCSession.default.sendMessage(message, replyHandler: nil)
    { error in
      print("Error sending message: \(error.localizedDescription)")
    }
  }

  func sendDataMessage() {
    guard WCSession.default.isReachable else {
      print("iPhone not reachable")
      let error = NSError(domain: "WatchConnectivity", code: 1, userInfo: [NSLocalizedDescriptionKey: "iPhone not reachable."])
      print(error.localizedDescription)
      return
    }

    WCSession.default.sendMessageData(Data(base64Encoded: "RGF0YSBNZXNzYWdlIHNlbnQgZnJvbSB3YXRjaA==")!, replyHandler: nil)
    { error in
      print("Error sending data message: \(error.localizedDescription)")
    }
  }

  func sendDataMessageWithReply() {
    guard WCSession.default.isReachable else {
      print("iPhone not reachable")
      let error = NSError(domain: "WatchConnectivity", code: 1, userInfo: [NSLocalizedDescriptionKey: "iPhone not reachable."])
      print(error.localizedDescription)
      return
    }

    WCSession.default.sendMessageData(Data(base64Encoded: "RGF0YSBNZXNzYWdlIHNlbnQgZnJvbSB3YXRjaCB3aXRoIHJlcGx5IGV4cGVjdGVk")!, replyHandler: { data in
      print("Data message received: \(String(data: data, encoding: .utf8)!)")
    })
    { error in
      print("Error sending data message: \(error.localizedDescription)")
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
    DispatchQueue.main.async { [weak self] in
      self?.isReachable = session.isReachable
    }
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    print("didReceiveMessage: \(message)")
  }

  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    DispatchQueue.main.async { [weak self] in
      self?.message = message["message"] as? String ?? "No message received"
    }
    replyHandler(["message": "Message received on watch!"])
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
    DispatchQueue.main.async { [weak self] in
      print("raw data: \(messageData) \(String(data: messageData, encoding: .utf8)!)")
      guard let decodedString = String(data: messageData, encoding: .utf8) else {
        self?.data = "No data received"
        return
      }
      self?.data = decodedString
    }
    replyHandler(Data(base64Encoded: "UmVzcG9uc2UgcmVjZWl2ZWQgaW4gd2F0Y2gh")!)
  }

  func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    DispatchQueue.main.async { [weak self] in
      print("raw data: \(messageData) \(String(data: messageData, encoding: .utf8)!)")
      guard let decodedString = String(data: messageData, encoding: .utf8) else {
        self?.data = "No data received"
        return
      }
      self?.data = decodedString
    }
  }
  
  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
      print("didReceiveApplicationContext: \(applicationContext)")
      DispatchQueue.main.async { [weak self] in
        self?.applicationContext = applicationContext
      }
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    print("didReceiveUserInfo: \(userInfo)")
    DispatchQueue.main.async { [weak self] in
      self?.userInfo = userInfo
    }
  }
  
}
