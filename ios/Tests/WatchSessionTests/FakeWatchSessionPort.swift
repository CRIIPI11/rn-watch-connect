import Foundation
@testable import WatchSession

/// In-memory adapter for WatchSessionPort. Tests set its state, read what was sent,
/// and push delegate callbacks with `simulate(_:)`.
final class FakeWatchSessionPort: WatchSessionPort {
    var isSupported = true
    var isPaired = true
    var isWatchAppInstalled = true
    var isReachable = true
    var activationState: WatchActivationState = .activated
    var applicationContext: [String: Any] = [:]
    var receivedApplicationContext: [String: Any] = [:]
    var outstandingUserInfoTransfers: [UserInfoTransferHandle] = []
    var outstandingFileTransfers: [FileTransferHandle] = []

    var onEvent: ((WatchSessionPortEvent) -> Void)?

    // MARK: - Recorded calls

    private(set) var activateCallCount = 0
    private(set) var sentMessages: [[String: Any]] = []
    private(set) var sentData: [Data] = []
    private(set) var lastMessageReplyHandler: (([String: Any]) -> Void)?
    private(set) var lastMessageErrorHandler: ((Error) -> Void)?
    private(set) var lastDataReplyHandler: ((Data) -> Void)?
    private(set) var lastDataErrorHandler: ((Error) -> Void)?
    private(set) var updatedApplicationContexts: [[String: Any]] = []

    /// Thrown by `updateApplicationContext` when set.
    var updateApplicationContextError: Error?

    func simulate(_ event: WatchSessionPortEvent) {
        onEvent?(event)
    }

    // MARK: - WatchSessionPort

    func activate() {
        activateCallCount += 1
    }

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        sentMessages.append(message)
        lastMessageReplyHandler = replyHandler
        lastMessageErrorHandler = errorHandler
    }

    func sendMessageData(
        _ data: Data,
        replyHandler: ((Data) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        sentData.append(data)
        lastDataReplyHandler = replyHandler
        lastDataErrorHandler = errorHandler
    }

    func updateApplicationContext(_ applicationContext: [String: Any]) throws {
        if let error = updateApplicationContextError { throw error }
        updatedApplicationContexts.append(applicationContext)
        self.applicationContext = applicationContext
    }

    func transferUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferHandle {
        let transfer = FakeUserInfoTransfer(userInfo: userInfo)
        outstandingUserInfoTransfers.append(transfer)
        return transfer
    }

    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> FileTransferHandle {
        let transfer = FakeFileTransfer(fileURL: fileURL, metadata: metadata)
        outstandingFileTransfers.append(transfer)
        return transfer
    }
}

final class FakeUserInfoTransfer: UserInfoTransferHandle {
    let userInfo: [String: Any]
    var isTransferring = true
    private(set) var isCancelled = false

    init(userInfo: [String: Any]) {
        self.userInfo = userInfo
    }

    func cancel() {
        isCancelled = true
    }
}

final class FakeFileTransfer: FileTransferHandle {
    let fileURL: URL
    let metadata: [String: Any]?
    var isTransferring = true
    let progress = Progress(totalUnitCount: 100)
    private(set) var isCancelled = false

    init(fileURL: URL, metadata: [String: Any]?) {
        self.fileURL = fileURL
        self.metadata = metadata
    }

    func cancel() {
        isCancelled = true
    }
}
