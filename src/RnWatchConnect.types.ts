export type MessagePayload = Record<string, any>;

export type RnWatchConnectModuleEvents<T = MessagePayload> = {
  onReachabilityChanged: (params: { isWatchReachable: boolean }) => void;
  onWatchAppInstallChanged: (params: { isWatchAppInstalled: boolean }) => void;
  onWatchPairedChanged: (params: { isWatchPaired: boolean }) => void;
  onMessageReceived: (message: T) => void;
  onMessageWithReply: (params: { message: T; replyId: string }) => void;
};

export type EventListener<T = MessagePayload> = (event: T) => void;
