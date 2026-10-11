//
//  WatchSessionController.swift
//  RnWatchConnect
//
//  Owns all Session behaviour behind the WatchSessionPort. Foundation only: see docs/adr/0001.
//

import Foundation

final class WatchSessionController {
    let port: WatchSessionPort
    private let queue: DispatchQueue
    private let queueKey = DispatchSpecificKey<Void>()
    private let stagingDirectory: URL
    private let fileManager = FileManager.default

    /// Receives every SessionEvent, on `queue`. Nothing is replayed to a handler set later.
    var onEvent: ((SessionEvent) -> Void)?

    // Pending Replies, keyed by Reply id. Only touched on `queue`.
    private var pendingReplies: [String: ([String: Any]) -> Void] = [:]
    private var pendingDataReplies: [String: (Data) -> Void] = [:]

    /// - Parameters:
    ///   - queue: serial queue for inbound work and pending-Reply state.
    ///   - stagingDirectory: where Received files are copied before they are reported.
    init(
        port: WatchSessionPort,
        queue: DispatchQueue = .main,
        stagingDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.port = port
        self.queue = queue
        self.stagingDirectory = stagingDirectory
        queue.setSpecific(key: queueKey, value: ())
        port.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    // MARK: - Session state

    var isSupported: Bool { port.isSupported }
    var isPaired: Bool { isSupported && port.isPaired }
    var isWatchAppInstalled: Bool { isSupported && port.isWatchAppInstalled }
    var isReachable: Bool { isSupported && port.isReachable }
    var activationState: WatchActivationState { isSupported ? port.activationState : .unknown }

    /// Activates the Session. Does nothing on devices without WatchConnectivity support.
    func activate() {
        guard port.isSupported else { return }
        port.activate()
    }

    // MARK: - Replies

    func replyToMessage(replyId: String, reply: [String: Any]) throws {
        let replyHandler = try onQueue { () throws -> ([String: Any]) -> Void in
            guard let handler = pendingReplies.removeValue(forKey: replyId) else {
                throw MessageError.invalidReplyId
            }
            return handler
        }
        replyHandler(reply)
    }

    func replyToDataMessage(replyId: String, reply: Data) throws {
        let replyHandler = try onQueue { () throws -> (Data) -> Void in
            guard let handler = pendingDataReplies.removeValue(forKey: replyId) else {
                throw MessageError.invalidReplyId
            }
            return handler
        }
        replyHandler(reply)
    }

    /// Forgets every pending Reply. Later replies to their Reply ids throw `invalidReplyId`.
    func dropPendingReplies() {
        onQueue {
            pendingReplies.removeAll()
            pendingDataReplies.removeAll()
        }
    }

    // MARK: - Inbound

    private func handle(_ event: WatchSessionPortEvent) {
        // WatchConnectivity deletes a received file when its callback returns,
        // so the file is staged here, synchronously, before hopping queues.
        if case let .file(fileURL, metadata) = event {
            stageReceivedFile(at: fileURL, metadata: metadata ?? [:])
            return
        }
        queue.async { [weak self] in
            self?.process(event)
        }
    }

    private func process(_ event: WatchSessionPortEvent) {
        switch event {
        case let .activationCompleted(error):
            if let error {
                print("Session activation failed with error: \(error.localizedDescription)")
                return
            }
            emit(.pairedChanged(port.isPaired))
            emit(.watchAppInstalledChanged(port.isWatchAppInstalled))
            emit(.reachabilityChanged(port.isReachable))
        case .becameInactive:
            break
        case .deactivated:
            // The user switched to another Watch: activate again for the new one.
            port.activate()
        case let .reachabilityChanged(isReachable):
            emit(.reachabilityChanged(isReachable))
        case let .watchStateChanged(isPaired, isWatchAppInstalled):
            emit(.pairedChanged(isPaired))
            emit(.watchAppInstalledChanged(isWatchAppInstalled))
        case let .message(message):
            emit(.message(message))
        case let .messageWithReply(message, reply):
            let replyId = UUID().uuidString
            pendingReplies[replyId] = reply
            emit(.messageWithReply(message, replyId: replyId))
        case let .messageData(data):
            emit(.dataMessage(data))
        case let .messageDataWithReply(data, reply):
            let replyId = UUID().uuidString
            pendingDataReplies[replyId] = reply
            emit(.dataMessageWithReply(data, replyId: replyId))
        case let .applicationContext(applicationContext):
            emit(.applicationContext(applicationContext))
        case let .userInfo(userInfo):
            emit(.userInfo(userInfo))
        case .file:
            break // handled synchronously in handle(_:)
        }
    }

    private func stageReceivedFile(at fileURL: URL, metadata: [String: Any]) {
        let destinationURL = stagingDirectory.appendingPathComponent(fileURL.lastPathComponent)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: fileURL, to: destinationURL)
        } catch {
            print("Error handling received file: \(error.localizedDescription)")
            return
        }

        queue.async { [weak self] in
            self?.emit(.fileReceived(fileURL: destinationURL, metadata: metadata))
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("Error removing received file: \(error.localizedDescription)")
        }
    }

    private func emit(_ event: SessionEvent) {
        onEvent?(event)
    }

    /// Runs `work` on `queue`, without deadlocking when already on it.
    private func onQueue<T>(_ work: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return try work()
        }
        return try queue.sync(execute: work)
    }
}
