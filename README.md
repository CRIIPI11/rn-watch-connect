# rn-watch-connect

A React Native module that enables seamless communication between an iOS app and its paired Apple Watch using WatchConnectivity. It provides an easy-to-use interface for sending messages, transferring files, syncing data, and monitoring connection status between the iPhone and Apple Watch.

## Installation

```bash
npm install rn-watch-connect
# or
yarn add rn-watch-connect
```

## Features

- Send messages between iPhone and Apple Watch
- Monitor watch connectivity status
- TypeScript support with generic types
- Event-based communication
- Promise-based message sending with reply support

## API Reference

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isWatchSupported` | `boolean` | Indicates if the device supports Watch Connectivity |
| `isWatchPaired` | `boolean` | Indicates if an Apple Watch is paired with the device |
| `isWatchAppInstalled` | `boolean` | Indicates if the Watch app is installed |
| `isWatchReachable` | `boolean` | Indicates if the paired Watch is currently reachable |
| `watchActivationState` | `string` | Current activation state of the Watch Connectivity session |

### Methods

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
  message: "Hello from iPhone!"
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
  message: "Hello from iPhone!"
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
  response: "Hello from iPhone!"
});
```

### Events

The module provides several events that you can suscribe to. Use `useEventListener` from this module to enable typescript support for messages events.

#### `onMessageReceived`

Triggered when a message is received from the Watch.

**Type Support:**
```typescript
useEventListener<T>(
  RnWatchConnect,
  "onMessageReceived",
  (message: T) => {
    // Handle message
  }
);
```

**Example:**
```typescript
type MyMessage = {
  message: string;
};

useEventListener<MyMessage>(
  RnWatchConnect,
  "onMessageReceived",
  ({ message }) => {
    console.log("Message received:", message);
  }
);
```

#### `onMessageWithReply`

Triggered when a message requiring a reply is received from the Watch.

**Type Support:**
```typescript
useEventListener<{ message: T; replyId: string }>(
  RnWatchConnect,
  "onMessageWithReply",
  (event) => {
    // Handle message and send reply
  }
);
```

**Example:**
```typescript
type MyMessage = {
  message: string;
};

useEventListener<{ message: MyMessage; replyId: string }>(
  RnWatchConnect,
  "onMessageWithReply",
  (event) => {
    console.log("Message received:", event.message);
    RnWatchConnect.replyToMessage(event.replyId, {
      response: "Reply from iPhone"
    });
  }
);
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
  message: "Hello"
});

// Or in event listeners
useEventListener<MyMessage>(
  RnWatchConnect,
  "onMessageReceived",
  (message) => {
    // TypeScript knows the shape of message
    console.log(message.message);
  }
);
```

## Example

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

## License

MIT 