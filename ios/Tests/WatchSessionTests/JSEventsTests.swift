import XCTest
@testable import WatchSession

/// The JS contract: each expectation here mirrors src/RnWatchConnect.types.ts.
/// If a test fails, either the Swift side drifted or the TS types need the same change.
final class JSEventsTests: XCTestCase {
    private let userInfoTransfer = UserInfoTransferSnapshot(id: "u1", isTransferring: true, userInfo: ["a": 1])
    private let fileTransfer = FileTransferSnapshot(
        id: "f1",
        isTransferring: false,
        progress: TransferProgress({ let p = Progress(totalUnitCount: 10); p.completedUnitCount = 4; return p }()),
        fileURL: URL(fileURLWithPath: "/tmp/a.txt"),
        metadata: ["name": "a.txt"]
    )

    private func assertEvent(
        _ event: SessionEvent,
        name: String,
        keys: Set<String>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let jsEvent = JSEvents.event(for: event)
        XCTAssertEqual(jsEvent.name, name, file: file, line: line)
        XCTAssertEqual(Set(jsEvent.body.keys), keys, "payload keys of \(name)", file: file, line: line)
        XCTAssertTrue(JSEvents.names.contains(name), "\(name) is missing from JSEvents.names", file: file, line: line)
    }

    // MARK: - Status (RnWatchConnectModuleEvents)

    func testStatusEvents() {
        assertEvent(.pairedChanged(true), name: "onWatchPairedChanged", keys: ["isWatchPaired"])
        assertEvent(.watchAppInstalledChanged(true), name: "onWatchAppInstallChanged", keys: ["isWatchAppInstalled"])
        assertEvent(.reachabilityChanged(false), name: "onReachabilityChanged", keys: ["isWatchReachable"])
    }

    // MARK: - Messages

    func testMessageEventsPassTheDictionaryThrough() {
        assertEvent(.message(["text": "hi"]), name: "onMessageReceived", keys: ["text"])
        assertEvent(.applicationContext(["theme": "dark"]), name: "onApplicationContextChanged", keys: ["theme"])
        assertEvent(.userInfo(["score": 3]), name: "onUserInfoReceived", keys: ["score"])
    }

    func testMessagesWithReply() {
        assertEvent(.messageWithReply(["q": 1], replyId: "r"), name: "onMessageWithReply", keys: ["message", "replyId"])
        assertEvent(.dataMessage(Data([1])), name: "onDataMessageReceived", keys: ["data"])
        assertEvent(.dataMessageWithReply(Data([1]), replyId: "r"), name: "onDataMessageWithReply", keys: ["data", "replyId"])
    }

    func testDataIsSentAsBase64() {
        let body = JSEvents.event(for: .dataMessage(Data([0xFF, 0x00]))).body
        XCTAssertEqual(body["data"] as? String, "/wA=")
    }

    // MARK: - Files and Transfers

    func testFileReceived() {
        assertEvent(
            .fileReceived(fileURL: URL(fileURLWithPath: "/tmp/a.txt"), metadata: [:]),
            name: "onFileReceived",
            keys: ["fileURL", "metadata"]
        )
    }

    func testUserInfoTransferShape() {
        XCTAssertEqual(Set(JSEvents.value(userInfoTransfer).keys), ["id", "isTransferring", "userInfo"])
    }

    func testFileTransferShape() {
        let value = JSEvents.value(fileTransfer)
        XCTAssertEqual(Set(value.keys), ["id", "isTransferring", "progress", "file"])
        XCTAssertEqual(Set((value["progress"] as? [String: Any])?.keys ?? [:].keys), ["fractionCompleted", "completedUnitCount", "totalUnitCount"])
        XCTAssertEqual(Set((value["file"] as? [String: Any])?.keys ?? [:].keys), ["fileURL", "metadata"])
    }

    func testFinishEventsAddErrorToTheTransferShape() {
        assertEvent(
            .userInfoTransferFinished(userInfoTransfer, error: nil),
            name: "onUserInfoTransferFinished",
            keys: ["id", "isTransferring", "userInfo", "error"]
        )
        assertEvent(
            .fileTransferFinished(fileTransfer, error: TransferError.cancelled),
            name: "onFileTransferFinished",
            keys: ["id", "isTransferring", "progress", "file", "error"]
        )
    }

    func testFinishErrorIsNullOrMessage() {
        let delivered = JSEvents.event(for: .fileTransferFinished(fileTransfer, error: nil)).body
        XCTAssertTrue(delivered["error"] is NSNull)

        let cancelled = JSEvents.event(for: .fileTransferFinished(fileTransfer, error: TransferError.cancelled)).body
        XCTAssertEqual((cancelled["error"] as? [String: Any])?["message"] as? String, "Transfer cancelled")
    }

    // MARK: - Names

    func testNamesAreUnique() {
        XCTAssertEqual(Set(JSEvents.names).count, JSEvents.names.count)
        XCTAssertEqual(JSEvents.names.count, 12)
    }
}
