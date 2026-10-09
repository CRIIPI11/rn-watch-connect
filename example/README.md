# 🧪 rn-watch-connect Example

The example project for [`rn-watch-connect`](https://github.com/CRIIPI11/rn-watch-connect/), a React Native module that connects an iOS app to its paired Apple Watch using Apple's [WatchConnectivity](https://developer.apple.com/documentation/watchconnectivity) framework.

It contains two apps that talk to each other:

| App                | Where                    | What it does                                                                                       |
| ------------------ | ------------------------ | -------------------------------------------------------------------------------------------------- |
| iPhone (Expo SDK 57) | [`App.tsx`](./App.tsx) | Exercises every module API: status, messages, data messages, application context, user info, files |
| Apple Watch (SwiftUI) | [`targets/watch/`](./targets/watch) | Native companion app that replies to the phone and can send everything back                         |

The watch app is generated into the Xcode project by [`@bacons/apple-targets`](https://github.com/EvanBacon/expo-apple-targets), so it lives outside `ios/` and survives `npx expo prebuild --clean`.

## 🛠 Setup

```bash
git clone https://github.com/CRIIPI11/rn-watch-connect/
cd rn-watch-connect
npm install
cd example
npm install
```

Set your own Apple Team ID in [`app.json`](./app.json) (`expo.ios.appleTeamId`) and change the bundle identifier if you're running on a real device.

## ▶️ Run

```bash
npx expo prebuild -p ios --clean
npx expo run:ios
```

Installing the iPhone app embeds the watch app. To install it on a watch:

- **Simulator:** pick a paired iPhone + Apple Watch simulator pair, then run the `WatchConnectExample` scheme in Xcode (`xed ios`) on the watch simulator.
- **Device:** install from the Watch app on the iPhone, or run the `WatchConnectExample` scheme in Xcode.

> Simulators handle live messages, data messages, and application context. Background transfers (`transferUserInfo`, `transferFile`) are unreliable on the simulator, so test them on real devices.

## 📝 What to try

| Feature             | From iPhone                                 | From Watch                    |
| ------------------- | ------------------------------------------- | ----------------------------- |
| Status              | Pills update live via events                | Reachability indicator        |
| Message             | **Send** shows the watch's reply            | **Send message** → phone replies |
| Data message        | **Send data** shows the watch's byte count  | **Send data** → phone replies |
| Application context | Tap a color to tint the watch app           | **App context**               |
| User info           | **Transfer user info**                      | **User info**                 |
| Files               | 1 KB or 5 MB file with progress + cancel    | **Send file**                 |

Everything sent or received shows up in the **Activity** log on both devices.

The message shapes both apps agree on are documented at the top of [`ConnectivityStore.swift`](./targets/watch/ConnectivityStore.swift).
