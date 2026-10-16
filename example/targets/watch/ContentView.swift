import SwiftUI

struct ContentView: View {
  @Environment(ConnectivityStore.self) private var store

  /// The iPhone app can recolor the watch UI through `updateApplicationContext({ accent: "#RRGGBB" })`.
  private var accent: Color {
    (store.applicationContext["accent"] as? String).flatMap(Color.init(hex:)) ?? .accentColor
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          StatusRow(isReachable: store.isReachable, activationState: store.activationState)
        }

        Section("Messages") {
          ActionButton("Send message", systemImage: "paperplane.fill", action: store.sendMessage)
          ActionButton("Send, no reply", systemImage: "paperplane", action: store.sendMessageWithoutReply)
          ActionButton("Send data", systemImage: "shippingbox.fill", action: store.sendDataMessage)
        }

        Section("Background transfers") {
          ActionButton("App context", systemImage: "arrow.triangle.2.circlepath", action: store.updateApplicationContext)
          ActionButton("User info", systemImage: "person.crop.circle", action: store.transferUserInfo)
          ActionButton("Send file", systemImage: "doc.fill", action: store.transferFile)
        }

        Section {
          if store.activity.isEmpty {
            Text("Nothing yet. Send something from either device.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          } else {
            ForEach(store.activity) { entry in
              ActivityRow(entry: entry)
            }
          }
        } header: {
          HStack {
            Text("Activity")
            Spacer()
            if !store.activity.isEmpty {
              Button("Clear", action: store.clearActivity)
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(accent)
            }
          }
        }
      }
      .navigationTitle("Watch Connect")
    }
    .tint(accent)
  }
}

private struct StatusRow: View {
  let isReachable: Bool
  let activationState: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: isReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
        .font(.title3)
        .foregroundStyle(isReachable ? .green : .orange)
        .contentTransition(.symbolEffect(.replace))
      VStack(alignment: .leading, spacing: 2) {
        Text(isReachable ? "iPhone reachable" : "iPhone not reachable")
          .font(.headline)
        Text("Session \(activationState)")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .animation(.default, value: isReachable)
  }
}

private struct ActionButton: View {
  let title: String
  let systemImage: String
  let action: () -> Void

  init(_ title: String, systemImage: String, action: @escaping () -> Void) {
    self.title = title
    self.systemImage = systemImage
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Label {
        Text(title)
      } icon: {
        Image(systemName: systemImage).foregroundStyle(.tint)
      }
    }
  }
}

private struct ActivityRow: View {
  let entry: ActivityEntry

  private var icon: (name: String, color: Color) {
    switch entry.direction {
    case .incoming: ("arrow.down.circle.fill", .green)
    case .outgoing: ("arrow.up.circle.fill", .blue)
    case .error: ("exclamationmark.triangle.fill", .orange)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: icon.name).foregroundStyle(icon.color)
        Text(entry.title).font(.footnote.weight(.semibold))
        Spacer(minLength: 0)
        Text(entry.date, style: .time)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Text(entry.detail)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(3)
    }
  }
}

private extension Color {
  init?(hex: String) {
    let cleaned = hex.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
    guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
    self.init(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}

#Preview {
  ContentView()
    .environment(ConnectivityStore())
}
