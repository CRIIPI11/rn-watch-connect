import { useEventListener } from "expo";
import { File, FileMode, Paths } from "expo-file-system";
import { useCallback, useEffect, useState } from "react";
import RnWatchConnect, { type FileTransfer } from "rn-watch-connect";

export type TransferStatus = "sending" | "delivered" | "failed" | "cancelled";

export type TrackedTransfer = {
  id: string;
  name: string;
  size: number;
  fraction: number;
  status: TransferStatus;
  error?: string;
};

const POLL_INTERVAL_MS = 500;
const KEEP_FINISHED_MS = 5000;
const CHUNK_BYTES = 1024 * 1024;
const CANCELLED_MESSAGE = "Transfer cancelled";

/** Writes `bytes` of test data in 1 MB chunks, so a 50 MB file never sits in one JS string. */
function writeTestFile(name: string, bytes: number): File {
  const file = new File(Paths.cache, name);
  if (file.exists && file.size === bytes) return file;

  file.create({ overwrite: true });
  const pattern = new TextEncoder().encode("0123456789abcdef");
  const chunk = new Uint8Array(Math.min(CHUNK_BYTES, bytes));
  for (let i = 0; i < chunk.length; i++) chunk[i] = pattern[i % pattern.length];

  const handle = file.open(FileMode.WriteOnly);
  try {
    for (let written = 0; written < bytes; written += chunk.length) {
      const remaining = bytes - written;
      handle.writeBytes(remaining < chunk.length ? chunk.subarray(0, remaining) : chunk);
    }
  } finally {
    handle.close();
  }
  return file;
}

/** A transfer this app run did not start, e.g. one still outstanding from before a relaunch. */
function adopt(transfer: FileTransfer): TrackedTransfer {
  const name =
    transfer.file.metadata?.name ?? transfer.file.fileURL.split("/").pop() ?? "file";
  return {
    id: transfer.id,
    name,
    size: transfer.file.metadata?.size ?? transfer.progress.totalUnitCount,
    fraction: transfer.progress.fractionCompleted,
    status: "sending",
  };
}

/**
 * Updates progress from `outstandingFileTransfers`, and adds transfers this app run has not
 * seen yet. Returns `prev` itself when nothing changed, so a hanging transfer does not make
 * the screen re-render on every poll.
 */
function merge(prev: TrackedTransfer[], outstanding: FileTransfer[]): TrackedTransfer[] {
  let changed = false;
  const next = prev.map((transfer) => {
    if (transfer.status !== "sending") return transfer;
    const current = outstanding.find((t) => t.id === transfer.id);
    // Not listed any more: keep the last progress until the finish event says how it ended.
    if (!current || current.progress.fractionCompleted === transfer.fraction) return transfer;
    changed = true;
    return { ...transfer, fraction: current.progress.fractionCompleted };
  });
  const unknown = outstanding.filter((t) => !prev.some((p) => p.id === t.id));
  if (unknown.length > 0) changed = true;
  return changed ? [...next, ...unknown.map(adopt)] : prev;
}

/**
 * Starts file transfers to the watch and tracks them.
 *
 * Progress comes from polling `outstandingFileTransfers`, because WatchConnectivity has no
 * progress event. Whether a transfer is done comes only from `onFileTransferFinished`, which
 * fires exactly once per transfer: delivered, failed, or cancelled.
 *
 * Transfer ids are valid only for the current app run. After a relaunch, a transfer that is
 * still outstanding shows up in `outstandingFileTransfers` with a new id, so the list starts
 * from there and stays cancellable.
 */
export function useFileTransfers() {
  const [transfers, setTransfers] = useState<TrackedTransfer[]>(() =>
    RnWatchConnect.outstandingFileTransfers.map(adopt),
  );
  const [lastFinishedId, setLastFinishedId] = useState<string>();
  const isSending = transfers.some((t) => t.status === "sending");

  useEffect(() => {
    if (!isSending) return;
    const interval = setInterval(() => {
      const outstanding = RnWatchConnect.outstandingFileTransfers;
      setTransfers((prev) => merge(prev, outstanding));
    }, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [isSending]);

  useEventListener(RnWatchConnect, "onFileTransferFinished", (finished) => {
    const status: TransferStatus = !finished.error
      ? "delivered"
      : finished.error.message === CANCELLED_MESSAGE
        ? "cancelled"
        : "failed";
    setLastFinishedId(finished.id);
    setTransfers((prev) =>
      prev.map((t) =>
        t.id === finished.id
          ? {
              ...t,
              status,
              error: finished.error?.message,
              fraction: status === "delivered" ? 1 : t.fraction,
            }
          : t,
      ),
    );
  });

  // Clear finished transfers after a short delay so the user sees how they ended.
  useEffect(() => {
    if (!transfers.some((t) => t.status !== "sending")) return;
    const timeout = setTimeout(
      () => setTransfers((prev) => prev.filter((t) => t.status === "sending")),
      KEEP_FINISHED_MS,
    );
    return () => clearTimeout(timeout);
  }, [transfers]);

  const sendTestFile = useCallback((name: string, bytes: number) => {
    const file = writeTestFile(name, bytes);
    const size = file.size ?? bytes;
    const transfer = RnWatchConnect.transferFile(file.uri, { name, size });
    setTransfers((prev) => [
      ...prev,
      { id: transfer.id, name, size, fraction: 0, status: "sending" },
    ]);
    return transfer;
  }, []);

  /** Throws "File not found" right away: no Transfer is created, so no finish event follows. */
  const sendMissingFile = useCallback(() => {
    const missing = new File(Paths.cache, "does-not-exist.bin");
    if (missing.exists) missing.delete();
    return RnWatchConnect.transferFile(missing.uri, { name: "does-not-exist.bin" });
  }, []);

  /** The finish event (with "Transfer cancelled") marks it done; nothing to update here. */
  const cancel = useCallback((id: string) => {
    RnWatchConnect.cancelFileTransfer(id);
  }, []);

  return {
    transfers,
    lastFinishedId,
    sendTestFile,
    sendMissingFile,
    cancel,
  };
}
