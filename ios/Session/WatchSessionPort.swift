//
//  WatchSessionPort.swift
//  RnWatchConnect
//
//  The seam between the Controller and WCSession. Foundation only: see docs/adr/0001.
//

import Foundation

/// Mirrors WCSession's activation states, as the strings the JS interface exposes.
enum WatchActivationState: String {
    case notActivated
    case inactive
    case activated
    case unknown
}

/// A raw WCSessionDelegate callback, translated into plain values by the adapter.
enum WatchSessionPortEvent {
    case activationCompleted(error: Error?)
    case becameInactive
    case deactivated
    case reachabilityChanged(isReachable: Bool)
    case watchStateChanged(isPaired: Bool, isWatchAppInstalled: Bool)
    case message([String: Any])
    case messageWithReply([String: Any], reply: ([String: Any]) -> Void)
    case messageData(Data)
    case messageDataWithReply(Data, reply: (Data) -> Void)
    case applicationContext([String: Any])
    case userInfo([String: Any])
    /// The file at `fileURL` is only valid until the event handler returns.
    case file(fileURL: URL, metadata: [String: Any]?)
    case userInfoTransferFinished(UserInfoTransferHandle, error: Error?)
    case fileTransferFinished(FileTransferHandle, error: Error?)
}

/// An outstanding User Info transfer. WCSessionUserInfoTransfer in production.
protocol UserInfoTransferHandle: AnyObject {
    var userInfo: [String: Any] { get }
    var isTransferring: Bool { get }
    func cancel()
}

/// An outstanding File Transfer. WCSessionFileTransfer in production.
protocol FileTransferHandle: AnyObject {
    var fileURL: URL { get }
    var metadata: [String: Any]? { get }
    var isTransferring: Bool { get }
    var progress: Progress { get }
    func cancel()
}

/// Low-level port over WCSession. Adapters forward each call with no logic of their own.
protocol WatchSessionPort: AnyObject {
    var isSupported: Bool { get }
    var isPaired: Bool { get }
    var isWatchAppInstalled: Bool { get }
    var isReachable: Bool { get }
    var activationState: WatchActivationState { get }
    var applicationContext: [String: Any] { get }
    var receivedApplicationContext: [String: Any] { get }
    var outstandingUserInfoTransfers: [UserInfoTransferHandle] { get }
    var outstandingFileTransfers: [FileTransferHandle] { get }

    /// Receives every delegate callback, on whatever queue WatchConnectivity uses.
    var onEvent: ((WatchSessionPortEvent) -> Void)? { get set }

    func activate()
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
    func sendMessageData(
        _ data: Data,
        replyHandler: ((Data) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )
    func updateApplicationContext(_ applicationContext: [String: Any]) throws
    func transferUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferHandle
    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> FileTransferHandle
}
