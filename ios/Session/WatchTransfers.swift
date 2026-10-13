//
//  WatchTransfers.swift
//  RnWatchConnect
//
//  Owns User Info and File Transfers: starting, listing, cancelling, and their snapshots.
//  Foundation only: see docs/adr/0001.
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

final class WatchTransfers {
    private let port: WatchSessionPort

    init(port: WatchSessionPort) {
        self.port = port
    }

    // MARK: - User Info

    func startUserInfo(_ userInfo: [String: Any]) -> UserInfoTransferSnapshot {
        snapshot(of: port.transferUserInfo(userInfo))
    }

    var outstandingUserInfo: [UserInfoTransferSnapshot] {
        guard port.isSupported else { return [] }
        return port.outstandingUserInfoTransfers.map(snapshot(of:))
    }

    func cancelUserInfo(id: String) throws {
        guard let transfer = port.outstandingUserInfoTransfers.first(where: { transferId(of: $0) == id }) else {
            throw UserInfoTransferError.invalidTransferId
        }
        transfer.cancel()
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

    var outstandingFiles: [FileTransferSnapshot] {
        guard port.isSupported else { return [] }
        return port.outstandingFileTransfers.map(snapshot(of:))
    }

    func cancelFile(id: String) throws {
        guard let transfer = port.outstandingFileTransfers.first(where: { transferId(of: $0) == id }) else {
            throw FileTransferError.invalidTransferId
        }
        transfer.cancel()
    }

    // MARK: - Snapshots

    private func snapshot(of transfer: UserInfoTransferHandle) -> UserInfoTransferSnapshot {
        UserInfoTransferSnapshot(
            id: transferId(of: transfer),
            isTransferring: transfer.isTransferring,
            userInfo: transfer.userInfo
        )
    }

    private func snapshot(of transfer: FileTransferHandle) -> FileTransferSnapshot {
        FileTransferSnapshot(
            id: transferId(of: transfer),
            isTransferring: transfer.isTransferring,
            progress: TransferProgress(transfer.progress),
            fileURL: transfer.fileURL,
            metadata: transfer.metadata ?? [:]
        )
    }

    private func transferId(of transfer: AnyObject) -> String {
        String(ObjectIdentifier(transfer).hashValue)
    }
}
