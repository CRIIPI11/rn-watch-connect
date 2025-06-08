//
//  ContentView.swift
//  aaaWatch-app Watch App
//
//  Created by Cristhian Molina on 5/24/25.
//

import SwiftUI

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
    }
  }
}

#Preview {
  ContentView()
}
