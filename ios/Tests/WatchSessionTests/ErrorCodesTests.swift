import XCTest
@testable import WatchSession

/// The Error codes JS matches on. Each expectation mirrors the docs site's Error codes page
/// (https://rn-watch-connect.vercel.app/docs/errors) and
/// `WatchConnectErrorCode` in src/RnWatchConnect.types.ts.
final class ErrorCodesTests: XCTestCase {
    private func wcError(_ number: Int) -> NSError {
        NSError(domain: "WCErrorDomain", code: number)
    }

    func testOwnErrors() {
        XCTAssertEqual(ErrorCodes.code(for: WatchConnectivityError.watchNotReachable), "ERR_WATCH_NOT_REACHABLE")
        XCTAssertEqual(ErrorCodes.code(for: MessageError.invalidReplyId), "ERR_REPLY_NOT_PENDING")
        XCTAssertEqual(ErrorCodes.code(for: UserInfoTransferError.invalidTransferId), "ERR_INVALID_TRANSFER_ID")
        XCTAssertEqual(ErrorCodes.code(for: FileTransferError.invalidTransferId), "ERR_INVALID_TRANSFER_ID")
        XCTAssertEqual(ErrorCodes.code(for: FileTransferError.invalidFileURL), "ERR_INVALID_FILE_URL")
        XCTAssertEqual(ErrorCodes.code(for: FileTransferError.fileNotFound), "ERR_FILE_NOT_FOUND")
        XCTAssertEqual(ErrorCodes.code(for: TransferError.cancelled), "ERR_TRANSFER_CANCELLED")
    }

    func testEveryBase64ErrorSharesOneCode() {
        let errors: [MessageError] = [.invalidBase64Format, .invalidBase64Length, .invalidBase64Padding, .invalidBase64Decoding]
        XCTAssertEqual(Set(errors.map(ErrorCodes.code(for:))), ["ERR_INVALID_BASE64"])
    }

    /// WCErrorCode 7001–7019, from WatchConnectivity/WCError.h.
    func testEveryWatchConnectivityError() {
        let expected = [
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
        for (number, code) in expected {
            XCTAssertEqual(ErrorCodes.code(for: wcError(number)), code, "WCError \(number)")
        }
    }

    func testUnknownErrorsAreUnexpected() {
        XCTAssertEqual(ErrorCodes.code(for: wcError(7999)), "ERR_UNEXPECTED", "a future WCError case")
        XCTAssertEqual(ErrorCodes.code(for: NSError(domain: "Other", code: 7007)), "ERR_UNEXPECTED", "same number, other domain")
        XCTAssertEqual(ErrorCodes.code(for: CocoaError(.fileWriteOutOfSpace)), "ERR_UNEXPECTED", "only Received files map disk errors")
    }

    func testReceivedFileErrors() {
        XCTAssertEqual(ErrorCodes.receivedFileCode(for: CocoaError(.fileWriteOutOfSpace)), "ERR_INSUFFICIENT_SPACE")
        XCTAssertEqual(ErrorCodes.receivedFileCode(for: NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))), "ERR_INSUFFICIENT_SPACE")
        XCTAssertEqual(ErrorCodes.receivedFileCode(for: CocoaError(.fileNoSuchFile)), "ERR_FILE_RECEIVE_FAILED")
    }

    /// `ErrorCodes.all` is what src/__tests__ compares with the TypeScript list.
    func testAllListsEveryCodeSwiftCanProduce() {
        var produced: Set<String> = [ErrorCodes.unexpected, "ERR_FILE_RECEIVE_FAILED"]
        produced.insert(ErrorCodes.code(for: WatchConnectivityError.watchNotReachable))
        produced.insert(ErrorCodes.code(for: MessageError.invalidReplyId))
        produced.insert(ErrorCodes.code(for: MessageError.invalidBase64Format))
        produced.insert(ErrorCodes.code(for: FileTransferError.invalidTransferId))
        produced.insert(ErrorCodes.code(for: FileTransferError.invalidFileURL))
        produced.insert(ErrorCodes.code(for: FileTransferError.fileNotFound))
        produced.insert(ErrorCodes.code(for: TransferError.cancelled))
        for number in 7001...7019 { produced.insert(ErrorCodes.code(for: wcError(number))) }

        XCTAssertEqual(Set(ErrorCodes.all), produced)
        XCTAssertEqual(Set(ErrorCodes.all).count, ErrorCodes.all.count, "no duplicates")
    }
}
