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

/** Why a Transfer finished without being delivered. `null` in a finish event means it was delivered. */
export type TransferFinishError = {
  message: string;
};

/** Sent exactly once per User Info Transfer, when it was delivered, failed or was cancelled. */
export type UserInfoTransferFinishedEvent = OutstandingUserInfoTransfer & {
  error: TransferFinishError | null;
};

/** Sent exactly once per File Transfer, when it was delivered, failed or was cancelled. */
export type FileTransferFinishedEvent = FileTransfer & {
  error: TransferFinishError | null;
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
  onMessageWithReply: (params: { message: MessagePayload; replyId: string }) => void;
  /** Triggered when a data message is received from the Watch */
  onDataMessageReceived: (messageData: { data: string }) => void;
  /** Triggered when a data message requiring a reply is received from the Watch */
  onDataMessageWithReply: (params: { data: string; replyId: string }) => void;
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
   */
  sendMessage<T extends MessagePayload, R extends MessagePayload>(
    message: T
  ): Promise<R>;
  /**
   * Sends a message to the Watch without waiting for a reply.
   * @param message - The message to send
   */
  sendMessageWithoutReply<T extends MessagePayload>(message: T): Promise<void>;
  /**
   * Sends a reply to a message received from the Watch.
   * @param replyId - The ID of the message to reply to
   * @param reply - The message to send as a reply
   */
  replyToMessage(replyId: string, reply: MessagePayload): Promise<void>;

  /**
   * Cancels a pending user info transfer.
   * @param transferId - The ID of the transfer to cancel
   */
  cancelUserInfoTransfer(transferId: string): {
    id: string;
  };

  // Data Message Methods
  /**
   * Sends a base64 encoded data message to the paired Watch and waits for a reply.
   * @param data - The base64 encoded string to send
   * @returns A promise that resolves with the Watch's base64 encoded string reply
   */
  sendDataMessage(data: string): Promise<string>;

  /**
   * Sends a base64 encoded data message to the paired Watch without waiting for a reply.
   * @param data - The base64 encoded string to send
   */
  sendDataMessageWithoutReply(data: string): Promise<void>;

  /**
   * Sends a reply to a data message received from the Watch.
   * @param replyId - The ID of the message to reply to
   * @param response - The base64 encoded string to send as a reply
   */
  replyToDataMessage(replyId: string, response: string): Promise<void>;

  /**
   * Updates the application context on the Watch.
   * @param applicationContext - The application context to update
   */
  updateApplicationContext<T extends Record<string, any>>(
    applicationContext: T
  ): Promise<void>;

  /**
   * Transfers user info to the Watch.
   * @param userInfo - The user info to transfer
   * @returns The transfer, in the same shape as `outstandingUserInfoTransfers`
   */
  transferUserInfo<T extends Record<string, any>>(
    userInfo: T
  ): OutstandingUserInfoTransfer;

  /**
   * Transfers a file to the Watch.
   * @param file - The file to transfer
   * @param metadata - The metadata to transfer
   * @returns The transfer, in the same shape as `outstandingFileTransfers`
   */
  transferFile(file: string, metadata?: Record<string, any>): FileTransfer;

  /**
   * Cancels a pending file transfer.
   * @param transferId - The ID of the transfer to cancel
   */
  cancelFileTransfer(transferId: string): {
    id: string;
  };
}
