//
//  WatchSessionController.swift
//  RnWatchConnect
//
//  Owns all Session behaviour behind the WatchSessionPort. Foundation only: see docs/adr/0001.
//

import Foundation

final class WatchSessionController {
    let port: WatchSessionPort
    private let queue: DispatchQueue
    private let stagingDirectory: URL

    /// - Parameters:
    ///   - queue: serial queue for inbound work and pending-Reply state.
    ///   - stagingDirectory: where Received files are copied before they are reported.
    init(
        port: WatchSessionPort,
        queue: DispatchQueue = .main,
        stagingDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.port = port
        self.queue = queue
        self.stagingDirectory = stagingDirectory
    }
}
