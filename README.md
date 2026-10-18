# ⌚️📱 rn-watch-connect

A React Native module that enables smooth and reliable communication between an iOS app and its paired Apple Watch using Apple’s [WatchConnectivity](https://developer.apple.com/documentation/watchconnectivity) framework. This library offers an easy-to-use interface for sending messages, transferring files, syncing data, and monitoring the connection status between the iPhone and Apple Watch — all from a React Native app.

> ⚠️ **Note:** This module does **NOT** provide a way to build Apple Watch apps. A separate Watch app must still be developed using Swift or SwiftUI. This package is intended as a modern, actively maintained alternative to the previously available (but now outdated) React Native watch connectivity module.

🙌 Contributions are welcome! If you'd like to improve the module or add new features, feel free to open an issue or submit a pull request.

## 📋 Requirements

- Expo SDK 57 or later (React Native 0.86+)
- iOS 16.4 or later

> Using an older Expo SDK or supporting iOS 15? Stay on `rn-watch-connect@1.x`.

## 🚀 Installation

```bash
npm install rn-watch-connect
# or
yarn add rn-watch-connect
```

The module has native code, so rebuild your app after installing it (for example `npx expo run:ios`, or a new development build). A JS reload isn't enough, and it doesn't run in Expo Go.

## 📖 Documentation

**Full docs: [rn-watch-connect.vercel.app](https://rn-watch-connect.vercel.app)**

- [Installation](https://rn-watch-connect.vercel.app/docs/installation)
- API: [Watch status](https://rn-watch-connect.vercel.app/docs/watch-status), [Messages](https://rn-watch-connect.vercel.app/docs/messages), [Data Messages](https://rn-watch-connect.vercel.app/docs/data-messages), [Application Context](https://rn-watch-connect.vercel.app/docs/application-context), [User Info](https://rn-watch-connect.vercel.app/docs/user-info), [File Transfer](https://rn-watch-connect.vercel.app/docs/file-transfer)
- [Error codes](https://rn-watch-connect.vercel.app/docs/errors)
- [Migrating from 1.x to 2.0](https://rn-watch-connect.vercel.app/docs/migration)
- [Using the docs with AI agents](https://rn-watch-connect.vercel.app/docs/ai-agents): [`llms.txt`](https://rn-watch-connect.vercel.app/llms.txt) and [`llms-full.txt`](https://rn-watch-connect.vercel.app/llms-full.txt)

## ✨ Features

- 📶 Monitor watch connectivity status
- 💬 Send messages between iPhone and Apple Watch
- 📂 Transfer files between iPhone and Apple Watch
- 🔄 Sync data between iPhone and Apple Watch
- 📡 Event-based communication
- 🧠 TypeScript support with generic types
- 📩 Promise-based message sending with reply support

## ⚡️ Quick start

Send a Message when the Watch is reachable, and listen for Messages from it:

```tsx
import { useEventListener } from "expo";
import RnWatchConnect from "rn-watch-connect";

export function WatchPing() {
  useEventListener(RnWatchConnect, "onMessageReceived", (message) => {
    console.log("From the Watch:", message);
  });

  async function ping() {
    if (!RnWatchConnect.isWatchReachable) return;
    const reply = await RnWatchConnect.sendMessage({ ping: Date.now() });
    console.log("Reply:", reply);
  }

  return null; // Call ping() from a button.
}
```

When something fails, the error has a stable `code`, such as `ERR_WATCH_NOT_REACHABLE`. Match on it, never on `message`. See [Error codes](https://rn-watch-connect.vercel.app/docs/errors).

## 📄 License

MIT
