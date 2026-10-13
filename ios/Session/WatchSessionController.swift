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
    private let transfers: WatchTransfers

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
        self.transfers = WatchTransfers(port: port)
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

    var applicationContext: [String: Any] { isSupported ? port.applicationContext : [:] }
    var receivedApplicationContext: [String: Any] { isSupported ? port.receivedApplicationContext : [:] }

    // MARK: - Messages

    /// Sends a Message and reports the Reply, or the error, through the handlers.
    /// Fails with `watchNotReachable`, without sending, when the Watch is not reachable.
    func sendMessage(
        _ message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        guard isReachable else {
            errorHandler(WatchConnectivityError.watchNotReachable)
            return
        }
        port.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func sendMessageWithoutReply(_ message: [String: Any]) throws {
        guard isReachable else { throw WatchConnectivityError.watchNotReachable }
        port.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    /// Sends a Data Message and reports the Reply, or the error, through the handlers.
    /// Fails with `watchNotReachable`, without sending, when the Watch is not reachable.
    func sendDataMessage(
        _ data: Data,
        replyHandler: @escaping (Data) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        guard isReachable else {
            errorHandler(WatchConnectivityError.watchNotReachable)
            return
        }
        port.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func sendDataMessageWithoutReply(_ data: Data) throws {
        guard isReachable else { throw WatchConnectivityError.watchNotReachable }
        port.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Application Context

    func updateApplicationContext(_ applicationContext: [String: Any]) throws {
        try port.updateApplicationContext(applicationContext)
    }

    // MARK: - Transfers

    // Every call runs on `queue`, where WatchTransfers keeps its Transfer registry.

    func transferUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferSnapshot {
        onQueue { transfers.startUserInfo(userInfo) }
    }

    var outstandingUserInfoTransfers: [UserInfoTransferSnapshot] {
        onQueue { transfers.outstandingUserInfo }
    }

    /// Cancels the Transfer and emits its finish event right away.
    func cancelUserInfoTransfer(id: String) throws {
        try onQueue { emit(try transfers.cancelUserInfo(id: id)) }
    }

    /// - Parameter file: a file URL string; the file must exist.
    func transferFile(_ file: String, metadata: [String: Any]?) throws -> FileTransferSnapshot {
        try onQueue { try transfers.startFile(file, metadata: metadata) }
    }

    var outstandingFileTransfers: [FileTransferSnapshot] {
        onQueue { transfers.outstandingFiles }
    }

    /// Cancels the Transfer and emits its finish event right away.
    func cancelFileTransfer(id: String) throws {
        try onQueue { emit(try transfers.cancelFile(id: id)) }
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
        case let .userInfoTransferFinished(handle, error):
            if let event = transfers.userInfoFinished(handle, error: error) { emit(event) }
        case let .fileTransferFinished(handle, error):
            if let event = transfers.fileFinished(handle, error: error) { emit(event) }
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
