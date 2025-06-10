import { EventEmitter } from "expo";

export type MessagePayload = Record<string, any>;

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

  // Message Methods
  /**
   * Sends a message to the Watch and waits for a reply.
   * @param message - The message to send
   * @returns A promise that resolves with the Watch's reply
   */
  sendMessage<T = MessagePayload, R = MessagePayload>(message: T): Promise<R>;
  /**
   * Sends a message to the Watch without waiting for a reply.
   * @param message - The message to send
   */
  sendMessageWithoutReply<T = MessagePayload>(message: T): Promise<void>;
  /**
   * Sends a reply to a message received from the Watch.
   * @param replyId - The ID of the message to reply to
   * @param reply - The message to send as a reply
   */
  replyToMessage(replyId: string, reply: MessagePayload): void;

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
}
