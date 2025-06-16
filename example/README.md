# 🧪 rn-watch-connect Example

This is the official example project for [`rn-watch-connect`](https://github.com/CRIIPI11/rn-watch-connect/) — a React Native module that enables seamless communication between an iOS app and its paired Apple Watch using Apple’s [WatchConnectivity](https://developer.apple.com/documentation/watchconnectivity) framework.

Note: Make sure you use actual devices for testing as testing in simulator is not recommended as stated in the [Apple Documentation](https://developer.apple.com/documentation/watchconnectivity).

This example demonstrates:

- 📶 Monitoring the status of the paired Apple Watch
- 💬 Sending messages between iPhone and Apple Watch (with and without replies)
- 📂 Transferring files and syncing data
- 🔄 Updating and receiving application context
- 🧠 Handling events using listeners
- 📡 SwiftUI + WatchConnectivity integration on the Watch side

> ⚠️ This project includes both a React Native iOS app and a native Watch app (built in SwiftUI) to demonstrate full end-to-end connectivity.

---

## 🛠 Installation

1. **Clone the repo:**

   ```bash
   git clone https://github.com/CRIIPI11/rn-watch-connect/
   cd rn-watch-connect
   ```

2. **Install dependencies:**

   ```bash
   npm install
   cd example
   npm install
   ```

3. **Run the app:**

   ```bash
   cd example
   npx expo run:ios
   ```

- Watch app can be installed from the Watch app on the iPhone or running the watch target in Xcode if it doesn't install automatically.

## 📝 Usage

On launch, the iOS app will display most of the functionality of the module. From the app, you can:

- Send a message or data message and receive a reply from the Watch
- Subscribe to messages or data messages from the Watch and reply to them
- Transfer files and observe transfer status
- Update the application context and user info
- Listen to connectivity changes and events in real time

You can modify App.tsx to test different interactions
