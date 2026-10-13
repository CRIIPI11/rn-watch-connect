# Device Test Checklist

Manual scenarios to run on a physical iPhone + paired Apple Watch before a release. These cover the WatchConnectivity integration itself — the behaviour that unit tests cannot reach because `WCSession` can't be faked or driven on a simulator.

Pure logic (transfer IDs, reply bookkeeping, base64 validation, JS encoding, file staging) belongs in unit tests, not here.

## Setup

- iPhone running the example app (`example/`), built in Debug with the Metro log visible.
- Paired Apple Watch running a companion app that can: echo messages with a reply, send messages without a reply, send data messages, update application context, transfer user info, and transfer files.
- Note the iOS and watchOS versions in the run log — several behaviours differ by OS version.
- Ideally a second iPhone/iOS version (one iOS 15–16, one iOS 17+) for the URL-handling checks.
- For the multi-watch section: two watches paired to the same iPhone.

Record each run as: date, iOS/watchOS versions, library version, pass/fail per item, notes.

## 1. Baseline flows

Run these first; if any fail, stop and fix before the edge cases.

- [ ] `isWatchSupported`, `isWatchPaired`, `isWatchAppInstalled` are `true`; `watchActivationState` is `"activated"`.
- [ ] `sendMessage` resolves with the watch's reply.
- [ ] `sendMessageWithoutReply` is received on the watch.
- [ ] `sendDataMessage` resolves with a base64 reply that decodes to what the watch sent.
- [ ] Watch → phone message fires `onMessageReceived`.
- [ ] Watch → phone message with reply fires `onMessageWithReply`; `replyToMessage` reaches the watch.
- [ ] Same two checks for data messages (`onDataMessageReceived`, `onDataMessageWithReply` / `replyToDataMessage`).
- [ ] `updateApplicationContext` arrives on the watch; watch-side context update fires `onApplicationContextChanged` and shows in `receivedApplicationContext`.
- [ ] `transferUserInfo` arrives on the watch; watch-side user info fires `onUserInfoReceived`.
- [ ] `transferFile` arrives on the watch; watch-side file fires `onFileReceived` with a readable `fileURL` and its `metadata`.

## 2. Status events

- [ ] Event payload keys match the TypeScript types: `onReachabilityChanged` → `isWatchReachable`, `onWatchPairedChanged` → `isWatchPaired`, `onWatchAppInstallChanged` → `isWatchAppInstalled`.
- [ ] Reachability toggles: lower the watch wrist / leave the watch app → `onReachabilityChanged(false)`; bring the watch app to the foreground → `true`.
- [ ] Bluetooth off on the iPhone → unreachable; `sendMessage` rejects with "Watch is not reachable" instead of hanging.
- [ ] Uninstall the watch app → `onWatchAppInstallChanged(false)`; reinstall → `true`.
- [ ] Adding the first listener does **not** fire spurious empty events (`onUserInfoReceived({})`, `onFileReceived({})`, `onApplicationContextChanged({})`).

## 3. App lifecycle

- [ ] **Cold launch from the watch.** Force-quit the iPhone app, send a message from the watch. Record whether the app is woken and whether the message reaches JS or is silently dropped. _(At time of writing handlers are_ `nil` _until JS subscribes, so it is expected to be dropped.)_
- [ ] **Background delivery.** With the iPhone app backgrounded, send user info and a file from the watch; foreground the app and confirm both events arrive (queued transfers are delivered even when not reachable).
- [ ] **Application context while killed.** Update context on the watch while the iPhone app is force-quit; relaunch; confirm `receivedApplicationContext` holds the latest value.
- [ ] **JS reload.** Reload the JS bundle (Metro `r`) and repeat a send and a receive — the native session persists, so listeners must re-attach cleanly with no duplicated events.

## 4. Replies

- [ ] **Reply after unmount.** Receive `onMessageWithReply`, unmount the listening component (removing the last listener) before calling `replyToMessage`. Record whether the reply throws `Invalid reply ID` and how long the watch waits before its error handler fires. _(At time of writing_ `OnStopObserving` _clears pending replies.)_
- [ ] **No reply.** Receive `onMessageWithReply` and never reply. Note how long until the watch's error handler fires.
- [ ] **Slow reply.** Reply after ~10 s and after ~60 s; record which still reach the watch.
- [ ] **Double reply.** Call `replyToMessage` twice with the same `replyId`; the second must throw, not crash.
- [ ] **Burst.** Have the watch send 20 messages-with-reply in quick succession; reply to all; every reply arrives, no crash (exercises concurrent access to the pending-reply store).

## 5. Transfers

- [ ] **Progress.** Transfer a large file (the example app's "large file" button); progress fields update and match the `FileTransfer` type (`fractionCompleted`, `completedUnitCount`, `totalUnitCount`). Compare the object returned by `transferFile` with the one in `outstandingFileTransfers` — they must have the same shape. _(Known mismatch at time of writing.)_
- [ ] **Cancel.** Start two file transfers, cancel the first by ID; only the first disappears from `outstandingFileTransfers` and the second completes.
- [ ] **Cancel finished transfer.** Cancel an ID whose transfer already completed; it throws `Invalid transfer ID` rather than cancelling something else.
- [ ] **Kill mid-transfer.** Start a large file transfer, force-quit the app, relaunch. Record whether it still appears in `outstandingFileTransfers`, whether it has an ID, and whether that ID can be cancelled.
- [ ] **Same as above for user info:** queue several `transferUserInfo` calls while the watch is unreachable, kill and relaunch, inspect `outstandingUserInfoTransfers`, cancel one.
- [ ] **Received file name collision.** Have the watch send two different files with the same file name back to back; confirm JS can read both with the right contents. _(At time of writing both are copied to_ `tmp/<name>`_, so the second overwrites the first.)_

## 6. Input edge cases

- [ ] `transferFile` with a `file://` URL → succeeds.
- [ ] `transferFile` with a plain path (no scheme) → record behaviour.
- [ ] `transferFile` with a path containing spaces, both percent-encoded and not — **run on iOS 15–16 and on iOS 17+**; `URL(string:)` handles unencoded spaces differently across these versions.
- [ ] `transferFile` with a non-existent path → rejects with "File not found".
- [ ] `sendDataMessage("")` → record behaviour (currently accepted as empty data).
- [ ] `sendDataMessage` with URL-safe base64 (`-`, `_`) or embedded newlines → rejects with a base64 error.
- [ ] Message payload near the size limit: send a dictionary of roughly 60 KB and roughly 100 KB; the oversized one must reject with an error, not hang.
- [ ] Payload with non-property-list values (e.g. `null`, nested `undefined`) → rejects cleanly.

## 7. Session state changes

- [ ] **Watch switching** (needs two watches). Switch the active watch in the Watch app; confirm the session reactivates (`sessionDidDeactivate` → `activate()`), `watchActivationState` returns to `"activated"`, and messaging works with the new watch.
- [ ] **Unpair** the watch → `onWatchPairedChanged(false)`, sends reject cleanly; re-pair → recovers without an app restart.
- [ ] **Airplane mode** on the iPhone during a file transfer → transfer pauses and resumes when connectivity returns.

## Keeping this current

- When a "known issue" above is fixed, remove the note and keep the check as a regression test.
- When a scenario gains a unit test that fully covers it, move it out of this list.
- Add a scenario here whenever a bug report turns out to be device- or OS-version-specific.
