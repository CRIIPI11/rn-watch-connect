# Changelog

## Unreleased

### Bug fixes

- **Status event payloads now use the documented keys.** `onReachabilityChanged`, `onWatchPairedChanged` and `onWatchAppInstallChanged` now send `{ isWatchReachable }`, `{ isWatchPaired }` and `{ isWatchAppInstalled }`, matching the TypeScript types and the README. Before, native code sent `{ isReachable }`, `{ isPaired }` and `{ isAppInstalled }`, so code that followed the docs read `undefined` after the first change. For example, a `useEvent` value seeded from the property worked at first, then stayed `false` for good. If you worked around this by reading the old keys, switch to the documented ones.
- **No more replayed or empty events when a listener is added.** Adding the first listener (or adding one again after all were removed) used to deliver the last value again: an empty `{}` for `onUserInfoReceived`, `onFileReceived` and `onApplicationContextChanged`, or a repeat of the last Received file, User Info or Application Context. Events now fire only when something actually happens on the Session.

### Behaviour changes

- **Status events fire only on a real change.** A new listener for `onReachabilityChanged`, `onWatchPairedChanged` or `onWatchAppInstallChanged` is no longer called right away with the current value. To get the current value, read `isWatchReachable`, `isWatchPaired` or `isWatchAppInstalled`, for example as the initial value of `useEvent`.

### Internal

- The iOS WatchConnectivity logic now lives in one Controller behind a port, with unit tests that run on macOS via `npm run test:ios` (see `docs/adr/0001-watch-session-behind-a-port.md`). The JS interface is otherwise unchanged.
