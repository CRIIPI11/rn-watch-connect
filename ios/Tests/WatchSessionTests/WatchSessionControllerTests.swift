import XCTest
@testable import WatchSession

final class WatchSessionControllerTests: XCTestCase {
    func testControllerIsCreatedAroundTheGivenPort() {
        let port = FakeWatchSessionPort()

        let controller = WatchSessionController(port: port)

        XCTAssertTrue(controller.port === port)
        XCTAssertEqual(port.activateCallCount, 0)
    }
}
