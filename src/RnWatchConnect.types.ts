import { EventEmitter } from "expo";

export type MessagePayload = Record<string, any>;

export type OutstandingUserInfoTransfer = {
  id: string;
  userInfo: Record<string, any>;
  isTransferring: boolean;
};

export type UserInfoTransfer = {
  id: string;
  isTransferring: boolean;
};

export type RnWatchConnectModuleEvents = {
  /** Triggered when the Watch's reachability status changes */
  onReachabilityChanged: (params: { isWatchReachable: boolean }) => void;
  /** Triggered when the Watch app installation status changes */
  onWatchAppInstallChanged: (params: { isWatchAppInstalled: boolean }) => void;
  /** Triggered when the Watch pairing status changes */
  onWatchPairedChanged: (params: { isWatchPaired: boolean }) => void;
  /** Triggered when a message is received from the Watch */
  onMessageReceived: (message: any) => void;
  /** Triggered when a message requiring a reply is received from the Watch */
  onMessageWithReply: (params: { message: any; replyId: string }) => void;
  /** Triggered when a data message is received from the Watch */
  onDataMessageReceived: (messageData: { data: string }) => void;
  /** Triggered when a data message requiring a reply is received from the Watch */
  onDataMessageWithReply: (params: { data: string; replyId: string }) => void;
  /** Triggered when the application context changes */
  onApplicationContextChanged: (params: any) => void;
  /** Triggered when user info is received from the Watch */
  onUserInfoReceived: (params: any) => void;
};

// Define the strict interface for the module
export interface RnWatchConnectInterface
  extends InstanceType<typeof EventEmitter<RnWatchConnectModuleEvents>> {
  // Properties
  readonly isWatchSupported: boolean;
  readonly isWatchPaired: boolean;
  readonly isWatchAppInstalled: boolean;
  readonly isWatchReachable: boolean;
  readonly watchActivationState: string;
  readonly applicationContext: any;
  readonly receivedApplicationContext: any;
  readonly outstandingUserInfoTransfers: OutstandingUserInfoTransfer[];

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
  replyToMessage(replyId: string, reply: MessagePayload): void;

  /**
   * Cancels a pending user info transfer.
   * @param transferId - The ID of the transfer to cancel
   */
  cancelUserInfoTransfer(transferId: string): Promise<void>;

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
  replyToDataMessage(replyId: string, response: string): void;

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
   * @returns A promise that resolves with the transfer ID and isTransferring status: { id: string, isTransferring: boolean }
   */
  transferUserInfo<T extends Record<string, any>>(
    userInfo: T
  ): UserInfoTransfer;
}
