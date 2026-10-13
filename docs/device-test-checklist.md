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

- [ ] **Cold launch from the watch.** Force-quit the iPhone app, send a message from the watch. Record whether the app is woken and whether the message reaches JS or is silently dropped. *(At time of writing handlers are* `nil` *until JS subscribes, so it is expected to be dropped.)*
- [ ] **Background delivery.** With the iPhone app backgrounded, send user info and a file from the watch; foreground the app and confirm both events arrive (queued transfers are delivered even when not reachable).
- [ ] **Application context while killed.** Update context on the watch while the iPhone app is force-quit; relaunch; confirm `receivedApplicationContext` holds the latest value.
- [ ] **JS reload.** Reload the JS bundle (Metro `r`) and repeat a send and a receive — the native session persists, so listeners must re-attach cleanly with no duplicated events.



## 4. Replies

- [ ] **Reply after unmount.** Receive `onMessageWithReply`, unmount the listening component (removing the last listener) before calling `replyToMessage`. Record whether the reply throws `Invalid reply ID` and how long the watch waits before its error handler fires. *(At time of writing* `OnStopObserving` *clears pending replies.)*
- [ ] **No reply.** Receive `onMessageWithReply` and never reply. Note how long until the watch's error handler fires.
- [ ] **Slow reply.** Reply after ~10 s and after ~60 s; record which still reach the watch.
- [ ] **Double reply.** Call `replyToMessage` twice with the same `replyId`; the second must throw, not crash.
- [ ] **Burst.** Have the watch send 20 messages-with-reply in quick succession; reply to all; every reply arrives, no crash (exercises concurrent access to the pending-reply store).



## 5. Transfers

Use the example app's **File transfers** section (the Transfer playground). Each transfer must produce **exactly one** finish event in Activity (`onFileTransferFinished` / `onUserInfoTransferFinished`).

- [ ] **Same shape.** Start a "5 MB file": the object returned by `transferFile` has the same keys as its entry in `outstandingFileTransfers` (`progress.fractionCompleted`, `completedUnitCount`, `totalUnitCount`), and progress updates while it sends.
- [ ] **Delivered.** "Small file" and "Transfer user info": each logs one "… delivered" entry with `error: null`. The short id in the "… delivered" entry matches the one in the entry that started it. This confirms WatchConnectivity hands back the same transfer object in `didFinish`; if the ids differ, the finish events can't be matched to their transfers.
- [ ] **Cancelled.** Start "Huge file · 50 MB" and press **Cancel** while it sends: one "File transfer ended: … Transfer cancelled" entry appears **immediately**, the row shows "Cancelled", and no second entry follows (wait about 30 s).
- [ ] **Cancel one of two.** Start two huge files and cancel the first: only the first ends as cancelled, and the second is delivered.
- [ ] **Late cancel.** After a transfer is delivered, press **Cancel finished**: it throws `Invalid transfer ID`, nothing else is cancelled, and no new finish event appears.
- [ ] **Failed at start.** Press **Missing file**: it throws `File not found` right away, and **no** finish event follows.
- [ ] **Delete source while sending.** Start "Huge file" and delete its source file. *(Result on iOS 27.0.1: still delivered. WatchConnectivity keeps its own copy, so this is not a failure trigger.)*
- [ ] **Uninstall the watch app while sending.** Start "Huge file", then uninstall the watch app. Record what happens. *(Result on iOS 27.0.1 / watchOS 27.0.1: progress reaches 100 %, the transfer stays in `outstandingFileTransfers`, and no finish event fires. **Cancel** ends it with one "Transfer cancelled" event. Also record what happens after the watch app is reinstalled.)*
- [ ] **Unpair the watch while sending.** Record whether this produces a failed finish event, and its message.
- [ ] **Kill mid-transfer.** Start "Huge file", force-quit the app, relaunch. The transfer appears in the File transfers list with a **new** id (ids are valid for one app run), its progress continues, and **Cancel** works with one "Transfer cancelled" event.
- [ ] **Same for User Info.** Turn off Bluetooth on the iPhone, press "Transfer user info" a few times, force-quit and relaunch. The User info section lists them as "Outstanding" with new ids. Cancel one: one "User info transfer ended … Transfer cancelled" event. Turn Bluetooth back on: the rest are delivered, each with one "User info delivered" event.
- [ ] **Received file name collision.** On the watch app, press **Send file** twice, a few seconds apart (both are named `from-watch.txt`, with different timestamps inside). Activity shows each file's text as it arrives. Then press **Re-read received files** on the iPhone: each file must still show its own text ("Re-read: unchanged"). *(At time of writing both are copied to* `tmp/<name>`*, so the second overwrites the first.)*



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

