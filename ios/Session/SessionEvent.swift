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
    /// `fileURL` points at the staged copy, which the app can read.
    case fileReceived(fileURL: URL, metadata: [String: Any])
}
