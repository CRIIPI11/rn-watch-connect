//
//  WCWatchSessionAdapter.swift
//  RnWatchConnect
//
//  The real WatchSessionPort adapter: forwards each call to WCSession.default and each
//  delegate callback to `onEvent`. Keep logic out of here (docs/adr/0001).
//

import Foundation
import WatchConnectivity

final class WCWatchSessionAdapter: NSObject, WatchSessionPort {
    private var session: WCSession { WCSession.default }

    var onEvent: ((WatchSessionPortEvent) -> Void)?

    var isSupported: Bool { WCSession.isSupported() }
    var isPaired: Bool { session.isPaired }
    var isWatchAppInstalled: Bool { session.isWatchAppInstalled }
    var isReachable: Bool { session.isReachable }
    var applicationContext: [String: Any] { session.applicationContext }
    var receivedApplicationContext: [String: Any] { session.receivedApplicationContext }

    var activationState: WatchActivationState {
        switch session.activationState {
        case .notActivated: return .notActivated
        case .inactive: return .inactive
        case .activated: return .activated
        @unknown default: return .unknown
        }
    }

    var outstandingUserInfoTransfers: [UserInfoTransferHandle] {
        session.outstandingUserInfoTransfers.map { $0 }
    }

    var outstandingFileTransfers: [FileTransferHandle] {
        session.outstandingFileTransfers.map { $0 }
    }

    func activate() {
        session.delegate = self
        session.activate()
    }

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func sendMessageData(
        _ data: Data,
        replyHandler: ((Data) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        session.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func updateApplicationContext(_ applicationContext: [String: Any]) throws {
        try session.updateApplicationContext(applicationContext)
    }

    func transferUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferHandle {
        session.transferUserInfo(userInfo)
    }

    func transferFile(_ fileURL: URL, metadata: [String: Any]?) -> FileTransferHandle {
        session.transferFile(fileURL, metadata: metadata)
    }
}

// MARK: - WCSessionDelegate

extension WCWatchSessionAdapter: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        onEvent?(.activationCompleted(error: error))
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        onEvent?(.becameInactive)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        onEvent?(.deactivated)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        onEvent?(.reachabilityChanged(isReachable: session.isReachable))
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        onEvent?(.watchStateChanged(isPaired: session.isPaired, isWatchAppInstalled: session.isWatchAppInstalled))
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        onEvent?(.message(message))
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        onEvent?(.messageWithReply(message, reply: replyHandler))
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        onEvent?(.messageData(messageData))
    }

    func session(
        _ session: WCSession,
        didReceiveMessageData messageData: Data,
        replyHandler: @escaping (Data) -> Void
    ) {
        onEvent?(.messageDataWithReply(messageData, reply: replyHandler))
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        onEvent?(.applicationContext(applicationContext))
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        onEvent?(.userInfo(userInfo))
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        onEvent?(.file(fileURL: file.fileURL, metadata: file.metadata))
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        onEvent?(.userInfoTransferFinished(userInfoTransfer, error: error))
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        onEvent?(.fileTransferFinished(fileTransfer, error: error))
    }
}

// MARK: - Transfer handles

extension WCSessionUserInfoTransfer: UserInfoTransferHandle {}

extension WCSessionFileTransfer: FileTransferHandle {
    var fileURL: URL { file.fileURL }
    var metadata: [String: Any]? { file.metadata }
}
