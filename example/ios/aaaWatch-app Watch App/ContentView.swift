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

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
            Text("📡 Connection Status: \(viewModel.isReachable ? "Reachable" : "Not Reachable")")
              .font(.headline)
              .foregroundColor(viewModel.isReachable ? .green : .red)

            Text("Message: \(viewModel.message)")
              .font(.subheadline)
              .padding()
              .background(Color.gray.opacity(0.2))
              .cornerRadius(8)
              .padding()
  
          Text("✉️ Send Message to iPhone")
            .font(.headline)
          TextField("Message", text: $messageToSend)
          Button("Send Message") {
            viewModel.sendMessage(["message": messageToSend]) { response in
              print("Reply received: \(response)")
            } errorHandler: { error in
              print("Error sending message: \(error.localizedDescription)")
            }
          }
        }
        }
    }
}

#Preview {
    ContentView()
}
