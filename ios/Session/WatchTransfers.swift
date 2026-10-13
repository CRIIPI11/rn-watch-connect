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
/// Transfer ids are UUIDs, valid for the current app run. A registry entry holds a strong
/// reference to its transfer object, so an object's address cannot be reused while its id is live.
/// An entry is removed when its `didFinish` arrives. A cancelled entry is kept until then too,
/// even after WatchConnectivity stops listing it, so a late `didFinish` cannot produce a second event.
///
/// Not thread-safe: the Controller calls it only on its serial queue.
final class WatchTransfers {
    private struct Entry<Handle> {
        let id: String
        let handle: Handle
        /// The finish event was already produced (by a cancel); ignore a later `didFinish`.
        var finishReported = false
    }

    private let port: WatchSessionPort
    private var userInfoEntries: [ObjectIdentifier: Entry<UserInfoTransferHandle>] = [:]
    private var fileEntries: [ObjectIdentifier: Entry<FileTransferHandle>] = [:]

    init(port: WatchSessionPort) {
        self.port = port
    }

    // MARK: - User Info

    func startUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferSnapshot {
        snapshot(of: port.transferUserInfo(userInfo))
    }

    /// Transfers not finished yet. Cancelled Transfers are left out, because their finish
    /// event was already produced, even while WatchConnectivity still lists them.
    var outstandingUserInfo: [UserInfoTransferSnapshot] {
        guard port.isSupported else { return [] }
        return port.outstandingUserInfoTransfers
            .filter { userInfoEntries[ObjectIdentifier($0)]?.finishReported != true }
            .map(snapshot(of:))
    }

    /// Cancels the Transfer and returns its finish event.
    /// - Throws: `invalidTransferId` when no outstanding Transfer has this id (including one
    ///   that already finished or was already cancelled).
    func cancelUserInfo(id: String) throws -> SessionEvent {
        guard let handle = port.outstandingUserInfoTransfers.first(where: {
            userInfoEntries[ObjectIdentifier($0)].map { $0.id == id && !$0.finishReported } ?? false
        }) else {
            throw UserInfoTransferError.invalidTransferId
        }
        handle.cancel()
        let snapshot = snapshot(of: handle)
        userInfoEntries[ObjectIdentifier(handle)]?.finishReported = true
        return .userInfoTransferFinished(snapshot, error: TransferError.cancelled)
    }

    /// WatchConnectivity reported the Transfer finished. Returns its finish event, or nil
    /// when it was already produced by a cancel.
    func userInfoFinished(_ handle: UserInfoTransferHandle, error: Error?) -> SessionEvent? {
        let key = ObjectIdentifier(handle)
        if userInfoEntries[key]?.finishReported == true {
            userInfoEntries[key] = nil
            return nil
        }
        let snapshot = snapshot(of: handle)
        userInfoEntries[key] = nil
        return .userInfoTransferFinished(snapshot, error: error)
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
        return snapshot(of: port.transferFile(fileURL, metadata: metadata))
    }

    /// Transfers not finished yet. Cancelled Transfers are left out, because their finish
    /// event was already produced, even while WatchConnectivity still lists them.
    var outstandingFiles: [FileTransferSnapshot] {
        guard port.isSupported else { return [] }
        return port.outstandingFileTransfers
            .filter { fileEntries[ObjectIdentifier($0)]?.finishReported != true }
            .map(snapshot(of:))
    }

    /// Cancels the Transfer and returns its finish event.
    /// - Throws: `invalidTransferId` when no outstanding Transfer has this id (including one
    ///   that already finished or was already cancelled).
    func cancelFile(id: String) throws -> SessionEvent {
        guard let handle = port.outstandingFileTransfers.first(where: {
            fileEntries[ObjectIdentifier($0)].map { $0.id == id && !$0.finishReported } ?? false
        }) else {
            throw FileTransferError.invalidTransferId
        }
        handle.cancel()
        let snapshot = snapshot(of: handle)
        fileEntries[ObjectIdentifier(handle)]?.finishReported = true
        return .fileTransferFinished(snapshot, error: TransferError.cancelled)
    }

    /// WatchConnectivity reported the Transfer finished. Returns its finish event, or nil
    /// when it was already produced by a cancel.
    func fileFinished(_ handle: FileTransferHandle, error: Error?) -> SessionEvent? {
        let key = ObjectIdentifier(handle)
        if fileEntries[key]?.finishReported == true {
            fileEntries[key] = nil
            return nil
        }
        let snapshot = snapshot(of: handle)
        fileEntries[key] = nil
        return .fileTransferFinished(snapshot, error: error)
    }

    // MARK: - Registry

    /// The Transfer's id, assigned the first time the Transfer is seen.
    private func id(of handle: UserInfoTransferHandle) -> String {
        let key = ObjectIdentifier(handle)
        if let entry = userInfoEntries[key] { return entry.id }
        let entry = Entry(id: UUID().uuidString, handle: handle)
        userInfoEntries[key] = entry
        return entry.id
    }

    private func id(of handle: FileTransferHandle) -> String {
        let key = ObjectIdentifier(handle)
        if let entry = fileEntries[key] { return entry.id }
        let entry = Entry(id: UUID().uuidString, handle: handle)
        fileEntries[key] = entry
        return entry.id
    }

    // MARK: - Snapshots

    private func snapshot(of transfer: UserInfoTransferHandle) -> UserInfoTransferSnapshot {
        UserInfoTransferSnapshot(
            id: id(of: transfer),
            isTransferring: transfer.isTransferring,
            userInfo: transfer.userInfo
        )
    }

    private func snapshot(of transfer: FileTransferHandle) -> FileTransferSnapshot {
        FileTransferSnapshot(
            id: id(of: transfer),
            isTransferring: transfer.isTransferring,
            progress: TransferProgress(transfer.progress),
            fileURL: transfer.fileURL,
            metadata: transfer.metadata ?? [:]
        )
    }
}
