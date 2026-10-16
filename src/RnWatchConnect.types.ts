import { EventEmitter } from "expo";

export type MessagePayload = Record<string, any>;

/** Whether the Session is ready to carry data. */
export type WatchActivationState = "notActivated" | "inactive" | "activated" | "unknown";

export type OutstandingUserInfoTransfer = {
  id: string;
  userInfo: Record<string, any>;
  isTransferring: boolean;
};

/** @deprecated Use `OutstandingUserInfoTransfer`. `transferUserInfo` returns the same shape as `outstandingUserInfoTransfers`. */
export type UserInfoTransfer = OutstandingUserInfoTransfer;

export type File = {
  fileURL: string;
  metadata: Record<string, any>;
};

/** A file from the Watch that the library couldn't keep, so it is lost. */
export type FileReceiveFailedEvent = {
  /** Why the file couldn't be kept, for example because the iPhone is out of storage. */
  message: string;
  /** `ERR_INSUFFICIENT_SPACE` when the iPhone is out of storage, otherwise `ERR_FILE_RECEIVE_FAILED`. */
  code: WatchConnectErrorCode;
  /** The file name the Watch sent. */
  fileName: string;
  /** What the Watch sent with the file, or `null` when it sent nothing. */
  metadata: Record<string, any> | null;
};

export type FileProgress = {
  fractionCompleted: number;
  completedUnitCount: number;
  totalUnitCount: number;
};

export type FileTransfer = {
  id: string;
  isTransferring: boolean;
  progress: FileProgress;
  file: File;
};

/**
 * The stable Error code of a failure: the `code` of a thrown or rejected error, and of the errors
 * in events. Match on it, never on `message`, which can change. See the README "Errors" section.
 */
export type WatchConnectErrorCode =
  // Not a known failure (Expo's default code)
  | "ERR_UNEXPECTED"
  // Called on a platform other than iOS
  | "ERR_UNSUPPORTED_PLATFORM"
  // The library's own checks
  | "ERR_WATCH_NOT_REACHABLE"
  | "ERR_REPLY_NOT_PENDING"
  | "ERR_INVALID_BASE64"
  | "ERR_INVALID_TRANSFER_ID"
  | "ERR_INVALID_FILE_URL"
  | "ERR_FILE_NOT_FOUND"
  | "ERR_TRANSFER_CANCELLED"
  | "ERR_FILE_RECEIVE_FAILED"
  // WatchConnectivity's own errors (WCError)
  | "ERR_GENERIC_ERROR"
  | "ERR_SESSION_NOT_SUPPORTED"
  | "ERR_SESSION_MISSING_DELEGATE"
  | "ERR_SESSION_NOT_ACTIVATED"
  | "ERR_DEVICE_NOT_PAIRED"
  | "ERR_WATCH_APP_NOT_INSTALLED"
  | "ERR_INVALID_PARAMETER"
  | "ERR_PAYLOAD_TOO_LARGE"
  | "ERR_PAYLOAD_UNSUPPORTED_TYPES"
  | "ERR_MESSAGE_REPLY_FAILED"
  | "ERR_MESSAGE_REPLY_TIMED_OUT"
  | "ERR_FILE_ACCESS_DENIED"
  | "ERR_DELIVERY_FAILED"
  | "ERR_INSUFFICIENT_SPACE"
  | "ERR_SESSION_INACTIVE"
  | "ERR_TRANSFER_TIMED_OUT"
  | "ERR_COMPANION_APP_NOT_INSTALLED"
  | "ERR_WATCH_ONLY_APP";

/** Why a Transfer finished without being delivered. `null` in a finish event means it was delivered. */
export type TransferFinishError = {
  message: string;
  /** For example `ERR_TRANSFER_CANCELLED`, or a WatchConnectivity code like `ERR_DELIVERY_FAILED`. */
  code: WatchConnectErrorCode;
};

/** Sent exactly once per User Info Transfer, when it was delivered, failed or was cancelled. */
export type UserInfoTransferFinishedEvent = OutstandingUserInfoTransfer & {
  error: TransferFinishError | null;
};

/** Sent exactly once per File Transfer, when it was delivered, failed or was cancelled. */
export type FileTransferFinishedEvent = FileTransfer & {
  error: TransferFinishError | null;
};

/** An Inbound Message that asks for a Reply. */
export type MessageWithReplyEvent = {
  message: MessagePayload;
  /**
   * The Reply function: sends `reply` back to the Watch.
   * Rejects if this Message was already replied to, or is no longer waiting for a Reply.
   */
  reply: (reply: MessagePayload) => Promise<void>;
  /**
   * @deprecated Call `reply` instead. `replyId` and `replyToMessage` will be removed in a future
   * major version.
   */
  replyId: string;
};

/** An Inbound Data Message that asks for a Reply. */
export type DataMessageWithReplyEvent = {
  /** The received bytes, base64 encoded. */
  data: string;
  /**
   * The Reply function: sends `reply` (base64 encoded) back to the Watch.
   * Rejects if this Data Message was already replied to, or is no longer waiting for a Reply.
   */
  reply: (reply: string) => Promise<void>;
  /**
   * @deprecated Call `reply` instead. `replyId` and `replyToDataMessage` will be removed in a
   * future major version.
   */
  replyId: string;
};

export type RnWatchConnectModuleEvents = {
  /** Triggered when the Watch's reachability status changes */
  onReachabilityChanged: (params: { isWatchReachable: boolean }) => void;
  /** Triggered when the Watch app installation status changes */
  onWatchAppInstallChanged: (params: { isWatchAppInstalled: boolean }) => void;
  /** Triggered when the Watch pairing status changes */
  onWatchPairedChanged: (params: { isWatchPaired: boolean }) => void;
  /** Triggered when a message is received from the Watch */
  onMessageReceived: (message: MessagePayload) => void;
  /** Triggered when a message requiring a reply is received from the Watch */
  onMessageWithReply: (event: MessageWithReplyEvent) => void;
  /** Triggered when a data message is received from the Watch */
  onDataMessageReceived: (messageData: { data: string }) => void;
  /** Triggered when a data message requiring a reply is received from the Watch */
  onDataMessageWithReply: (event: DataMessageWithReplyEvent) => void;
  /** Triggered when the application context changes */
  onApplicationContextChanged: (params: Record<string, any>) => void;
  /** Triggered when user info is received from the Watch */
  onUserInfoReceived: (params: Record<string, any>) => void;
  /** Triggered when a file is received from the Watch */
  onFileReceived: (params: File) => void;
  /** Triggered when a file from the Watch couldn't be kept (for example, the iPhone is out of storage). The file is lost. */
  onFileReceiveFailed: (event: FileReceiveFailedEvent) => void;
  /** Triggered exactly once per User Info Transfer: delivered (`error: null`), failed, or cancelled */
  onUserInfoTransferFinished: (event: UserInfoTransferFinishedEvent) => void;
  /** Triggered exactly once per File Transfer: delivered (`error: null`), failed, or cancelled */
  onFileTransferFinished: (event: FileTransferFinishedEvent) => void;
};

// Define the strict interface for the module
export interface RnWatchConnectInterface
  extends InstanceType<typeof EventEmitter<RnWatchConnectModuleEvents>> {
  // Properties
  readonly isWatchSupported: boolean;
  readonly isWatchPaired: boolean;
  readonly isWatchAppInstalled: boolean;
  readonly isWatchReachable: boolean;
  readonly watchActivationState: WatchActivationState;
  readonly applicationContext: Record<string, any>;
  readonly receivedApplicationContext: Record<string, any>;
  readonly outstandingUserInfoTransfers: OutstandingUserInfoTransfer[];
  readonly outstandingFileTransfers: FileTransfer[];
  // Message Methods
  /**
   * Sends a message to the Watch and waits for a reply.
   * @param message - The message to send
   * @returns A promise that resolves with the Watch's reply
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  sendMessage<T extends MessagePayload, R extends MessagePayload>(
    message: T
  ): Promise<R>;
  /**
   * Sends a message to the Watch without waiting for a reply.
   * @param message - The message to send
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  sendMessageWithoutReply<T extends MessagePayload>(message: T): Promise<void>;
  /**
   * Sends a reply to a message received from the Watch.
   * @param replyId - The ID of the message to reply to
   * @param reply - The message to send as a reply
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   * @deprecated Use the `reply` function from the event instead. Will be removed in a future
   * major version.
   * ```ts
   * useEventListener(RnWatchConnect, "onMessageWithReply", ({ message, reply }) => {
   *   reply({ ok: true });
   * });
   * ```
   */
  replyToMessage(replyId: string, reply: MessagePayload): Promise<void>;

  /**
   * Cancels a pending user info transfer.
   * @param transferId - The ID of the transfer to cancel
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  cancelUserInfoTransfer(transferId: string): {
    id: string;
  };

  // Data Message Methods
  /**
   * Sends a base64 encoded data message to the paired Watch and waits for a reply.
   * @param data - The base64 encoded string to send
   * @returns A promise that resolves with the Watch's base64 encoded string reply
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  sendDataMessage(data: string): Promise<string>;

  /**
   * Sends a base64 encoded data message to the paired Watch without waiting for a reply.
   * @param data - The base64 encoded string to send
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  sendDataMessageWithoutReply(data: string): Promise<void>;

  /**
   * Sends a reply to a data message received from the Watch.
   * @param replyId - The ID of the message to reply to
   * @param response - The base64 encoded string to send as a reply
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   * @deprecated Use the `reply` function from the event instead. Will be removed in a future
   * major version.
   * ```ts
   * useEventListener(RnWatchConnect, "onDataMessageWithReply", ({ data, reply }) => {
   *   reply("SGVsbG8gZnJvbSBpUGhvbmUh");
   * });
   * ```
   */
  replyToDataMessage(replyId: string, response: string): Promise<void>;

  /**
   * Updates the application context on the Watch.
   * @param applicationContext - The application context to update
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  updateApplicationContext<T extends Record<string, any>>(
    applicationContext: T
  ): Promise<void>;

  /**
   * Transfers user info to the Watch.
   * @param userInfo - The user info to transfer
   * @returns The transfer, in the same shape as `outstandingUserInfoTransfers`
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  transferUserInfo<T extends Record<string, any>>(
    userInfo: T
  ): OutstandingUserInfoTransfer;

  /**
   * Transfers a file to the Watch.
   * @param file - The file to transfer
   * @param metadata - The metadata to transfer
   * @returns The transfer, in the same shape as `outstandingFileTransfers`
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  transferFile(file: string, metadata?: Record<string, any>): FileTransfer;

  /**
   * Cancels a pending file transfer.
   * @param transferId - The ID of the transfer to cancel
   * @throws `ERR_UNSUPPORTED_PLATFORM` on platforms other than iOS. Check `isWatchSupported` first.
   */
  cancelFileTransfer(transferId: string): {
    id: string;
  };
}
