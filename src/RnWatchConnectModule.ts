import {
  RnWatchConnectInterface,
  OutstandingUserInfoTransfer,
  UserInfoTransfer,
  FileTransfer,
} from "./RnWatchConnect.types";

const UNSUPPORTED_MESSAGE =
  "RnWatchConnect is only supported on iOS. WatchConnectivity is not available on this platform.";

/**
 * Fallback stub for non-iOS platforms.
 * Properties return safe defaults and methods throw a descriptive error.
 */
const module = {
  isWatchSupported: false,
  isWatchPaired: false,
  isWatchAppInstalled: false,
  isWatchReachable: false,
  watchActivationState: "notActivated",
  applicationContext: {},
  receivedApplicationContext: {},
  outstandingUserInfoTransfers: [] as OutstandingUserInfoTransfer[],
  outstandingFileTransfers: [] as FileTransfer[],

  sendMessage(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  sendMessageWithoutReply(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  replyToMessage(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  sendDataMessage(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  sendDataMessageWithoutReply(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  replyToDataMessage(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  updateApplicationContext(): Promise<never> {
    return Promise.reject(new Error(UNSUPPORTED_MESSAGE));
  },
  transferUserInfo(): UserInfoTransfer {
    throw new Error(UNSUPPORTED_MESSAGE);
  },
  cancelUserInfoTransfer(): { id: string } {
    throw new Error(UNSUPPORTED_MESSAGE);
  },
  transferFile(): FileTransfer {
    throw new Error(UNSUPPORTED_MESSAGE);
  },
  cancelFileTransfer(): { id: string } {
    throw new Error(UNSUPPORTED_MESSAGE);
  },

  addListener() {
    return { remove: () => { } };
  },
  removeListener() { },
  removeAllListeners() { },
  emit() { },
} as unknown as RnWatchConnectInterface;

export default module;
