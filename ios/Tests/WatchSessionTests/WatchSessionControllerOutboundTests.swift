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
}
