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

## ✨ Features

- 📶 Monitor watch connectivity status
- 💬 Send messages between iPhone and Apple Watch
- 📂 Transfer files between iPhone and Apple Watch
- 🔄 Sync data between iPhone and Apple Watch
- 📡 Event-based communication
- 🧠 TypeScript support with generic types
- 📩 Promise-based message sending with reply support

## 📚 API Reference

### Properties

| Property                       | Type                            | Description                                                |
| ------------------------------ | ------------------------------- | ---------------------------------------------------------- |
| `isWatchSupported`             | `boolean`                       | Indicates if the device supports Watch Connectivity        |
| `isWatchPaired`                | `boolean`                       | Indicates if an Apple Watch is paired with the device      |
| `isWatchAppInstalled`          | `boolean`                       | Indicates if the Watch app is installed                    |
| `isWatchReachable`             | `boolean`                       | Indicates if the paired Watch is currently reachable       |
| `watchActivationState`         | [`WatchActivationState`](#watchactivationstate) | Current activation state of the Watch Connectivity session |
| `applicationContext`           | `{ [key: string]: any }`        | Current application context                                |
| `receivedApplicationContext`   | `{ [key: string]: any }`        | Received application context from the Watch                |
| `outstandingUserInfoTransfers` | [`OutstandingUserInfoTransfer[]`](#outstandinguserinfotransfer) | Outstanding user info transfers                            |
| `outstandingFileTransfers`     | [`FileTransfer[]`](#filetransfer)                | Outstanding file transfers                                 |

## 📡 Methods

#### `sendMessage<T, R>(message: T): Promise<R>`

Sends a message to the paired Apple Watch and waits for a reply.

**Type Parameters:**

- `T`: Type of the message to send (defaults to `Record<string, any>`)
- `R`: Type of the expected reply (defaults to `Record<string, any>`)

**Parameters:**

- `message`: The message to send to the Watch

**Returns:**

- `Promise<R>`: A promise that resolves with the Watch's reply

**Note:**
The following delegate method is expected to receive the message on the receiver app

- On Counter app (receiver):
  ```swift
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void)
  ```

**Example:**

```typescript
type MyMessage = {
  message: string;
};

type MyReply = {
  response: string;
};

const reply = await RnWatchConnect.sendMessage<MyMessage, MyReply>({
  message: "Hello from iPhone!",
});
```

#### `sendMessageWithoutReply<T>(message: T): Promise<void>`

Sends a message to the paired Apple Watch without expecting a reply.

**Type Parameters:**

- `T`: Type of the message to send (defaults to `Record<string, any>`)

**Parameters:**

- `message`: The message to send to the Watch

**Note:**
The following delegate method is expected to receive the message on the receiver app

- On Watch app (receiver):
  ```swift
  func session(_ session: WCSession, didReceiveMessage message: [String : Any])
  ```

**Example:**

```typescript
await RnWatchConnect.sendMessageWithoutReply({
  message: "Hello from iPhone!",
});
```

#### `replyToMessage(replyId: string, reply: Record<string, any>): Promise<void>`

> **Deprecated.** Use the `reply` function from [`onMessageWithReply`](#onmessagewithreply) instead. `replyToMessage` still works, and will be removed in a future major version.
>
> ```typescript
> useEventListener(RnWatchConnect, "onMessageWithReply", ({ message, reply }) => {
>   reply({ response: "Hello from iPhone!" });
> });
> ```

Sends a reply to a message received from the Watch.

**Parameters:**

- `replyId`: The ID of the message to reply to
- `reply`: The reply message to send

**Throws:** `ERR_REPLY_NOT_PENDING` if the message was already replied to, or is no longer waiting for a Reply

**Example:**

```typescript
await RnWatchConnect.replyToMessage(replyId, {
  response: "Hello from iPhone!",
});
```

#### `sendDataMessage(data: string): Promise<string>`

Sends a base64 encoded data message to the paired Apple Watch and waits for a reply.

**Parameters:**

- `data`: A base64 encoded string to send to the Watch

**Returns:**

- `Promise<string>`: A promise that resolves with the Watch's base64 encoded reply

**Note:**
The following delegate method is expected to receive the message on the receiver app

- On Watch app (receiver):
  ```swift
  func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void)
  ```

**Example:**

```typescript
try {
  const reply = await RnWatchConnect.sendDataMessage(
    "SGVsbG8gZnJvbSBpUGhvbmUh"
  ); // "Hello from iPhone!" in base64
  console.log("Decoded reply:", Buffer.from(reply, "base64").toString());
} catch (error) {
  console.log("Error:", error);
}
```

#### `sendDataMessageWithoutReply(data: string): Promise<void>`

Sends a base64 encoded data message to the paired Apple Watch without expecting a reply.

**Parameters:**

- `data`: A base64 encoded string to send to the Watch

**Note:**
The following delegate method is expected to receive the message on the receiver app

- On Watch app (receiver):
  ```swift
  func session(_ session: WCSession, didReceiveMessageData messageData: Data)
  ```

**Example:**

```typescript
try {
  await RnWatchConnect.sendDataMessageWithoutReply("SGVsbG8gZnJvbSBpUGhvbmUh");
} catch (error) {
  console.log("Error:", error);
}
```

#### `replyToDataMessage(replyId: string, response: string): Promise<void>`

> **Deprecated.** Use the `reply` function from [`onDataMessageWithReply`](#ondatamessagewithreply) instead. `replyToDataMessage` still works, and will be removed in a future major version.
>
> ```typescript
> useEventListener(RnWatchConnect, "onDataMessageWithReply", ({ data, reply }) => {
>   reply("SGVsbG8gZnJvbSBpUGhvbmUh");
> });
> ```

Sends a reply to a data message received from the Watch.

**Parameters:**

- `replyId`: The ID of the message to reply to
- `response`: The base64 encoded response string

**Throws:** `ERR_REPLY_NOT_PENDING` if the data message was already replied to or is no longer waiting for a Reply, or `ERR_INVALID_BASE64` if the base64 string is malformed

**Example:**

```typescript
await RnWatchConnect.replyToDataMessage(
  event.replyId,
  "TWVzc2FnZSByZWNlaXZlZCBvbiBSZWFjdCBOYXRpdmUh"
);
```

#### `updateApplicationContext<T>(applicationContext: T): Promise<void>`

Updates the application context on the Watch.

**Parameters:**

- `applicationContext`: The application context to update (defaults to `Record<string, any>`)

**Example:**

```typescript
await RnWatchConnect.updateApplicationContext({
  theme: "red",
});
```

#### `transferUserInfo<T>(userInfo: T): OutstandingUserInfoTransfer`

Transfers user info to the Watch.

**Parameters:**

- `userInfo`: The user info to transfer (defaults to `Record<string, any>`)

**Returns:**

- [`OutstandingUserInfoTransfer`](#outstandinguserinfotransfer): The transfer, in the same shape as `outstandingUserInfoTransfers`

**Example:**

```typescript
const transfer = RnWatchConnect.transferUserInfo({
  message: "Hello from iPhone!",
});
```

#### `cancelUserInfoTransfer(transferId: string): { id: string }`

Cancels a pending user info transfer.

**Parameters:**

- `transferId`: The ID of the transfer to cancel

**Returns:**

- `{ id: string }`: The transfer ID

**Throws:** `ERR_INVALID_TRANSFER_ID` if the `transferId` is invalid

**Example:**

```typescript
RnWatchConnect.cancelUserInfoTransfer(transfer.id);
```

#### `transferFile(file: string, metadata?: Record<string, any>): FileTransfer`

Transfers a file to the Watch.

**Parameters:**

- `file`: The file URL to transfer
- `metadata`: The metadata to transfer (defaults to `Record<string, any>`) (optional)

**Returns:**

- [`FileTransfer`](#filetransfer): The transfer, in the same shape as `outstandingFileTransfers`

**Throws:** `ERR_INVALID_FILE_URL` if the file URL is invalid, or `ERR_FILE_NOT_FOUND` if the file is not found

**Example:**

```typescript
const transfer = RnWatchConnect.transferFile("file://path/to/file.txt", {
  name: "file.txt",
});
```

#### `cancelFileTransfer(transferId: string): { id: string }`

Cancels a pending file transfer.

**Parameters:**

- `transferId`: The ID of the transfer to cancel

**Returns:**

- `{ id: string }`: The transfer ID

**Throws:** `ERR_INVALID_TRANSFER_ID` if the `transferId` is invalid

**Example:**

```typescript
RnWatchConnect.cancelFileTransfer(transfer.id);
```

## 📡 Events

#### `onMessageReceived`

Triggered when a message is received from the Watch. It doesn't require a response. The event object is the message object received from the Watch.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onMessageReceived", (event) => {
  console.log("Message received:", event);
});
```

#### `onMessageWithReply`

Triggered when a message requiring a reply is received from the Watch. The event object is an object with the following properties:

- `message`: The message object received from the Watch
- `reply(reply)`: The Reply function. Sends `reply` (an object) back to the Watch and returns a `Promise<void>`. It rejects if the message was already replied to, or is no longer waiting for a Reply (for example, after the last listener was removed). If several listeners get the same message, the first `reply` call wins.
- `replyId`: **Deprecated**, use `reply`. The ID to pass to `replyToMessage`.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onMessageWithReply", ({ message, reply }) => {
  console.log("Message received:", message);
  reply({ response: "Reply from iPhone" });
});
```

#### `onDataMessageReceived`

Triggered when a data message is received from the Watch. The event object is an object with the following properties:

- `data`: The base64 encoded data received from the Watch

**Example:**

```typescript
useEventListener(RnWatchConnect, "onDataMessageReceived", (event) => {
  console.log("Data message received:", event.data);
});
```

#### `onDataMessageWithReply`

Triggered when a data message requiring a reply is received from the Watch. The event object is an object with the following properties:

- `data`: The base64 encoded data received from the Watch
- `reply(reply)`: The Reply function. Sends `reply` (a base64 encoded string) back to the Watch and returns a `Promise<void>`. It rejects in the same cases as for `onMessageWithReply`, or if the base64 string is malformed.
- `replyId`: **Deprecated**, use `reply`. The ID to pass to `replyToDataMessage`.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onDataMessageWithReply", ({ data, reply }) => {
  console.log("Data message received:", data);
  reply("SGVsbG8gZnJvbSBpUGhvbmUh");
});
```

#### `onUserInfoReceived`

Triggered when user info is received from the Watch. The event object is the user info object received from the Watch.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onUserInfoReceived", (event) => {
  console.log("User info received:", event);
});
```

#### `onFileReceived`

Triggered when a file is received from the Watch. The event object is a [`File`](#file): `fileURL` points at the file, which your app now owns, and `metadata` is what the Watch sent with it.

Where Received files are kept:

- WatchConnectivity deletes a delivered file as soon as its delegate returns, before any JS can run. So the library moves each Received file into your app's **temporary directory** first, and does nothing else with it. From `onFileReceived` on, the file is yours: the library never moves, overwrites or deletes it again.
- iOS may delete files in the temporary directory at any time when your app isn't running, so **move or copy the file somewhere permanent if you need to keep it**, and delete it when you're done. A file you ignore is eventually cleaned up by iOS.
- Received files are never overwritten. If a file with the same name is already there, the new one is numbered the way Finder does it: `photo.jpg`, then `photo(1).jpg`, `photo(2).jpg`, and so on. `metadata` is passed through unchanged, so you can still read the original name if the Watch sent it there.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onFileReceived", (event) => {
  console.log("File received:", event);
});
```

#### `onFileReceiveFailed`

Triggered when a file from the Watch arrived but the library couldn't move it out of WatchConnectivity's folder, for example because the iPhone is out of storage. The file is lost: WatchConnectivity has already deleted it, and `onFileReceived` doesn't fire for it. The event object is a [`FileReceiveFailedEvent`](#filereceivefailedevent). Use `fileName` and `metadata` to tell which file it was, for example to ask the Watch to send it again.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onFileReceiveFailed", ({ message, fileName }) => {
  console.warn(`Lost ${fileName} from the Watch: ${message}`);
});
```

#### `onUserInfoTransferFinished` / `onFileTransferFinished`

Triggered when a Transfer finishes. **Each Transfer gets exactly one of these events**, however it ends:

| How it ended | `error` |
| --- | --- |
| Delivered to the Watch | `null` |
| Failed | `{ message, code }` from WatchConnectivity, for example `code: "ERR_DELIVERY_FAILED"` |
| Cancelled with `cancelUserInfoTransfer` / `cancelFileTransfer` | `{ message: "Transfer cancelled", code: "ERR_TRANSFER_CANCELLED" }`, sent immediately when you cancel |

The event object is the Transfer snapshot ([`OutstandingUserInfoTransfer`](#outstandinguserinfotransfer) or [`FileTransfer`](#filetransfer)) plus `error`.

If you cancel a Transfer that was already delivered, the cancel throws `ERR_INVALID_TRANSFER_ID`, and this event reports the delivery with `error: null`.

WatchConnectivity has no progress event. To show progress, read `outstandingFileTransfers` periodically, and use this event to know when a Transfer is done.

Good to know:

- **Deleting your file after starting a File Transfer doesn't stop or fail it.** WatchConnectivity keeps its own copy, so you can delete the source right after calling `transferFile`.
- **If the Watch app is uninstalled during a Transfer, the Transfer stays outstanding** and no finish event is sent, even after the Watch app is reinstalled: WatchConnectivity does not deliver it to the new installation. Cancel it to end it. To handle this automatically, listen for `onWatchAppInstallChanged` and cancel (or flag) your outstanding Transfers when `isWatchAppInstalled` becomes `false`.
- **After your app relaunches**, Transfers that are still outstanding have **new ids**. Read `outstandingFileTransfers` / `outstandingUserInfoTransfers` at launch to pick them up. Their finish events, and `cancel…Transfer`, use the new ids.

**Example:**

```typescript
useEventListener(RnWatchConnect, "onFileTransferFinished", (transfer) => {
  if (transfer.error?.code === "ERR_TRANSFER_CANCELLED") {
    console.log("Transfer cancelled:", transfer.id);
  } else if (transfer.error) {
    console.log("Transfer failed:", transfer.id, transfer.error.code, transfer.error.message);
  } else {
    console.log("Transfer delivered:", transfer.file.fileURL);
  }
});
```

#### `onReachabilityChanged`

Triggered when the Watch's reachability status changes.

**Example:**

```typescript
useEventListener(
  RnWatchConnect,
  "onReachabilityChanged",
  ({ isWatchReachable }) => {
    console.log("Watch reachability changed:", isWatchReachable);
  }
);
```

#### `onWatchPairedChanged`

Triggered when the Watch pairing status changes.

**Example:**

```typescript
useEventListener(
  RnWatchConnect,
  "onWatchPairedChanged",
  ({ isWatchPaired }) => {
    console.log("Watch paired status changed:", isWatchPaired);
  }
);
```

#### `onWatchAppInstallChanged`

Triggered when the Watch app installation status changes.

**Example:**

```typescript
useEventListener(
  RnWatchConnect,
  "onWatchAppInstallChanged",
  ({ isWatchAppInstalled }) => {
    console.log("Watch app installation status changed:", isWatchAppInstalled);
  }
);
```

#### `onApplicationContextChanged`

Triggered when the application context changes.

**Example:**

```typescript
useEventListener(
  RnWatchConnect,
  "onApplicationContextChanged",
  (applicationContext) =>
    console.log("Application context changed:", applicationContext)
);
```

## Errors

Every failure has a stable **Error code** in `code`, on thrown and rejected errors and on the `error` in events. **Match on `code`, never on `message`.** Messages can change between versions, and functions that throw directly (rather than reject a Promise) get Expo's prefix: "Calling the 'transferFile' function has failed → Caused by: …".

```typescript
import RnWatchConnect, { type WatchConnectErrorCode } from "rn-watch-connect";

try {
  await RnWatchConnect.sendMessageWithoutReply({ ping: 1 });
} catch (error) {
  const code = (error as { code?: WatchConnectErrorCode }).code;
  if (code === "ERR_WATCH_NOT_REACHABLE") {
    // Try again later, or use transferUserInfo, which doesn't need the Watch to be reachable.
  }
}
```

The same failure has the same code whichever function reports it: for example, `sendMessage` and `sendMessageWithoutReply` both use `ERR_WATCH_NOT_REACHABLE`.

The library's own checks:

| Code | When |
| --- | --- |
| `ERR_WATCH_NOT_REACHABLE` | A Message or Data Message was sent while the Watch isn't reachable |
| `ERR_REPLY_NOT_PENDING` | `reply` was called for a message already replied to, or no longer waiting for a Reply |
| `ERR_INVALID_BASE64` | A Data Message or data Reply isn't valid base64 (`message` says why) |
| `ERR_INVALID_TRANSFER_ID` | `cancelUserInfoTransfer` / `cancelFileTransfer` got an id that isn't an outstanding Transfer |
| `ERR_INVALID_FILE_URL` | `transferFile` got a URL it can't read |
| `ERR_FILE_NOT_FOUND` | `transferFile` got a file that doesn't exist |
| `ERR_TRANSFER_CANCELLED` | In a finish event: the Transfer was cancelled |
| `ERR_INSUFFICIENT_SPACE` | In `onFileReceiveFailed`: the iPhone is out of storage (also WatchConnectivity's own code for this) |
| `ERR_FILE_RECEIVE_FAILED` | In `onFileReceiveFailed`: the file couldn't be kept for another reason |
| `ERR_UNSUPPORTED_PLATFORM` | A method was called on a platform other than iOS |
| `ERR_UNEXPECTED` | Any other failure |

WatchConnectivity's own errors (for example when sending, updating the Application Context, or in finish events) use `ERR_` plus Apple's [`WCError.Code`](https://developer.apple.com/documentation/watchconnectivity/wcerror/code) name: `ERR_GENERIC_ERROR`, `ERR_SESSION_NOT_SUPPORTED`, `ERR_SESSION_MISSING_DELEGATE`, `ERR_SESSION_NOT_ACTIVATED`, `ERR_DEVICE_NOT_PAIRED`, `ERR_WATCH_APP_NOT_INSTALLED`, `ERR_INVALID_PARAMETER`, `ERR_PAYLOAD_TOO_LARGE`, `ERR_PAYLOAD_UNSUPPORTED_TYPES`, `ERR_MESSAGE_REPLY_FAILED`, `ERR_MESSAGE_REPLY_TIMED_OUT`, `ERR_FILE_ACCESS_DENIED`, `ERR_DELIVERY_FAILED`, `ERR_INSUFFICIENT_SPACE`, `ERR_SESSION_INACTIVE`, `ERR_TRANSFER_TIMED_OUT`, `ERR_COMPANION_APP_NOT_INSTALLED` and `ERR_WATCH_ONLY_APP`. Its `notReachable` uses `ERR_WATCH_NOT_REACHABLE`.

`WatchConnectErrorCode` is the TypeScript union of every code.

## Types

> **Transfer ids** (`id` on the types below) are valid only for the current app run. After the app restarts, a Transfer that is still outstanding gets a new id.

### `WatchActivationState`

`"notActivated" | "inactive" | "activated" | "unknown"`. `"unknown"` is returned when WatchConnectivity isn't supported: on a device without it, and on platforms other than iOS.

The session activates when the module loads, and there is no event for a failed activation. If `watchActivationState` still isn't `"activated"` shortly after launch, activation failed.

### `OutstandingUserInfoTransfer`

| Property       | Type                | Description                                   |
| -------------- | ------------------- | --------------------------------------------- |
| id             | string              | Unique identifier for the transfer            |
| userInfo       | Record<string, any> | The user info payload being transferred       |
| isTransferring | boolean             | Whether the transfer is currently in progress |

### `UserInfoTransfer`

_Deprecated._ An alias of [`OutstandingUserInfoTransfer`](#outstandinguserinfotransfer), kept so existing code still compiles. Use `OutstandingUserInfoTransfer` instead.

### `FileTransfer`

| Property       | Type         | Description                                   |
| -------------- | ------------ | --------------------------------------------- |
| id             | string       | Unique identifier for the transfer            |
| isTransferring | boolean      | Whether the transfer is currently in progress |
| progress       | [FileProgress](#fileprogress) | The progress of the file transfer             |
| file           | [File](#file)         | The file being transferred                    |

### `File`

| Property | Type                | Description                           |
| -------- | ------------------- | ------------------------------------- |
| fileURL  | string              | The URL of the file being transferred |
| metadata | Record<string, any> | The metadata associated with the file |

### `FileReceiveFailedEvent`

| Property | Type                        | Description                                                                 |
| -------- | --------------------------- | --------------------------------------------------------------------------- |
| message  | string                      | Why the file couldn't be kept, for example because the iPhone is out of storage |
| code     | [`WatchConnectErrorCode`](#errors) | `ERR_INSUFFICIENT_SPACE` when the iPhone is out of storage, otherwise `ERR_FILE_RECEIVE_FAILED` |
| fileName | string                      | The file name the Watch sent                                                 |
| metadata | Record<string, any> \| null | What the Watch sent with the file, or `null` when it sent nothing            |

### `FileProgress`

| Property           | Type   | Description                                               |
| ------------------ | ------ | --------------------------------------------------------- |
| fractionCompleted  | number | The fraction of the file transfer that has been completed |
| completedUnitCount | number | The number of bytes transferred so far                    |
| totalUnitCount     | number | The total number of bytes to be transferred               |

## TypeScript Support

The module is fully typed and supports generic types for messages and replies. You can define your own types for messages and replies:

```typescript
// Define your message types
type MyMessage = {
  message: string;
  // ... other properties
};

type MyReply = {
  response: string;
  // ... other properties
};

// Use them in your code
const reply = await RnWatchConnect.sendMessage<MyMessage, MyReply>({
  message: "Hello",
});
```

## 📄 License

MIT
