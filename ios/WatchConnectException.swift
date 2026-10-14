import ExpoModulesCore

/// An error from the Session package as an Expo Exception, so JS receives its Error code
/// (ErrorCodes) instead of Expo's generic ERR_UNEXPECTED.
final class WatchConnectException: Exception, @unchecked Sendable {
    private let error: Error

    init(_ error: Error, file: String = #fileID, line: UInt = #line, function: String = #function) {
        self.error = error
        super.init(file: file, line: line, function: function)
    }

    override var code: String {
        ErrorCodes.code(for: error)
    }

    override var reason: String {
        error.localizedDescription
    }
}

/// Runs `body`, rethrowing any error as a WatchConnectException.
func withErrorCodes<T>(_ body: () throws -> T) throws -> T {
    do {
        return try body()
    } catch {
        throw WatchConnectException(error)
    }
}
