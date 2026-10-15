//
//  ErrorCodes.swift
//  RnWatchConnect
//
//  The Error code JS sees for each failure, thrown or in an event. Codes never change between
//  versions. They must match `WatchConnectErrorCode` in src/RnWatchConnect.types.ts;
//  ErrorCodesTests and src/__tests__ check that.
//  Foundation only: WatchConnectivity errors are matched by domain and number (docs/adr/0001).
//

import Foundation

enum ErrorCodes {
    /// Expo's code for an error it doesn't know. Also ours for errors we don't recognise.
    static let unexpected = "ERR_UNEXPECTED"

    /// Every code Swift can produce. Mirrors `ERROR_CODES` in src/errorCodes.ts.
    static let all: [String] = [
        "ERR_UNEXPECTED",
        "ERR_WATCH_NOT_REACHABLE",
        "ERR_REPLY_NOT_PENDING",
        "ERR_INVALID_BASE64",
        "ERR_INVALID_TRANSFER_ID",
        "ERR_INVALID_FILE_URL",
        "ERR_FILE_NOT_FOUND",
        "ERR_TRANSFER_CANCELLED",
        "ERR_FILE_RECEIVE_FAILED",
        "ERR_GENERIC_ERROR",
        "ERR_SESSION_NOT_SUPPORTED",
        "ERR_SESSION_MISSING_DELEGATE",
        "ERR_SESSION_NOT_ACTIVATED",
        "ERR_DEVICE_NOT_PAIRED",
        "ERR_WATCH_APP_NOT_INSTALLED",
        "ERR_INVALID_PARAMETER",
        "ERR_PAYLOAD_TOO_LARGE",
        "ERR_PAYLOAD_UNSUPPORTED_TYPES",
        "ERR_MESSAGE_REPLY_FAILED",
        "ERR_MESSAGE_REPLY_TIMED_OUT",
        "ERR_FILE_ACCESS_DENIED",
        "ERR_DELIVERY_FAILED",
        "ERR_INSUFFICIENT_SPACE",
        "ERR_SESSION_INACTIVE",
        "ERR_TRANSFER_TIMED_OUT",
        "ERR_COMPANION_APP_NOT_INSTALLED",
        "ERR_WATCH_ONLY_APP",
    ]

    /// `WCErrorDomain`. WatchConnectivity doesn't exist on macOS, where the Session tests run.
    private static let watchConnectivityDomain = "WCErrorDomain"

    /// WCErrorCode, from WatchConnectivity/WCError.h: `ERR_` plus Apple's name in snake case.
    /// `notReachable` shares our own code, so one failure has one code whoever detects it.
    private static let watchConnectivityCodes: [Int: String] = [
        7001: "ERR_GENERIC_ERROR",
        7002: "ERR_SESSION_NOT_SUPPORTED",
        7003: "ERR_SESSION_MISSING_DELEGATE",
        7004: "ERR_SESSION_NOT_ACTIVATED",
        7005: "ERR_DEVICE_NOT_PAIRED",
        7006: "ERR_WATCH_APP_NOT_INSTALLED",
        7007: "ERR_WATCH_NOT_REACHABLE",
        7008: "ERR_INVALID_PARAMETER",
        7009: "ERR_PAYLOAD_TOO_LARGE",
        7010: "ERR_PAYLOAD_UNSUPPORTED_TYPES",
        7011: "ERR_MESSAGE_REPLY_FAILED",
        7012: "ERR_MESSAGE_REPLY_TIMED_OUT",
        7013: "ERR_FILE_ACCESS_DENIED",
        7014: "ERR_DELIVERY_FAILED",
        7015: "ERR_INSUFFICIENT_SPACE",
        7016: "ERR_SESSION_INACTIVE",
        7017: "ERR_TRANSFER_TIMED_OUT",
        7018: "ERR_COMPANION_APP_NOT_INSTALLED",
        7019: "ERR_WATCH_ONLY_APP",
    ]

    static func code(for error: Error) -> String {
        switch error {
        case WatchConnectivityError.watchNotReachable:
            return "ERR_WATCH_NOT_REACHABLE"
        case let error as MessageError:
            return error == .invalidReplyId ? "ERR_REPLY_NOT_PENDING" : "ERR_INVALID_BASE64"
        case UserInfoTransferError.invalidTransferId, FileTransferError.invalidTransferId:
            return "ERR_INVALID_TRANSFER_ID"
        case FileTransferError.invalidFileURL:
            return "ERR_INVALID_FILE_URL"
        case FileTransferError.fileNotFound:
            return "ERR_FILE_NOT_FOUND"
        case TransferError.cancelled:
            return "ERR_TRANSFER_CANCELLED"
        default:
            let nsError = error as NSError
            guard nsError.domain == watchConnectivityDomain else { return unexpected }
            return watchConnectivityCodes[nsError.code] ?? unexpected
        }
    }

    /// The code for a Received file the library couldn't move out of WatchConnectivity's folder.
    static func receivedFileCode(for error: Error) -> String {
        let nsError = error as NSError
        let outOfSpace =
            (nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError)
            || (nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ENOSPC))
        return outOfSpace ? "ERR_INSUFFICIENT_SPACE" : "ERR_FILE_RECEIVE_FAILED"
    }
}
