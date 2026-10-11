import XCTest
@testable import WatchSession

final class WatchSessionControllerOutboundTests: XCTestCase {
    private var port: FakeWatchSessionPort!
    private var controller: WatchSessionController!

    override func setUp() {
        port = FakeWatchSessionPort()
        controller = WatchSessionController(port: port, queue: DispatchQueue(label: "OutboundTests"))
    }

    private func assertNotReachable(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        guard case .watchNotReachable? = error as? WatchConnectivityError else {
            return XCTFail("expected watchNotReachable, got \(String(describing: error))", file: file, line: line)
        }
    }

    // MARK: - Messages

    func testMessageIsNotSentWhenTheWatchIsNotReachable() {
        port.isReachable = false
        var receivedError: Error?

        controller.sendMessage(["a": 1], replyHandler: { _ in XCTFail("no reply expected") }, errorHandler: { receivedError = $0 })

        assertNotReachable(receivedError)
        XCTAssertTrue(port.sentMessages.isEmpty)
    }

    func testMessageReplyAndErrorAreForwarded() {
        var replies: [[String: Any]] = []
        var errors: [Error] = []

        controller.sendMessage(["q": "ping"], replyHandler: { replies.append($0) }, errorHandler: { errors.append($0) })
        port.lastMessageReplyHandler?(["a": "pong"])
        port.lastMessageErrorHandler?(NSError(domain: "wc", code: 7))

        XCTAssertEqual(port.sentMessages.first?["q"] as? String, "ping")
        XCTAssertEqual(replies.first?["a"] as? String, "pong")
        XCTAssertEqual((errors.first as NSError?)?.code, 7)
    }

    func testMessageWithoutReply() throws {
        try controller.sendMessageWithoutReply(["a": 1])

        XCTAssertEqual(port.sentMessages.count, 1)
        XCTAssertNil(port.lastMessageReplyHandler)
    }

    func testMessageWithoutReplyThrowsWhenTheWatchIsNotReachable() {
        port.isReachable = false

        XCTAssertThrowsError(try controller.sendMessageWithoutReply(["a": 1])) { assertNotReachable($0) }
        XCTAssertTrue(port.sentMessages.isEmpty)
    }

    func testMessagesFailWhenNotSupported() {
        port.isSupported = false
        var receivedError: Error?

        controller.sendMessage([:], replyHandler: { _ in }, errorHandler: { receivedError = $0 })

        assertNotReachable(receivedError)
        XCTAssertTrue(port.sentMessages.isEmpty)
    }

    // MARK: - Data Messages

    func testDataMessageIsNotSentWhenTheWatchIsNotReachable() {
        port.isReachable = false
        var receivedError: Error?

        controller.sendDataMessage(Data([1]), replyHandler: { _ in XCTFail("no reply expected") }, errorHandler: { receivedError = $0 })

        assertNotReachable(receivedError)
        XCTAssertTrue(port.sentData.isEmpty)
    }

    func testDataMessageReplyAndErrorAreForwarded() {
        var replies: [Data] = []
        var errors: [Error] = []

        controller.sendDataMessage(Data([1]), replyHandler: { replies.append($0) }, errorHandler: { errors.append($0) })
        port.lastDataReplyHandler?(Data([2]))
        port.lastDataErrorHandler?(NSError(domain: "wc", code: 8))

        XCTAssertEqual(port.sentData, [Data([1])])
        XCTAssertEqual(replies, [Data([2])])
        XCTAssertEqual((errors.first as NSError?)?.code, 8)
    }

    func testDataMessageWithoutReply() throws {
        try controller.sendDataMessageWithoutReply(Data([3]))

        XCTAssertEqual(port.sentData, [Data([3])])
        XCTAssertNil(port.lastDataReplyHandler)
    }

    func testDataMessageWithoutReplyThrowsWhenTheWatchIsNotReachable() {
        port.isReachable = false

        XCTAssertThrowsError(try controller.sendDataMessageWithoutReply(Data([3]))) { assertNotReachable($0) }
        XCTAssertTrue(port.sentData.isEmpty)
    }

    // MARK: - Application Context

    func testUpdateApplicationContext() throws {
        try controller.updateApplicationContext(["theme": "dark"])

        XCTAssertEqual(port.updatedApplicationContexts.first?["theme"] as? String, "dark")
        XCTAssertEqual(controller.applicationContext["theme"] as? String, "dark")
    }

    func testUpdateApplicationContextErrorIsThrown() {
        port.updateApplicationContextError = NSError(domain: "wc", code: 9)

        XCTAssertThrowsError(try controller.updateApplicationContext([:])) {
            XCTAssertEqual(($0 as NSError).code, 9)
        }
    }

    func testReceivedApplicationContext() {
        port.receivedApplicationContext = ["from": "watch"]

        XCTAssertEqual(controller.receivedApplicationContext["from"] as? String, "watch")
    }

    func testApplicationContextIsEmptyWhenNotSupported() {
        port.applicationContext = ["a": 1]
        port.receivedApplicationContext = ["b": 2]
        port.isSupported = false

        XCTAssertTrue(controller.applicationContext.isEmpty)
        XCTAssertTrue(controller.receivedApplicationContext.isEmpty)
    }

    // MARK: - User Info

    func testUserInfoTransferSnapshotMatchesItsOutstandingEntry() throws {
        let snapshot = controller.transferUserInfo(["score": 3])

        let outstanding = controller.outstandingUserInfoTransfers
        XCTAssertEqual(outstanding.count, 1)
        XCTAssertEqual(snapshot["id"] as? String, outstanding[0]["id"] as? String)
        XCTAssertEqual(snapshot["isTransferring"] as? Bool, true)
        XCTAssertEqual((outstanding[0]["userInfo"] as? [String: Any])?["score"] as? Int, 3)
        XCTAssertEqual(outstanding[0]["isTransferring"] as? Bool, true)
    }

    func testCancelUserInfoTransfer() throws {
        let id = try XCTUnwrap(controller.transferUserInfo([:])["id"] as? String)
        _ = controller.transferUserInfo([:])

        let result = try controller.cancelUserInfoTransfer(id: id)

        XCTAssertEqual(result["id"] as? String, id)
        let fakes = port.outstandingUserInfoTransfers.compactMap { $0 as? FakeUserInfoTransfer }
        XCTAssertEqual(fakes.map(\.isCancelled), [true, false])
    }

    func testCancelUnknownUserInfoTransferThrows() {
        XCTAssertThrowsError(try controller.cancelUserInfoTransfer(id: "nope")) {
            XCTAssertEqual($0 as? UserInfoTransferError, .invalidTransferId)
        }
    }

    func testOutstandingUserInfoTransfersAreEmptyWhenNotSupported() {
        _ = controller.transferUserInfo([:])
        port.isSupported = false

        XCTAssertTrue(controller.outstandingUserInfoTransfers.isEmpty)
    }

    // MARK: - File Transfers

    private func makeFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("outbound-\(UUID().uuidString).txt")
        try "data".write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testTransferFileSnapshot() throws {
        let url = try makeFile()

        let snapshot = try controller.transferFile(url.absoluteString, metadata: ["kind": "log"])

        XCTAssertNotNil(snapshot["id"] as? String)
        XCTAssertEqual(snapshot["isTransferring"] as? Bool, true)
        let progress = try XCTUnwrap(snapshot["progress"] as? [String: Any])
        // The keys this call has always returned (unified later in the Transfers follow-up).
        XCTAssertEqual(progress["total"] as? Int64, 100)
        XCTAssertEqual(progress["completed"] as? Int64, 0)
        XCTAssertEqual(progress["fractionCompleted"] as? Double, 0)
        let file = try XCTUnwrap(snapshot["file"] as? [String: Any])
        XCTAssertEqual(file["fileURL"] as? String, url.absoluteString)
        XCTAssertEqual((file["metadata"] as? [String: Any])?["kind"] as? String, "log")
    }

    func testTransferFileWithAnInvalidURLThrows() {
        XCTAssertThrowsError(try controller.transferFile("", metadata: nil)) {
            XCTAssertEqual($0 as? FileTransferError, .invalidFileURL)
        }
        XCTAssertTrue(port.outstandingFileTransfers.isEmpty)
    }

    func testTransferFileForAMissingFileThrows() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString)")

        XCTAssertThrowsError(try controller.transferFile(missing.absoluteString, metadata: nil)) {
            XCTAssertEqual($0 as? FileTransferError, .fileNotFound)
        }
        XCTAssertTrue(port.outstandingFileTransfers.isEmpty)
    }

    func testOutstandingFileTransferSnapshot() throws {
        let url = try makeFile()
        let id = try XCTUnwrap(try controller.transferFile(url.absoluteString, metadata: nil)["id"] as? String)
        let fake = try XCTUnwrap(port.outstandingFileTransfers.first as? FakeFileTransfer)
        fake.progress.completedUnitCount = 40

        let outstanding = controller.outstandingFileTransfers

        XCTAssertEqual(outstanding.count, 1)
        XCTAssertEqual(outstanding[0]["id"] as? String, id)
        let progress = try XCTUnwrap(outstanding[0]["progress"] as? [String: Any])
        XCTAssertEqual(progress["fractionCompleted"] as? Double, 0.4)
        XCTAssertEqual(progress["completedUnitCount"] as? Int64, 40)
        XCTAssertEqual(progress["totalUnitCount"] as? Int64, 100)
        let file = try XCTUnwrap(outstanding[0]["file"] as? [String: Any])
        XCTAssertEqual(file["fileURL"] as? String, url.absoluteString)
        XCTAssertTrue((file["metadata"] as? [String: Any])?.isEmpty ?? false)
    }

    func testCancelFileTransfer() throws {
        let url = try makeFile()
        let id = try XCTUnwrap(try controller.transferFile(url.absoluteString, metadata: nil)["id"] as? String)

        let result = try controller.cancelFileTransfer(id: id)

        XCTAssertEqual(result["id"] as? String, id)
        XCTAssertEqual((port.outstandingFileTransfers.first as? FakeFileTransfer)?.isCancelled, true)
    }

    func testCancelUnknownFileTransferThrows() {
        XCTAssertThrowsError(try controller.cancelFileTransfer(id: "nope")) {
            XCTAssertEqual($0 as? FileTransferError, .invalidTransferId)
        }
    }

    func testOutstandingFileTransfersAreEmptyWhenNotSupported() throws {
        let url = try makeFile()
        _ = try controller.transferFile(url.absoluteString, metadata: nil)
        port.isSupported = false

        XCTAssertTrue(controller.outstandingFileTransfers.isEmpty)
    }
}
