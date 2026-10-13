import XCTest
@testable import WatchSession

final class WatchTransfersTests: XCTestCase {
    private var port: FakeWatchSessionPort!
    private var transfers: WatchTransfers!

    override func setUp() {
        port = FakeWatchSessionPort()
        transfers = WatchTransfers(port: port)
    }

    private func makeFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("transfer-\(UUID().uuidString).txt")
        try "data".write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    // MARK: - User Info

    func testStartedUserInfoMatchesItsOutstandingSnapshot() {
        let started = transfers.startUserInfo(["score": 3])

        XCTAssertEqual(transfers.outstandingUserInfo, [started])
        XCTAssertTrue(started.isTransferring)
        XCTAssertEqual(started.userInfo["score"] as? Int, 3)
    }

    func testCancelUserInfo() throws {
        let first = transfers.startUserInfo([:])
        _ = transfers.startUserInfo([:])

        try transfers.cancelUserInfo(id: first.id)

        let fakes = port.outstandingUserInfoTransfers.compactMap { $0 as? FakeUserInfoTransfer }
        XCTAssertEqual(fakes.map(\.isCancelled), [true, false])
    }

    func testCancelUnknownUserInfoThrows() {
        XCTAssertThrowsError(try transfers.cancelUserInfo(id: "nope")) {
            XCTAssertEqual($0 as? UserInfoTransferError, .invalidTransferId)
        }
    }

    func testOutstandingUserInfoIsEmptyWhenNotSupported() {
        _ = transfers.startUserInfo([:])
        port.isSupported = false

        XCTAssertTrue(transfers.outstandingUserInfo.isEmpty)
    }

    // MARK: - Files

    func testStartedFileMatchesItsOutstandingSnapshot() throws {
        let url = try makeFile()

        let started = try transfers.startFile(url.absoluteString, metadata: ["kind": "log"])

        XCTAssertEqual(transfers.outstandingFiles, [started])
        XCTAssertTrue(started.isTransferring)
        XCTAssertEqual(started.fileURL, url)
        XCTAssertEqual(started.metadata["kind"] as? String, "log")
        XCTAssertEqual(started.progress.totalUnitCount, 100)
        XCTAssertEqual(started.progress.completedUnitCount, 0)
        XCTAssertEqual(started.progress.fractionCompleted, 0)
    }

    func testOutstandingFileReportsCurrentProgress() throws {
        let url = try makeFile()
        let started = try transfers.startFile(url.absoluteString, metadata: nil)
        let fake = try XCTUnwrap(port.outstandingFileTransfers.first as? FakeFileTransfer)
        fake.progress.completedUnitCount = 40

        let current = try XCTUnwrap(transfers.outstandingFiles.first)

        XCTAssertEqual(current.id, started.id)
        XCTAssertEqual(current.progress.completedUnitCount, 40)
        XCTAssertEqual(current.progress.fractionCompleted, 0.4)
        XCTAssertTrue(current.metadata.isEmpty)
    }

    func testStartFileWithAnInvalidURLThrows() {
        XCTAssertThrowsError(try transfers.startFile("", metadata: nil)) {
            XCTAssertEqual($0 as? FileTransferError, .invalidFileURL)
        }
        XCTAssertTrue(port.outstandingFileTransfers.isEmpty)
    }

    func testStartFileForAMissingFileThrows() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString)")

        XCTAssertThrowsError(try transfers.startFile(missing.absoluteString, metadata: nil)) {
            XCTAssertEqual($0 as? FileTransferError, .fileNotFound)
        }
        XCTAssertTrue(port.outstandingFileTransfers.isEmpty)
    }

    func testCancelFile() throws {
        let url = try makeFile()
        let started = try transfers.startFile(url.absoluteString, metadata: nil)

        try transfers.cancelFile(id: started.id)

        XCTAssertEqual((port.outstandingFileTransfers.first as? FakeFileTransfer)?.isCancelled, true)
    }

    func testCancelUnknownFileThrows() {
        XCTAssertThrowsError(try transfers.cancelFile(id: "nope")) {
            XCTAssertEqual($0 as? FileTransferError, .invalidTransferId)
        }
    }

    func testOutstandingFilesAreEmptyWhenNotSupported() throws {
        let url = try makeFile()
        _ = try transfers.startFile(url.absoluteString, metadata: nil)
        port.isSupported = false

        XCTAssertTrue(transfers.outstandingFiles.isEmpty)
    }

    // MARK: - Through the Controller

    func testControllerHandsTransfersToWatchTransfers() throws {
        let controller = WatchSessionController(port: port, queue: DispatchQueue(label: "WatchTransfersTests"))
        let url = try makeFile()

        let userInfo = controller.transferUserInfo(["a": 1])
        let file = try controller.transferFile(url.absoluteString, metadata: nil)

        XCTAssertEqual(controller.outstandingUserInfoTransfers, [userInfo])
        XCTAssertEqual(controller.outstandingFileTransfers, [file])
        try controller.cancelFileTransfer(id: file.id)
        try controller.cancelUserInfoTransfer(id: userInfo.id)
    }
}
