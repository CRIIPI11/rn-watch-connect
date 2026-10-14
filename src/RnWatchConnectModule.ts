import type { OutstandingUserInfoTransfer, FileTransfer } from "./RnWatchConnect.types";
import type { NativeRnWatchConnect } from "./RnWatchConnectNative.types";

const UNSUPPORTED_MESSAGE =
  "RnWatchConnect is only supported on iOS. WatchConnectivity is not available on this platform.";

/**
 * Fallback stub for non-iOS platforms.
 * Properties return safe defaults and methods throw a descriptive error.
 * Typed as NativeRnWatchConnect (no cast), so a missing or mistyped member is a compile error.
 */
const module: NativeRnWatchConnect = {
  isWatchSupported: false,
  isWatchPaired: false,
  isWatchAppInstalled: false,
  isWatchReachable: false,
  watchActivationState: "notActivated",
  applicationContext: {},
  receivedApplicationContext: {},
  outstandingUserInfoTransfers: [],
  outstandingFileTransfers: [],

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
  transferUserInfo(): OutstandingUserInfoTransfer {
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

  // No events are ever emitted on these platforms.
  addListener() {
    return { remove() {} };
  },
  removeListener() {},
  removeAllListeners() {},
  emit() {},
  listenerCount() {
    return 0;
  },
};

export default module;
