import { File, Paths } from "expo-file-system";
import { useCallback, useEffect, useState } from "react";
import RnWatchConnect from "rn-watch-connect";

export type TrackedTransfer = {
  id: string;
  name: string;
  size: number;
  fraction: number;
  done: boolean;
};

const POLL_INTERVAL_MS = 500;
const KEEP_FINISHED_MS = 3000;

function writeTestFile(name: string, bytes: number): File {
  const file = new File(Paths.cache, name);
  if (!file.exists || file.size !== bytes) {
    file.create({ overwrite: true });
    file.write("0123456789abcdef".repeat(Math.ceil(bytes / 16)).slice(0, bytes));
  }
  return file;
}

/**
 * Starts file transfers to the watch and tracks their progress by polling
 * `outstandingFileTransfers`, which is the only progress signal WatchConnectivity exposes.
 */
export function useFileTransfers() {
  const [transfers, setTransfers] = useState<TrackedTransfer[]>([]);
  const hasActive = transfers.some((t) => !t.done);

  useEffect(() => {
    if (!hasActive) return;
    const interval = setInterval(() => {
      const outstanding = RnWatchConnect.outstandingFileTransfers;
      setTransfers((prev) =>
        prev.map((transfer) => {
          if (transfer.done) return transfer;
          const current = outstanding.find((t) => t.id === transfer.id);
          // A transfer disappears from the outstanding list once the system has delivered it.
          if (!current) return { ...transfer, fraction: 1, done: true };
          return { ...transfer, fraction: current.progress.fractionCompleted };
        })
      );
    }, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [hasActive]);

  // Clear finished transfers after a short delay so the user sees them complete.
  useEffect(() => {
    if (!transfers.some((t) => t.done)) return;
    const timeout = setTimeout(
      () => setTransfers((prev) => prev.filter((t) => !t.done)),
      KEEP_FINISHED_MS
    );
    return () => clearTimeout(timeout);
  }, [transfers]);

  const sendTestFile = useCallback((name: string, bytes: number) => {
    const file = writeTestFile(name, bytes);
    const size = file.size ?? bytes;
    const transfer = RnWatchConnect.transferFile(file.uri, { name, size });
    setTransfers((prev) => [
      ...prev,
      { id: transfer.id, name, size, fraction: 0, done: false },
    ]);
    return transfer;
  }, []);

  const cancel = useCallback((id: string) => {
    RnWatchConnect.cancelFileTransfer(id);
    setTransfers((prev) => prev.filter((t) => t.id !== id));
  }, []);

  return { transfers, sendTestFile, cancel };
}
