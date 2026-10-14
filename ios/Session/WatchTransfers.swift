//
//  WatchTransfers.swift
//  RnWatchConnect
//
//  Owns User Info and File Transfers: starting, listing, cancelling, their snapshots,
//  their Transfer ids, and how each one finishes. Foundation only: see docs/adr/0001.
//

import Foundation

/// Progress of a File Transfer at one moment.
struct TransferProgress: Equatable {
    let totalUnitCount: Int64
    let completedUnitCount: Int64
    let fractionCompleted: Double

    init(_ progress: Progress) {
        totalUnitCount = progress.totalUnitCount
        completedUnitCount = progress.completedUnitCount
        fractionCompleted = progress.fractionCompleted
    }
}

/// A User Info Transfer at one moment. The same shape whether it comes from starting or listing.
struct UserInfoTransferSnapshot: Equatable {
    let id: String
    let isTransferring: Bool
    let userInfo: [String: Any]

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.isTransferring == rhs.isTransferring
            && NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }
}

/// A File Transfer at one moment. The same shape whether it comes from starting or listing.
struct FileTransferSnapshot: Equatable {
    let id: String
    let isTransferring: Bool
    let progress: TransferProgress
    let fileURL: URL
    let metadata: [String: Any]

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.isTransferring == rhs.isTransferring
            && lhs.progress == rhs.progress
            && lhs.fileURL == rhs.fileURL
            && NSDictionary(dictionary: lhs.metadata).isEqual(to: rhs.metadata)
    }
}

/// Starts, lists and cancels Transfers, and decides their finish events.
///
/// Rule: every Transfer gets exactly one finish event. Cancelling produces it immediately;
/// a later `didFinish` for a cancelled Transfer is ignored.
///
/// Transfer ids are UUIDs, valid for the current app run. The registry holds each transfer
/// object weakly: an entry lives exactly as long as WatchConnectivity keeps the object, which is
/// as long as a `didFinish` can still arrive for it. A reused address never matches a stale entry.
///
/// Not thread-safe: the Controller calls it only on its serial queue.
final class WatchTransfers {
    private let port: WatchSessionPort
    private var userInfoRegistry = Registry()
    private var fileRegistry = Registry()

    init(port: WatchSessionPort) {
        self.port = port
    }

    /// Registry entries still alive (for tests).
    var trackedTransferCount: Int {
        userInfoRegistry.pruneReleased()
        fileRegistry.pruneReleased()
        return userInfoRegistry.count + fileRegistry.count
    }

    // MARK: - User Info

    func startUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferSnapshot {
        userInfoRegistry.pruneReleased()
        return snapshot(of: port.transferUserInfo(userInfo))
    }

    /// Transfers not finished yet. Cancelled Transfers are left out, because their finish
    /// event was already produced, even while WatchConnectivity still lists them.
    var outstandingUserInfo: [UserInfoTransferSnapshot] {
        guard port.isSupported else { return [] }
        userInfoRegistry.pruneReleased()
        return port.outstandingUserInfoTransfers
            .filter { !userInfoRegistry.isFinishReported($0) }
            .map(snapshot(of:))
    }

    /// Cancels the Transfer and returns its finish event.
    /// - Throws: `invalidTransferId` when no outstanding Transfer has this id (including one
    ///   that already finished or was already cancelled).
    func cancelUserInfo(id: String) throws -> SessionEvent {
        userInfoRegistry.pruneReleased()
        guard let handle = port.outstandingUserInfoTransfers.first(where: {
            userInfoRegistry.hasUnreportedId(id, for: $0)
        }) else {
            throw UserInfoTransferError.invalidTransferId
        }
        handle.cancel()
        let snapshot = snapshot(of: handle)
        userInfoRegistry.markFinishReported(handle)
        return .userInfoTransferFinished(snapshot, error: TransferError.cancelled)
    }

    /// WatchConnectivity reported the Transfer finished. Returns its finish event, or nil
    /// when it was already produced by a cancel.
    func userInfoFinished(_ handle: UserInfoTransferHandle, error: Error?) -> SessionEvent? {
        userInfoRegistry.pruneReleased()
        defer { userInfoRegistry.remove(handle) }
        if userInfoRegistry.isFinishReported(handle) { return nil }
        return .userInfoTransferFinished(snapshot(of: handle), error: error)
    }

    // MARK: - Files

    /// - Parameter file: a file URL string; the file must exist.
    func startFile(_ file: String, metadata: [String: Any]?) throws -> FileTransferSnapshot {
        guard let fileURL = URL(string: file) else {
            throw FileTransferError.invalidFileURL
        }
        guard FileManager.default.fileExists(atPath: fileURL.relativePath) else {
            throw FileTransferError.fileNotFound
        }
        fileRegistry.pruneReleased()
        return snapshot(of: port.transferFile(fileURL, metadata: metadata))
    }

    /// Transfers not finished yet. Cancelled Transfers are left out, because their finish
    /// event was already produced, even while WatchConnectivity still lists them.
    var outstandingFiles: [FileTransferSnapshot] {
        guard port.isSupported else { return [] }
        fileRegistry.pruneReleased()
        return port.outstandingFileTransfers
            .filter { !fileRegistry.isFinishReported($0) }
            .map(snapshot(of:))
    }

    /// Cancels the Transfer and returns its finish event.
    /// - Throws: `invalidTransferId` when no outstanding Transfer has this id (including one
    ///   that already finished or was already cancelled).
    func cancelFile(id: String) throws -> SessionEvent {
        fileRegistry.pruneReleased()
        guard let handle = port.outstandingFileTransfers.first(where: {
            fileRegistry.hasUnreportedId(id, for: $0)
        }) else {
            throw FileTransferError.invalidTransferId
        }
        handle.cancel()
        let snapshot = snapshot(of: handle)
        fileRegistry.markFinishReported(handle)
        return .fileTransferFinished(snapshot, error: TransferError.cancelled)
    }

    /// WatchConnectivity reported the Transfer finished. Returns its finish event, or nil
    /// when it was already produced by a cancel.
    func fileFinished(_ handle: FileTransferHandle, error: Error?) -> SessionEvent? {
        fileRegistry.pruneReleased()
        defer { fileRegistry.remove(handle) }
        if fileRegistry.isFinishReported(handle) { return nil }
        return .fileTransferFinished(snapshot(of: handle), error: error)
    }

    // MARK: - Snapshots

    private func snapshot(of transfer: UserInfoTransferHandle) -> UserInfoTransferSnapshot {
        UserInfoTransferSnapshot(
            id: userInfoRegistry.id(of: transfer),
            isTransferring: transfer.isTransferring,
            userInfo: transfer.userInfo
        )
    }

    private func snapshot(of transfer: FileTransferHandle) -> FileTransferSnapshot {
        FileTransferSnapshot(
            id: fileRegistry.id(of: transfer),
            isTransferring: transfer.isTransferring,
            progress: TransferProgress(transfer.progress),
            fileURL: transfer.fileURL,
            metadata: transfer.metadata ?? [:]
        )
    }
}

/// Transfer ids for one kind of Transfer, keyed by the transfer object's identity.
private struct Registry {
    private struct Entry {
        let id: String
        weak var object: AnyObject?
        /// The finish event was already produced (by a cancel); ignore a later `didFinish`.
        var finishReported = false
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    var count: Int { entries.count }

    /// Drops entries whose transfer object was released: no `didFinish` can arrive for them.
    mutating func pruneReleased() {
        entries = entries.filter { $0.value.object != nil }
    }

    /// The Transfer's id, assigned the first time the Transfer is seen.
    mutating func id(of object: AnyObject) -> String {
        if let entry = liveEntry(for: object) { return entry.id }
        let entry = Entry(id: UUID().uuidString, object: object)
        entries[ObjectIdentifier(object)] = entry
        return entry.id
    }

    func isFinishReported(_ object: AnyObject) -> Bool {
        liveEntry(for: object)?.finishReported ?? false
    }

    func hasUnreportedId(_ id: String, for object: AnyObject) -> Bool {
        liveEntry(for: object).map { $0.id == id && !$0.finishReported } ?? false
    }

    mutating func markFinishReported(_ object: AnyObject) {
        guard liveEntry(for: object) != nil else { return }
        entries[ObjectIdentifier(object)]?.finishReported = true
    }

    mutating func remove(_ object: AnyObject) {
        guard liveEntry(for: object) != nil else { return }
        entries[ObjectIdentifier(object)] = nil
    }

    /// The entry for this exact object. An entry left at a reused address does not match.
    private func liveEntry(for object: AnyObject) -> Entry? {
        guard let entry = entries[ObjectIdentifier(object)], entry.object === object else { return nil }
        return entry
    }
}
