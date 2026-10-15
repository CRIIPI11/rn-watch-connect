# rn-watch-connect

A React Native (Expo) library that lets an iPhone app exchange data with its companion Apple Watch app through Apple's WatchConnectivity.

## Language

### The link

**Watch**:
The paired Apple Watch, and the companion Watch app running on it.
_Avoid_: Counterpart, peer, device

**Session**:
The single WatchConnectivity link between the iPhone app and the Watch app. Everything in this library travels over the Session.
_Avoid_: Connection, channel

**Activation state**:
Whether the Session is ready to carry data: not activated, inactive, or activated.

**Paired**:
The iPhone has an Apple Watch paired with it.

**Watch app installed**:
The companion Watch app is installed on the paired Watch.

**Reachability**:
Whether the Watch app can receive a Message right now (it is running and in range). Only Messages and Data Messages depend on it.
_Avoid_: Connected, online, available

### Live communication

**Message**:
A dictionary sent to the Watch for immediate delivery. Fails when the Watch is not reachable.
_Avoid_: Event, payload, notification

**Data Message**:
A Message whose content is raw bytes instead of a dictionary.
_Avoid_: Binary message

**Outbound**:
Sent by the iPhone app to the Watch.

**Inbound**:
Sent by the Watch to the iPhone app.

**Reply**:
The answer the receiver sends back to a Message or Data Message that asked for one.
_Avoid_: Response, ack

**Reply function**:
What the app calls to send the Reply to an Inbound Message that asked for one.

**Reply id**:
The token that ties a received Message to the Reply the app sends back for it.

### Background transfer

**Application Context**:
A dictionary describing the latest state. Only the most recent one is delivered, and each update replaces the previous one.
_Avoid_: State, settings, shared context

**User Info**:
A dictionary queued for background delivery. Every User Info is delivered, in order, even when the Watch is not reachable.
_Avoid_: User data, profile

**File Transfer**:
A file, with optional metadata, queued for background delivery to the Watch.

**Transfer**:
An outstanding User Info or File Transfer that has not been delivered yet. It can be inspected or cancelled by its Transfer id, and it ends with exactly one finish event: delivered, failed, or cancelled.
_Avoid_: Job, upload

**Transfer id**:
The identifier of one Transfer, valid only for the current app run. After the app restarts, an outstanding Transfer gets a new one.

**Transfer snapshot**:
The state of one Transfer at one moment. A Transfer has the same snapshot shape whether it comes from starting it, listing it, or its finish event.
_Avoid_: Transfer info, transfer status

**Received file**:
A file the Watch sent to the iPhone, kept by the library at a location the app can read.

### Failures

**Error code**:
The stable name of one kind of failure, such as Watch not reachable. It is the same whether the failure is thrown or reported in an event, and it never changes between versions, unlike the error message.
_Avoid_: Error type, error ID
