//
//  ViewModel.swift
//  aaaWatch-app Watch App
//
//  Created by Cristhian Molina on 5/24/25.
//

import CoreMotion
import Foundation
import WatchConnectivity
import SwiftUI

// Add ReceivedFile structure
struct ReceivedFile {
    let name: String
    let size: Int64
    let url: URL
    
    var sizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

class WatchConnectivityViewModel: NSObject, ObservableObject {
  
  static let shared = WatchConnectivityViewModel()
  
  @Published var isReachable: Bool = false
  @Published var message: String = "No message received"
  @Published var data: String = "No data received"
  @Published var applicationContext: [String: Any] = [:]  
  @Published var userInfo: [String: Any] = [:]
  @Published var receivedFiles: [ReceivedFile] = []
  
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

  func sendFile() {
    guard WCSession.default.isReachable else {
      print("iPhone not reachable")
      return
    }

    // 1. Get caches directory
    guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      print("❌ Could not find caches directory.")
      return
    }
    
    // 2. Create a file URL
    let fileName = "TestFileFromWatch.txt"
    let fileURL = cachesDirectory.appendingPathComponent(fileName)
    
    // 3. Content to write
    let fileContent = "Hello from Apple Watch! 🖐️⌚️"
    
    // 4. Write content to the file
    do {
      try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
      print("✅ File written successfully at \(fileURL.path)")
    } catch {
      print("❌ Error writing file: \(error.localizedDescription)")
      return
    }

    // 5. Transfer the file
    WCSession.default.transferFile(fileURL, metadata: ["name": fileName, "size": fileContent.count])

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

  func session(_ session: WCSession, didReceive file: WCSessionFile) {
    
     // Get the file metadata
     let metadata = file.metadata ?? [:]
     let fileName = metadata["name"] as? String ?? "Unknown File"
     let fileSize = metadata["size"] as? Int64 ?? 0
    
    print("Received file: \(fileName) (Size: \(fileSize) bytes) Local URL: \(file.fileURL.absoluteString)")
    
     // Handle the file based on your needs
     do {
       // Get the temporary URL where WatchConnectivity stored the file
       let receivedFileURL = file.fileURL
      
       // Create a URL in the Watch app's documents directory
       let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
       let destinationURL = documentsURL.appendingPathComponent(fileName)
      
       // Move the file to the documents directory
       if FileManager.default.fileExists(atPath: destinationURL.path) {
         try FileManager.default.removeItem(at: destinationURL)
       }
       try FileManager.default.moveItem(at: receivedFileURL, to: destinationURL)
      
       print("File saved successfully at: \(destinationURL.path)")
      
       // Create a ReceivedFile object and update the UI
       let receivedFile = ReceivedFile(name: fileName, size: fileSize, url: destinationURL)
      
       // Update UI on main thread
       DispatchQueue.main.async { [weak self] in
         self?.receivedFiles.append(receivedFile)
       }
     } catch {
       print("❌ Error handling received file: \(error.localizedDescription)")
     }
  }
  
}
