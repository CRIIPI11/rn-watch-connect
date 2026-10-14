//
//  SessionEvent.swift
//  RnWatchConnect
//

import Foundation

/// Something that happened on the Session, as the Controller reports it to the Expo Module.
enum SessionEvent {
    case pairedChanged(Bool)
    case watchAppInstalledChanged(Bool)
    case reachabilityChanged(Bool)
    case message([String: Any])
    case messageWithReply([String: Any], replyId: String)
    case dataMessage(Data)
    case dataMessageWithReply(Data, replyId: String)
    case applicationContext([String: Any])
    case userInfo([String: Any])
    /// `fileURL` points at the staged file, which the app now owns.
    case fileReceived(fileURL: URL, metadata: [String: Any])
    /// Sent exactly once per Transfer. `error` is nil when the Transfer was delivered.
    case userInfoTransferFinished(UserInfoTransferSnapshot, error: Error?)
    /// Sent exactly once per Transfer. `error` is nil when the Transfer was delivered.
    case fileTransferFinished(FileTransferSnapshot, error: Error?)
}
