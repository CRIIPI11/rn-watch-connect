import SwiftUI

@main
struct WatchConnectExampleApp: App {
  @State private var store = ConnectivityStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(store)
    }
  }
}
