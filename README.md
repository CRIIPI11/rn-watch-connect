# ⌚️📱 rn-watch-connect

A React Native module that enables seamless communication between an iOS app and its paired Apple Watch using WatchConnectivity. It provides an easy-to-use interface for sending messages, transferring files, syncing data, and monitoring connection status between the iPhone and Apple Watch.

## 🚀 Installation

```bash
npm install rn-watch-connect
# or
yarn add rn-watch-connect
```

## ✨ Features

- Send messages between iPhone and Apple Watch
- Monitor watch connectivity status
- TypeScript support with generic types
- Event-based communication
- Promise-based message sending with reply support

## 📚 API Reference

### Properties

| Property                     | Type      | Description                                                |
| ---------------------------- | --------- | ---------------------------------------------------------- |
| `isWatchSupported`           | `boolean` | Indicates if the device supports Watch Connectivity        |
| `isWatchPaired`              | `boolean` | Indicates if an Apple Watch is paired with the device      |
| `isWatchAppInstalled`        | `boolean` | Indicates if the Watch app is installed                    |
| `isWatchReachable`           | `boolean` | Indicates if the paired Watch is currently reachable       |
| `watchActivationState`       | `string`  | Current activation state of the Watch Connectivity session |
| `applicationContext`         | `any`     | Current application context                                |
| `receivedApplicationContext` | `any`     | Received application context from the Watch                |

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

#### `replyToMessage(replyId: string, reply: Record<string, any>): void`

Sends a reply to a message received from the Watch.

**Parameters:**

- `replyId`: The ID of the message to reply to
- `reply`: The reply message to send

**Example:**

```typescript
RnWatchConnect.replyToMessage(replyId, {
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

#### `replyToDataMessage(replyId: string, response: string): void`

Sends a reply to a data message received from the Watch.

**Parameters:**

- `replyId`: The ID of the message to reply to
- `response`: The base64 encoded response string

**Example:**

```typescript
RnWatchConnect.replyToDataMessage(
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

## 📝 Example

```typescript
import RnWatchConnect, { useEventListener } from "rn-watch-connect";

type MyMessage = {
  message: string;
};

type MyReply = {
  response: string;
};

function App() {
  // Listen for messages
  useEventListener<MyMessage>(
    RnWatchConnect,
    "onMessageReceived",
    ({ message }) => {
      console.log("Message received:", message);
    }
  );

  // Send a message
  const sendMessage = async () => {
    try {
      const reply = await RnWatchConnect.sendMessage<MyMessage, MyReply>({
        message: "Hello from iPhone!"
      });
      console.log("Reply:", reply);
    } catch (error) {
      console.error("Error:", error);
    }
  };

  return (
    // ... your app UI
  );
}
```

## 📄 License

MIT
