import { EventEmitter } from "expo";

export type MessagePayload = Record<string, any>;

export type RnWatchConnectModuleEvents<T = MessagePayload> = {
  onReachabilityChanged: (params: { isWatchReachable: boolean }) => void;
  onWatchAppInstallChanged: (params: { isWatchAppInstalled: boolean }) => void;
  onWatchPairedChanged: (params: { isWatchPaired: boolean }) => void;
  onMessageReceived: (message: T) => void;
  onMessageWithReply: (params: { message: T; replyId: string }) => void;
  onDataMessageReceived: (messageData: { data: string }) => void;
  onDataMessageWithReply: (params: { data: string; replyId: string }) => void;
};

export type EventListener<T = MessagePayload> = (event: T) => void;

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
  sendMessage<T = MessagePayload, R = MessagePayload>(message: T): Promise<R>;
  sendMessageWithoutReply<T = MessagePayload>(message: T): Promise<void>;
  replyToMessage(replyId: string, reply: MessagePayload): void;

  // Data Message Methods
  sendDataMessage(data: string): Promise<string>;
  sendDataMessageWithoutReply(data: string): Promise<void>;
  replyToDataMessage(replyId: string, response: string): void;
}
