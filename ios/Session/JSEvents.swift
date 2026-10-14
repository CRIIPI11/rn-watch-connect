//
//  JSEvents.swift
//  RnWatchConnect
//
//  How Session values look on the JS side: event names, payload keys and Transfer shapes.
//  They must match src/RnWatchConnectNative.types.ts (the public types in src/RnWatchConnect.types.ts
//  add a `reply` function to the reply events); JSEventsTests and src/__tests__ check that.
//  Foundation only: see docs/adr/0001.
//

import Foundation

/// A SessionEvent as JS receives it.
struct JSEvent {
    let name: String
    let body: [String: Any]
}

enum JSEvents {
    /// Every event the module can send. Mirrors `EVENT_NAMES` in src/eventNames.ts.
    static let names: [String] = [
        "onWatchPairedChanged",
        "onWatchAppInstallChanged",
        "onReachabilityChanged",
        "onMessageReceived",
        "onMessageWithReply",
        "onDataMessageReceived",
        "onDataMessageWithReply",
        "onApplicationContextChanged",
        "onUserInfoReceived",
        "onFileReceived",
        "onFileReceiveFailed",
        "onUserInfoTransferFinished",
        "onFileTransferFinished",
    ]

    static func event(for event: SessionEvent) -> JSEvent {
        switch event {
        case let .pairedChanged(isPaired):
            return JSEvent(name: "onWatchPairedChanged", body: ["isWatchPaired": isPaired])
        case let .watchAppInstalledChanged(isInstalled):
            return JSEvent(name: "onWatchAppInstallChanged", body: ["isWatchAppInstalled": isInstalled])
        case let .reachabilityChanged(isReachable):
            return JSEvent(name: "onReachabilityChanged", body: ["isWatchReachable": isReachable])
        case let .message(message):
            return JSEvent(name: "onMessageReceived", body: message)
        case let .messageWithReply(message, replyId):
            return JSEvent(name: "onMessageWithReply", body: ["message": message, "replyId": replyId])
        case let .dataMessage(data):
            return JSEvent(name: "onDataMessageReceived", body: ["data": data.base64EncodedString()])
        case let .dataMessageWithReply(data, replyId):
            return JSEvent(name: "onDataMessageWithReply", body: ["data": data.base64EncodedString(), "replyId": replyId])
        case let .applicationContext(applicationContext):
            return JSEvent(name: "onApplicationContextChanged", body: applicationContext)
        case let .userInfo(userInfo):
            return JSEvent(name: "onUserInfoReceived", body: userInfo)
        case let .fileReceived(fileURL, metadata):
            return JSEvent(name: "onFileReceived", body: ["fileURL": fileURL.absoluteString, "metadata": metadata])
        case let .fileReceiveFailed(fileName, metadata, error):
            return JSEvent(name: "onFileReceiveFailed", body: [
                "message": error.localizedDescription,
                "code": ErrorCodes.receivedFileCode(for: error),
                "fileName": fileName,
                "metadata": metadata ?? NSNull(),
            ])
        case let .userInfoTransferFinished(transfer, error):
            return JSEvent(name: "onUserInfoTransferFinished", body: value(transfer).merging(errorValue(error)) { $1 })
        case let .fileTransferFinished(transfer, error):
            return JSEvent(name: "onFileTransferFinished", body: value(transfer).merging(errorValue(error)) { $1 })
        }
    }

    /// `OutstandingUserInfoTransfer` in RnWatchConnect.types.ts.
    static func value(_ transfer: UserInfoTransferSnapshot) -> [String: Any] {
        [
            "id": transfer.id,
            "isTransferring": transfer.isTransferring,
            "userInfo": transfer.userInfo,
        ]
    }

    /// `FileTransfer` in RnWatchConnect.types.ts.
    static func value(_ transfer: FileTransferSnapshot) -> [String: Any] {
        [
            "id": transfer.id,
            "isTransferring": transfer.isTransferring,
            "progress": [
                "fractionCompleted": transfer.progress.fractionCompleted,
                "completedUnitCount": transfer.progress.completedUnitCount,
                "totalUnitCount": transfer.progress.totalUnitCount,
            ],
            "file": [
                "fileURL": transfer.fileURL.absoluteString,
                "metadata": transfer.metadata,
            ],
        ]
    }

    /// `error` in a finish event: `{ message, code }`, or `null` when the Transfer was delivered.
    private static func errorValue(_ error: Error?) -> [String: Any] {
        ["error": error.map { ["message": $0.localizedDescription, "code": ErrorCodes.code(for: $0)] } ?? NSNull()]
    }
}
