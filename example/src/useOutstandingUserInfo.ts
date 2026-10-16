import { useEventListener } from "expo";
import { useCallback, useEffect, useState } from "react";
import RnWatchConnect, { type OutstandingUserInfoTransfer } from "rn-watch-connect";

const POLL_INTERVAL_MS = 1000;

const sameIds = (a: OutstandingUserInfoTransfer[], b: OutstandingUserInfoTransfer[]) =>
  a.length === b.length && a.every((t, i) => t.id === b[i].id);

/**
 * User Info transfers that are not delivered yet, including ones from before a relaunch
 * (they get a new id after a relaunch). User Info is usually delivered at once (over Wi-Fi
 * too, when Bluetooth is off), so the list is usually empty.
 */
export function useOutstandingUserInfo() {
  const [outstanding, setOutstanding] = useState(
    () => RnWatchConnect.outstandingUserInfoTransfers,
  );

  const refresh = useCallback(() => {
    const current = RnWatchConnect.outstandingUserInfoTransfers;
    setOutstanding((prev) => (sameIds(prev, current) ? prev : current));
  }, []);

  useEffect(() => {
    const interval = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [refresh]);

  useEventListener(RnWatchConnect, "onUserInfoTransferFinished", refresh);

  return { outstanding, refresh };
}
