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

        _ = try transfers.cancelUserInfo(id: first.id)

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

        _ = try transfers.cancelFile(id: started.id)

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

    // MARK: - Transfer ids

    private func startFile() throws -> (FileTransferSnapshot, FakeFileTransfer) {
        let url = try makeFile()
        let snapshot = try transfers.startFile(url.absoluteString, metadata: nil)
        let handle = try XCTUnwrap(port.outstandingFileTransfers.last as? FakeFileTransfer)
        return (snapshot, handle)
    }

    /// Like WatchConnectivity: the Transfer leaves the outstanding list before `didFinish`.
    private func deliver(_ handle: FakeFileTransfer, error: Error? = nil) -> SessionEvent? {
        port.outstandingFileTransfers.removeAll { $0 === handle }
        return transfers.fileFinished(handle, error: error)
    }

    func testIdsAreUUIDs() throws {
        let (file, _) = try startFile()
        let userInfo = transfers.startUserInfo([:])

        XCTAssertNotNil(UUID(uuidString: file.id))
        XCTAssertNotNil(UUID(uuidString: userInfo.id))
    }

    func testIdStaysTheSameAcrossReads() throws {
        let (started, _) = try startFile()

        XCTAssertEqual(transfers.outstandingFiles.map(\.id), [started.id])
        XCTAssertEqual(transfers.outstandingFiles.map(\.id), [started.id])
    }

    func testIdsAreNeverReusedAfterATransferFinishes() throws {
        var seen = Set<String>()
        for _ in 0..<50 {
            let (snapshot, handle) = try startFile()
            XCTAssertTrue(seen.insert(snapshot.id).inserted, "id \(snapshot.id) was reused")
            _ = deliver(handle)
        }
    }

    func testTransfersFromAnEarlierRunGetIdsWhenFirstListed() throws {
        let earlier = FakeFileTransfer(fileURL: URL(fileURLWithPath: "/tmp/earlier.bin"), metadata: nil)
        port.outstandingFileTransfers = [earlier]

        let id = try XCTUnwrap(transfers.outstandingFiles.first?.id)

        XCTAssertEqual(transfers.outstandingFiles.first?.id, id)
        _ = try transfers.cancelFile(id: id)
        XCTAssertTrue(earlier.isCancelled)
    }

    // MARK: - Finish events

    func testDeliveredTransferFinishesWithoutError() throws {
        let (started, handle) = try startFile()

        let event = deliver(handle)

        guard case let .fileTransferFinished(snapshot, error)? = event else { return XCTFail("\(String(describing: event))") }
        XCTAssertEqual(snapshot.id, started.id)
        XCTAssertNil(error)
    }

    func testFailedTransferFinishesWithItsError() throws {
        let (started, handle) = try startFile()

        let event = deliver(handle, error: NSError(domain: "WCErrorDomain", code: 7007))

        guard case let .fileTransferFinished(snapshot, error)? = event else { return XCTFail("\(String(describing: event))") }
        XCTAssertEqual(snapshot.id, started.id)
        XCTAssertEqual((error as NSError?)?.code, 7007)
    }

    func testCancelProducesTheFinishEventImmediately() throws {
        let (started, handle) = try startFile()

        let event = try transfers.cancelFile(id: started.id)

        guard case let .fileTransferFinished(snapshot, error) = event else { return XCTFail("\(event)") }
        XCTAssertEqual(snapshot.id, started.id)
        XCTAssertEqual(error as? TransferError, .cancelled)
        XCTAssertEqual(error?.localizedDescription, "Transfer cancelled")
        XCTAssertTrue(handle.isCancelled)
    }

    func testDidFinishAfterCancelIsIgnored() throws {
        let (started, handle) = try startFile()
        _ = try transfers.cancelFile(id: started.id)

        XCTAssertNil(deliver(handle, error: NSError(domain: "WCErrorDomain", code: 1)))
    }

    func testDidFinishAfterCancelIsIgnoredEvenAfterTheListWasRead() throws {
        let (started, handle) = try startFile()
        _ = try transfers.cancelFile(id: started.id)
        port.outstandingFileTransfers.removeAll { $0 === handle }
        _ = transfers.outstandingFiles

        XCTAssertNil(transfers.fileFinished(handle, error: nil))
    }

    func testCancelledTransferIsLeftOutOfTheOutstandingList() throws {
        let (started, _) = try startFile()
        let (other, _) = try startFile()

        _ = try transfers.cancelFile(id: started.id)

        XCTAssertEqual(transfers.outstandingFiles.map(\.id), [other.id])
    }

    func testCancellingTwiceThrows() throws {
        let (started, _) = try startFile()
        _ = try transfers.cancelFile(id: started.id)

        XCTAssertThrowsError(try transfers.cancelFile(id: started.id)) {
            XCTAssertEqual($0 as? FileTransferError, .invalidTransferId)
        }
    }

    func testLateCancelThrowsAndTheDeliveryIsStillReported() throws {
        let (started, handle) = try startFile()
        port.outstandingFileTransfers.removeAll { $0 === handle } // delivered, didFinish not yet processed

        XCTAssertThrowsError(try transfers.cancelFile(id: started.id)) {
            XCTAssertEqual($0 as? FileTransferError, .invalidTransferId)
        }
        guard case let .fileTransferFinished(snapshot, error)? = transfers.fileFinished(handle, error: nil) else {
            return XCTFail("expected a finish event")
        }
        XCTAssertEqual(snapshot.id, started.id)
        XCTAssertNil(error)
        XCTAssertFalse(handle.isCancelled)
    }

    func testDidFinishForATransferNeverSeenBefore() {
        let unknown = FakeFileTransfer(fileURL: URL(fileURLWithPath: "/tmp/unknown.bin"), metadata: ["name": "unknown"])

        guard case let .fileTransferFinished(snapshot, error)? = transfers.fileFinished(unknown, error: nil) else {
            return XCTFail("expected a finish event")
        }
        XCTAssertNotNil(UUID(uuidString: snapshot.id))
        XCTAssertEqual(snapshot.metadata["name"] as? String, "unknown")
        XCTAssertNil(error)
    }

    func testUserInfoFinishEvents() throws {
        let delivered = transfers.startUserInfo(["a": 1])
        let cancelled = transfers.startUserInfo(["b": 2])
        let deliveredHandle = try XCTUnwrap(port.outstandingUserInfoTransfers.first)
        let cancelledHandle = try XCTUnwrap(port.outstandingUserInfoTransfers.last)

        let cancelEvent = try transfers.cancelUserInfo(id: cancelled.id)
        port.outstandingUserInfoTransfers.removeAll()
        let deliveredEvent = transfers.userInfoFinished(deliveredHandle, error: nil)
        let lateEvent = transfers.userInfoFinished(cancelledHandle, error: nil)

        guard case let .userInfoTransferFinished(c, cError) = cancelEvent,
              case let .userInfoTransferFinished(d, dError)? = deliveredEvent
        else { return XCTFail("unexpected events") }
        XCTAssertEqual(c.id, cancelled.id)
        XCTAssertEqual(cError as? TransferError, .cancelled)
        XCTAssertEqual(d.id, delivered.id)
        XCTAssertEqual(d.userInfo["a"] as? Int, 1)
        XCTAssertNil(dError)
        XCTAssertNil(lateEvent)
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

    func testControllerEmitsExactlyOneFinishEventPerTransfer() throws {
        let queue = DispatchQueue(label: "WatchTransfersTests.controller")
        let controller = WatchSessionController(port: port, queue: queue)
        var finished: [(id: String, error: Error?)] = []
        controller.onEvent = { event in
            if case let .fileTransferFinished(snapshot, error) = event { finished.append((snapshot.id, error)) }
        }
        let delivered = try controller.transferFile(try makeFile().absoluteString, metadata: nil)
        let cancelled = try controller.transferFile(try makeFile().absoluteString, metadata: nil)
        let deliveredHandle = try XCTUnwrap(port.outstandingFileTransfers.first)
        let cancelledHandle = try XCTUnwrap(port.outstandingFileTransfers.last)

        try controller.cancelFileTransfer(id: cancelled.id)
        XCTAssertEqual(finished.map(\.id), [cancelled.id], "cancel emits right away")

        port.finish(cancelledHandle)
        port.finish(deliveredHandle)
        queue.sync {}

        XCTAssertEqual(finished.map(\.id), [cancelled.id, delivered.id])
        XCTAssertEqual(finished[0].error as? TransferError, .cancelled)
        XCTAssertNil(finished[1].error)
    }
}
