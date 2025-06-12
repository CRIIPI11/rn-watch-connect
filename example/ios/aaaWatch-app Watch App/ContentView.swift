//
//  ContentView.swift
//  aaaWatch-app Watch App
//
//  Created by Cristhian Molina on 5/24/25.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
  @ObservedObject private var viewModel = WatchConnectivityViewModel.shared
  @State private var messageToSend = "Hello from watch"
  @State private var messageToSendWithoutReply = "Hello from watch without reply"
  
  var body: some View {
    List {
      Section(header: Text("Connection Status")) {
        Text("📡 Connection Status: \(viewModel.isReachable ? "Reachable" : "Not Reachable")")
          .font(.headline)
          .foregroundColor(viewModel.isReachable ? .green : .red)
      }
      Section(header: Text("Message")) {
        Text("Message: \(viewModel.message)")
          .font(.subheadline)

        TextField("Message", text: $messageToSend)
        Button("Send Message") {
          viewModel.sendMessage(["message": messageToSend]) { response in
            print("Reply received: \(response)")
          } errorHandler: { error in
            print("Error sending message: \(error.localizedDescription)")
          }
        }
        Button("Send Message Without Reply") {
          viewModel.sendMessageWithoutReply(["message": messageToSendWithoutReply])
        }
      }
      Section(header: Text("Send Data Message")) {
        Text("Data: \(viewModel.data)")
          .font(.subheadline)
          
        Button("Send Data Message") {
          viewModel.sendDataMessage() 
        }
        Button("Send Data Message With Reply") {
          viewModel.sendDataMessageWithReply()
        }
      }
      
      Section(header: Text("Application Context")) {
        Text("application context: \(viewModel.applicationContext)")
          .font(.subheadline)
        Text("application context from session: \(WCSession.default.receivedApplicationContext)")
          .font(.subheadline)
        Text("sent application context: \(WCSession.default.applicationContext)")
          .font(.subheadline)
          
        Button("Send Data Message") {
          do {
            try WCSession.default.updateApplicationContext(["theme": "dark"])
          } catch {
            print("❌ Failed to update application context: \(error.localizedDescription)")
          }
        }
      }
      

      Section(header: Text("User Info")) {
        Text("user info: \(viewModel.userInfo)")
          .font(.subheadline) 
        Button("Transfer User Info") {
          WCSession.default.transferUserInfo(["name": "John", "age": 30])
        }
      }
      
       Section(header: Text("Received Files")) {
         if viewModel.receivedFiles.isEmpty {
           Text("No files received")
             .font(.subheadline)
             .foregroundColor(.secondary)
         } else {
           ForEach(viewModel.receivedFiles, id: \.name) { file in
             VStack(alignment: .leading) {
               Text(file.name)
                 .font(.headline)
               Text(file.sizeString)
                 .font(.caption)
                 .foregroundColor(.secondary)
             }
           }
         }

         Button("Send File") {
          viewModel.sendFile()
         }
       }
        
    }
  }
}

#Preview {
  ContentView()
}
