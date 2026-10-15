# Changelog

## 2.0.0 (unreleased)

### Breaking changes

- **Expo SDK 57.** The module now targets Expo SDK 57, with iOS 16.4 as the minimum.
- **`transferFile` returns the documented progress keys.** Its `progress` now has `totalUnitCount` and `completedUnitCount`, the same as `outstandingFileTransfers` and the `FileTransfer` type. Before, it returned `total` and `completed`. Rename those if you read them.

### New features

- **Transfer finish events.** `onUserInfoTransferFinished` and `onFileTransferFinished` tell you how each Transfer ended, with the Transfer snapshot plus `error` (`null` when delivered, `{ message, code }` when it failed or was cancelled). Each Transfer gets exactly one of these events. Cancelling sends it immediately.
- **`onFileReceiveFailed`.** Tells you when a file from the Watch couldn't be kept, for example because the iPhone is out of storage, with `{ message, fileName, metadata }`. Before, the file was lost without any event.

- **Reply function on reply events.** `onMessageWithReply` and `onDataMessageWithReply` now include `reply`, which sends the Reply directly: `({ message, reply }) => reply({ ok: true })`. It returns a `Promise<void>` and rejects if the message was already replied to or is no longer waiting for a Reply. This matches WatchConnectivity's delegate, which hands you a reply handler with the message, and makes replying simpler: no Reply id to keep and no extra `replyTo…` call.

- **Stable Error codes.** Every failure now has its own `code`, on thrown and rejected errors and on the `error` in events, instead of `ERR_UNEXPECTED` for everything. For example `ERR_WATCH_NOT_REACHABLE`, `ERR_INVALID_TRANSFER_ID`, `ERR_FILE_NOT_FOUND`, `ERR_TRANSFER_CANCELLED`, and `ERR_` plus Apple's name for WatchConnectivity's own errors (`ERR_PAYLOAD_TOO_LARGE`, `ERR_DELIVERY_FAILED`, …). The TypeScript union `WatchConnectErrorCode` lists them all, and the README has an "Errors" section. Match on `code`, never on `message`.

### Deprecations

These still work and will be removed in a future major version.

- **`replyToMessage`, `replyToDataMessage` and the `replyId` field** of the reply events. Call the event's `reply` function instead.

### Bug fixes

- **Received files with the same name no longer overwrite each other.** Each Received file was copied to the temporary directory under its own name, replacing any earlier file with that name, so two `onFileReceived` events could point at the same file. A name that's already taken is now numbered the way Finder does it (`photo(1).jpg`, `photo(2).jpg`, …). `metadata` is unchanged.

- **Transfer ids can no longer point at the wrong Transfer.** Ids were derived from memory addresses, which the system can reuse after a Transfer ends, so an old id could cancel a different Transfer. Ids are now unique for the whole app run. Note that they are only valid for the current app run.

- **Status event payloads now use the documented keys.** `onReachabilityChanged`, `onWatchPairedChanged` and `onWatchAppInstallChanged` now send `{ isWatchReachable }`, `{ isWatchPaired }` and `{ isWatchAppInstalled }`, matching the TypeScript types and the README. Before, native code sent `{ isReachable }`, `{ isPaired }` and `{ isAppInstalled }`, so code that followed the docs read `undefined` after the first change. For example, a `useEvent` value seeded from the property worked at first, then stayed `false` for good. If you worked around this by reading the old keys, switch to the documented ones.
- **No more replayed or empty events when a listener is added.** Adding the first listener (or adding one again after all were removed) used to deliver the last value again: an empty `{}` for `onUserInfoReceived`, `onFileReceived` and `onApplicationContextChanged`, or a repeat of the last Received file, User Info or Application Context. Events now fire only when something actually happens on the Session.

### Behaviour changes

- **Stricter TypeScript types.** `watchActivationState` is now `WatchActivationState` (`"notActivated" | "inactive" | "activated" | "unknown"`) instead of `string`. `applicationContext`, `receivedApplicationContext` and the payloads of `onMessageReceived`, `onMessageWithReply`, `onApplicationContextChanged` and `onUserInfoReceived` are now `Record<string, any>` instead of `any`. These are type changes only, with no runtime effect. Code that compares the activation state against a misspelled value now fails to compile.

- **`transferUserInfo` returns the same shape as `outstandingUserInfoTransfers`.** It now includes `userInfo`, and in TypeScript it returns `OutstandingUserInfoTransfer`. `UserInfoTransfer` is now a deprecated alias of that type, so existing code still compiles.
- **Error codes and messages of thrown errors.** Errors that were `ERR_UNEXPECTED` now have their own code (see New features). Functions that throw directly, rather than reject a Promise (`sendMessageWithoutReply`, `sendDataMessageWithoutReply`, `replyToMessage`, `replyToDataMessage`, `updateApplicationContext`, `transferFile`, `cancelUserInfoTransfer`, `cancelFileTransfer`), now get Expo's prefix in `message`: "Calling the '…' function has failed → Caused by: …". If you matched on the message text, match on `code` instead. On platforms other than iOS, the errors now have `code: "ERR_UNSUPPORTED_PLATFORM"`.
- **New reply error message.** Replying twice, or after the message stopped waiting, now rejects with "Already replied, or the message is no longer waiting for a Reply" instead of "Invalid reply ID". If you matched on the old text, update it.
- **Status events fire only on a real change.** A new listener for `onReachabilityChanged`, `onWatchPairedChanged` or `onWatchAppInstallChanged` is no longer called right away with the current value. To get the current value, read `isWatchReachable`, `isWatchPaired` or `isWatchAppInstalled`, for example as the initial value of `useEvent`.

### Internal

- The iOS WatchConnectivity logic now lives in one Controller behind a port, with unit tests that run on macOS via `npm run test:ios` (see `docs/adr/0001-watch-session-behind-a-port.md`). User Info and File Transfers are now their own module behind it. Apart from the changes listed above, the JS interface is unchanged.
- Received files are now moved out of WatchConnectivity's folder instead of copied and then deleted. Nothing changes for apps: the file still ends up in the temporary directory, and the app owns it from `onFileReceived` on.
- The JS interface is described once, in `RnWatchConnect.types.ts`. The non-iOS stub is type-checked against it, and tests catch drift with the Swift side: `npm test` compares the event names, and `npm run test:ios` checks every event's name and payload keys.
