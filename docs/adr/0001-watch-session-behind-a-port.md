# WatchConnectivity logic sits behind a port, free of WatchConnectivity and Expo

All Session behaviour (reachability check, Reply ids and pending Replies, staging Received files, turning delegate callbacks into events, Transfers) lives in one Controller. The Controller imports only Foundation and talks to WCSession through a low-level port protocol. Two adapters fill the port: a thin real adapter, which is the only `WCSessionDelegate`, and an in-memory fake used by tests. The Expo Module only translates between JS and the Controller.

We chose this so the logic can be tested with plain `swift test` on macOS, where WatchConnectivity does not exist, with no simulator or paired Watch. Before this, the logic was split between the Expo Module and a singleton manager that both called `WCSession.default`, and bugs collected in the gap between them.

## Consequences

- Do not import WatchConnectivity or ExpoModulesCore into the Controller or the port. Doing so breaks the macOS test build. Keep WC-specific code in the real adapter, and keep it close to a one-line forward per call.
- WC transfer objects cannot be created by a fake, and they do not exist on macOS. They therefore cross the port as small handle protocols, and Received files cross it as plain values.
- Behaviour that only a real Watch can show (actual delivery, OS-version quirks) is covered by `docs/device-test-checklist.md`, not by unit tests.
