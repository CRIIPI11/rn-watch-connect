import Foundation
import Observation
import WatchConnectivity

/// A single entry in the watch's activity feed.
struct ActivityEntry: Identifiable {
  enum Direction { case incoming, outgoing, error }

  let id = UUID()
  let date = Date()
  let direction: Direction
  let title: String
  let detail: String
}

/// Owns the watch-side `WCSession` and mirrors everything the iPhone example app can send.
///
/// Message contract shared with `example/App.tsx`:
/// - Messages are `["text": String]`; replies are `["reply": String]`.
/// - Data messages are UTF-8 encoded strings.
/// - Application context from the iPhone carries `["accent": "#RRGGBB", "updatedAt": Double]`.
@MainActor
@Observable
final class ConnectivityStore: NSObject {
  private(set) var isReachable = false
  private(set) var activationState = "notActivated"
  private(set) var applicationContext: [String: Any] = [:]
  private(set) var activity: [ActivityEntry] = []

  private var session: WCSession? { WCSession.isSupported() ? .default : nil }

  override init() {
    super.init()
    guard let session else { return }
    session.delegate = self
    session.activate()
  }

  // MARK: - Outgoing

  func sendMessage() {
    let text = "Hello from the watch 👋"
    guard requireReachable() else { return }
    log(.outgoing, "Message", text)
    session?.sendMessage(["text": text]) { reply in
      Task { @MainActor in
        self.log(.incoming, "Reply", reply["reply"] as? String ?? "\(reply)")
      }
    } errorHandler: { error in
      Task { @MainActor in self.log(.error, "Message failed", error.localizedDescription) }
    }
  }

  func sendMessageWithoutReply() {
    let text = "Fire-and-forget from the watch"
    guard requireReachable() else { return }
    log(.outgoing, "Message (no reply)", text)
    session?.sendMessage(["text": text], replyHandler: nil) { error in
      Task { @MainActor in self.log(.error, "Message failed", error.localizedDescription) }
    }
  }

  func sendDataMessage() {
    let text = "Data from the watch 📦"
    guard requireReachable() else { return }
    log(.outgoing, "Data", text)
    session?.sendMessageData(Data(text.utf8)) { data in
      Task { @MainActor in
        self.log(.incoming, "Data reply", String(decoding: data, as: UTF8.self))
      }
    } errorHandler: { error in
      Task { @MainActor in self.log(.error, "Data failed", error.localizedDescription) }
    }
  }

  func updateApplicationContext() {
    let context: [String: Any] = ["source": "watch", "updatedAt": Date().timeIntervalSince1970 * 1000]
    do {
      try session?.updateApplicationContext(context)
      log(.outgoing, "App context", describe(context))
    } catch {
      log(.error, "App context failed", error.localizedDescription)
    }
  }

  func transferUserInfo() {
    let info: [String: Any] = ["from": "watch", "steps": Int.random(in: 1_000...12_000)]
    session?.transferUserInfo(info)
    log(.outgoing, "User info", describe(info))
  }

  func transferFile() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("from-watch.txt")
    let contents = "Hello from Apple Watch ⌚️ — \(Date().formatted(date: .omitted, time: .standard))"
    do {
      try contents.write(to: url, atomically: true, encoding: .utf8)
      session?.transferFile(url, metadata: ["name": "from-watch.txt", "size": contents.utf8.count])
      log(.outgoing, "File", "from-watch.txt")
    } catch {
      log(.error, "File failed", error.localizedDescription)
    }
  }

  func clearActivity() {
    activity.removeAll()
  }

  // MARK: - Helpers

  private func requireReachable() -> Bool {
    if session?.isReachable == true { return true }
    log(.error, "iPhone not reachable", "Open the example app on your iPhone.")
    return false
  }

  fileprivate func log(_ direction: ActivityEntry.Direction, _ title: String, _ detail: String) {
    activity.insert(ActivityEntry(direction: direction, title: title, detail: detail), at: 0)
    if activity.count > 30 { activity.removeLast() }
  }

  fileprivate func refresh(from session: WCSession) {
    isReachable = session.isReachable
    activationState = switch session.activationState {
    case .activated: "activated"
    case .inactive: "inactive"
    case .notActivated: "notActivated"
    @unknown default: "unknown"
    }
  }
}

func describe(_ dictionary: [String: Any]) -> String {
  dictionary
    .sorted { $0.key < $1.key }
    .map { "\($0.key): \($0.value)" }
    .joined(separator: ", ")
}

// MARK: - WCSessionDelegate

extension ConnectivityStore: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    let context = session.receivedApplicationContext
    Task { @MainActor in
      self.refresh(from: session)
      if !context.isEmpty { self.applicationContext = context }
      if let error { self.log(.error, "Activation failed", error.localizedDescription) }
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in self.refresh(from: session) }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    let text = message["text"] as? String ?? describe(message)
    Task { @MainActor in self.log(.incoming, "Message", text) }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    let text = message["text"] as? String ?? describe(message)
    replyHandler(["reply": "Watch got: \(text)"])
    Task { @MainActor in self.log(.incoming, "Message (replied)", text) }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    let text = String(decoding: messageData, as: UTF8.self)
    Task { @MainActor in self.log(.incoming, "Data", text) }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessageData messageData: Data,
    replyHandler: @escaping (Data) -> Void
  ) {
    let text = String(decoding: messageData, as: UTF8.self)
    replyHandler(Data("Watch got \(messageData.count) bytes ✅".utf8))
    Task { @MainActor in self.log(.incoming, "Data (replied)", text) }
  }

  nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    let text = describe(applicationContext)
    Task { @MainActor in
      self.applicationContext = applicationContext
      self.log(.incoming, "App context", text)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    let text = describe(userInfo)
    Task { @MainActor in self.log(.incoming, "User info", text) }
  }

  nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
    // The system deletes `file.fileURL` once this method returns, so read what we need now.
    let name = file.metadata?["name"] as? String ?? file.fileURL.lastPathComponent
    let size = (try? FileManager.default.attributesOfItem(atPath: file.fileURL.path)[.size] as? Int) ?? 0
    let formatted = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    Task { @MainActor in self.log(.incoming, "File", "\(name) · \(formatted)") }
  }
}
