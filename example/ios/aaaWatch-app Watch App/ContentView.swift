//
//  ContentView.swift
//  aaaWatch-app Watch App
//
//  Created by Cristhian Molina on 5/24/25.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject private var viewModel = WatchConnectivityViewModel.shared
    var body: some View {
        VStack {
          Text("📡 Connection Status: \(viewModel.isReachable ? "Reachable" : "Not Reachable")")
            .font(.headline)
            .foregroundColor(viewModel.isReachable ? .green : .red)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
