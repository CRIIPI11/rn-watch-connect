import XCTest
@testable import WatchSession

final class WatchSessionControllerTests: XCTestCase {
    private var port: FakeWatchSessionPort!
    private var queue: DispatchQueue!
    private var stagingDirectory: URL!
    private var controller: WatchSessionController!
    private var events: [SessionEvent] = []

    override func setUpWithError() throws {
        port = FakeWatchSessionPort()
        queue = DispatchQueue(label: "WatchSessionControllerTests")
        stagingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WatchSessionControllerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        controller = WatchSessionController(port: port, queue: queue, stagingDirectory: stagingDirectory)
        events = []
        controller.onEvent = { [unowned self] in events.append($0) }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: stagingDirectory)
    }

    /// Simulates a delegate callback and waits until the Controller has processed it.
    private func receive(_ event: WatchSessionPortEvent) {
        port.simulate(event)
        queue.sync {}
    }

    // MARK: - Activation and state

    func testActivateActivatesTheSessionWhenSupported() {
        controller.activate()

        XCTAssertEqual(port.activateCallCount, 1)
    }

    func testActivateDoesNothingWhenNotSupported() {
        port.isSupported = false

        controller.activate()

        XCTAssertEqual(port.activateCallCount, 0)
    }

    func testStateIsReadLiveFromThePort() {
        port.isPaired = true
        port.isWatchAppInstalled = false
        port.isReachable = true
        port.activationState = .inactive

        XCTAssertTrue(controller.isPaired)
        XCTAssertFalse(controller.isWatchAppInstalled)
        XCTAssertTrue(controller.isReachable)
        XCTAssertEqual(controller.activationState, .inactive)

        port.isReachable = false
        XCTAssertFalse(controller.isReachable)
    }

    func testStateIsEmptyWhenNotSupported() {
        port.isSupported = false

        XCTAssertFalse(controller.isSupported)
        XCTAssertFalse(controller.isPaired)
        XCTAssertFalse(controller.isWatchAppInstalled)
        XCTAssertFalse(controller.isReachable)
        XCTAssertEqual(controller.activationState, .unknown)
    }

    func testActivationCompletedReportsCurrentStatus() {
        port.isPaired = true
        port.isWatchAppInstalled = false
        port.isReachable = true

        receive(.activationCompleted(error: nil))

        XCTAssertEqual(events.count, 3)
        guard case .pairedChanged(true) = events[0],
              case .watchAppInstalledChanged(false) = events[1],
              case .reachabilityChanged(true) = events[2]
        else { return XCTFail("unexpected events: \(events)") }
    }

    func testFailedActivationReportsNothing() {
        receive(.activationCompleted(error: NSError(domain: "test", code: 1)))

        XCTAssertTrue(events.isEmpty)
    }

    func testDeactivatedSessionIsActivatedAgain() {
        receive(.deactivated)

        XCTAssertEqual(port.activateCallCount, 1)
        XCTAssertTrue(events.isEmpty)
    }

    func testBecameInactiveReportsNothing() {
        receive(.becameInactive)

        XCTAssertTrue(events.isEmpty)
    }

    func testReachabilityChange() {
        receive(.reachabilityChanged(isReachable: false))

        guard case .reachabilityChanged(false) = events.single else {
            return XCTFail("unexpected events: \(events)")
        }
    }

    func testWatchStateChangeReportsPairedAndWatchAppInstalled() {
        receive(.watchStateChanged(isPaired: false, isWatchAppInstalled: true))

        XCTAssertEqual(events.count, 2)
        guard case .pairedChanged(false) = events[0],
              case .watchAppInstalledChanged(true) = events[1]
        else { return XCTFail("unexpected events: \(events)") }
    }

    // MARK: - Inbound payloads

    func testMessage() {
        receive(.message(["text": "hi"]))

        guard case let .message(message) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(message["text"] as? String, "hi")
    }

    func testDataMessage() {
        receive(.messageData(Data([1, 2, 3])))

        guard case let .dataMessage(data) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(data, Data([1, 2, 3]))
    }

    func testApplicationContext() {
        receive(.applicationContext(["theme": "dark"]))

        guard case let .applicationContext(context) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(context["theme"] as? String, "dark")
    }

    func testUserInfo() {
        receive(.userInfo(["score": 3]))

        guard case let .userInfo(userInfo) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(userInfo["score"] as? Int, 3)
    }

    func testNothingIsReplayedToAHandlerSetLater() {
        receive(.userInfo(["score": 3]))
        receive(.reachabilityChanged(isReachable: true))

        var lateEvents: [SessionEvent] = []
        controller.onEvent = { lateEvents.append($0) }
        queue.sync {}

        XCTAssertTrue(lateEvents.isEmpty)
    }

    // MARK: - Replies

    func testMessageWithReplyIsAnsweredThroughItsReplyId() throws {
        var replies: [[String: Any]] = []
        receive(.messageWithReply(["q": "ping"], reply: { replies.append($0) }))
        guard case let .messageWithReply(message, replyId) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(message["q"] as? String, "ping")

        try controller.replyToMessage(replyId: replyId, reply: ["a": "pong"])

        XCTAssertEqual(replies.count, 1)
        XCTAssertEqual(replies.first?["a"] as? String, "pong")
    }

    func testReplyIdCanOnlyBeUsedOnce() throws {
        receive(.messageWithReply([:], reply: { _ in }))
        guard case let .messageWithReply(_, replyId) = events.single else { return XCTFail("\(events)") }
        try controller.replyToMessage(replyId: replyId, reply: [:])

        XCTAssertThrowsError(try controller.replyToMessage(replyId: replyId, reply: [:])) {
            XCTAssertEqual($0 as? MessageError, .invalidReplyId)
        }
    }

    func testUnknownReplyIdThrows() {
        XCTAssertThrowsError(try controller.replyToMessage(replyId: "nope", reply: [:])) {
            XCTAssertEqual($0 as? MessageError, .invalidReplyId)
        }
        XCTAssertThrowsError(try controller.replyToDataMessage(replyId: "nope", reply: Data())) {
            XCTAssertEqual($0 as? MessageError, .invalidReplyId)
        }
    }

    func testEachMessageWithReplyGetsItsOwnReplyId() {
        receive(.messageWithReply([:], reply: { _ in }))
        receive(.messageWithReply([:], reply: { _ in }))

        guard case let .messageWithReply(_, first) = events[0],
              case let .messageWithReply(_, second) = events[1]
        else { return XCTFail("\(events)") }
        XCTAssertNotEqual(first, second)
    }

    func testDataMessageWithReplyIsAnsweredThroughItsReplyId() throws {
        var replies: [Data] = []
        receive(.messageDataWithReply(Data([9]), reply: { replies.append($0) }))
        guard case let .dataMessageWithReply(data, replyId) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(data, Data([9]))

        try controller.replyToDataMessage(replyId: replyId, reply: Data([7]))

        XCTAssertEqual(replies, [Data([7])])
    }

    func testDroppedPendingRepliesCanNoLongerBeAnswered() {
        var replied = false
        receive(.messageWithReply([:], reply: { _ in replied = true }))
        receive(.messageDataWithReply(Data(), reply: { _ in replied = true }))
        guard case let .messageWithReply(_, replyId) = events[0],
              case let .dataMessageWithReply(_, dataReplyId) = events[1]
        else { return XCTFail("\(events)") }

        controller.dropPendingReplies()

        XCTAssertThrowsError(try controller.replyToMessage(replyId: replyId, reply: [:]))
        XCTAssertThrowsError(try controller.replyToDataMessage(replyId: dataReplyId, reply: Data()))
        XCTAssertFalse(replied)
    }

    func testRepliesWorkWhenCalledOnTheControllerQueue() throws {
        receive(.messageWithReply([:], reply: { _ in }))
        guard case let .messageWithReply(_, replyId) = events.single else { return XCTFail("\(events)") }

        try queue.sync {
            try controller.replyToMessage(replyId: replyId, reply: [:])
        }
    }

    // MARK: - Received files

    private func makeIncomingFile(named name: String, contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("incoming-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testReceivedFileIsStagedAndTheOriginalDeleted() throws {
        let incoming = try makeIncomingFile(named: "photo.jpg", contents: "jpeg")

        receive(.file(fileURL: incoming, metadata: ["album": "trip"]))

        guard case let .fileReceived(fileURL, metadata) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(fileURL, stagingDirectory.appendingPathComponent("photo.jpg"))
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "jpeg")
        XCTAssertEqual(metadata["album"] as? String, "trip")
        XCTAssertFalse(FileManager.default.fileExists(atPath: incoming.path))
    }

    func testReceivedFileIsStagedBeforeTheCallbackReturns() throws {
        let incoming = try makeIncomingFile(named: "note.txt", contents: "x")

        port.simulate(.file(fileURL: incoming, metadata: nil))

        // No queue drain: the copy must already exist.
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: stagingDirectory.appendingPathComponent("note.txt").path))
    }

    func testReceivedFileOverwritesAStagedFileWithTheSameName() throws {
        try "old".write(to: stagingDirectory.appendingPathComponent("log.txt"), atomically: true, encoding: .utf8)
        let incoming = try makeIncomingFile(named: "log.txt", contents: "new")

        receive(.file(fileURL: incoming, metadata: nil))

        guard case let .fileReceived(fileURL, metadata) = events.single else { return XCTFail("\(events)") }
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "new")
        XCTAssertTrue(metadata.isEmpty)
    }

    func testReceivedFileThatCannotBeCopiedReportsNothing() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString)")

        receive(.file(fileURL: missing, metadata: nil))

        XCTAssertTrue(events.isEmpty)
    }
}

private extension Array {
    /// The only element, or nil when the array does not have exactly one.
    var single: Element? { count == 1 ? first : nil }
}
