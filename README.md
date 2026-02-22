# ⌚️📱 rn-watch-connect

A React Native module that enables smooth and reliable communication between an iOS app and its paired Apple Watch using Apple’s [WatchConnectivity](https://developer.apple.com/documentation/watchconnectivity) framework. This library offers an easy-to-use interface for sending messages, transferring files, syncing data, and monitoring the connection status between the iPhone and Apple Watch — all from a React Native app.

> ⚠️ **Note:** This module does **NOT** provide a way to build Apple Watch apps. A separate Watch app must still be developed using Swift or SwiftUI. This package is intended as a modern, actively maintained alternative to the previously available (but now outdated) React Native watch connectivity module.

🙌 Contributions are welcome! If you'd like to improve the module or add new features, feel free to open an issue or submit a pull request.

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
| `watchActivationState`         | `string`                        | Current activation state of the Watch Connectivity session |
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

Sends a reply to a message received from the Watch.

**Parameters:**

- `replyId`: The ID of the message to reply to
- `reply`: The reply message to send

**Throws:** If the `replyId` is invalid

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

Sends a reply to a data message received from the Watch.

**Parameters:**

- `replyId`: The ID of the message to reply to
- `response`: The base64 encoded response string

**Throws:** If the `replyId` is invalid or the base64 string is malformed

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

#### `transferUserInfo<T>(userInfo: T): UserInfoTransfer`

Transfers user info to the Watch.

**Parameters:**

- `userInfo`: The user info to transfer (defaults to `Record<string, any>`)

**Returns:**

- [`UserInfoTransfer`](#userinfotransfer): The transfer ID and isTransferring status

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

**Throws:** If the `transferId` is invalid

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

- [`FileTransfer`](#filetransfer): Object containing the transfer information

**Throws:** If the file URL is invalid or the file is not found

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

**Throws:** If the `transferId` is invalid

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
- `replyId`: The ID of the message to reply to

**Example:**

```typescript
useEventListener(RnWatchConnect, "onMessageWithReply", (event) => {
  console.log("Message received:", event.message);
  RnWatchConnect.replyToMessage(event.replyId, {
    response: "Reply from iPhone",
  });
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
- `replyId`: The ID of the message to reply to

**Example:**

```typescript
useEventListener(RnWatchConnect, "onDataMessageWithReply", (event) => {
  console.log("Data message received:", event.data);
  RnWatchConnect.replyToDataMessage(event.replyId, "SGVsbG8gZnJvbSBpUGhvbmUh");
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

Triggered when a file is received from the Watch. The event object is an object with the following properties:

- `File`: The file object received from the Watch

**Example:**

```typescript
useEventListener(RnWatchConnect, "onFileReceived", (event) => {
  console.log("File received:", event);
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

## Types

### `OutstandingUserInfoTransfer`

| Property       | Type                | Description                                   |
| -------------- | ------------------- | --------------------------------------------- |
| id             | string              | Unique identifier for the transfer            |
| userInfo       | Record<string, any> | The user info payload being transferred       |
| isTransferring | boolean             | Whether the transfer is currently in progress |

### `UserInfoTransfer`

| Property       | Type    | Description                                   |
| -------------- | ------- | --------------------------------------------- |
| id             | string  | Unique identifier for the transfer            |
| isTransferring | boolean | Whether the transfer is currently in progress |

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
