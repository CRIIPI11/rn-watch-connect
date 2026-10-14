import type {
  OutstandingUserInfoTransfer,
  FileTransfer,
  WatchConnectErrorCode,
} from "./RnWatchConnect.types";
import type { NativeRnWatchConnect } from "./RnWatchConnectNative.types";

const UNSUPPORTED_MESSAGE =
  "RnWatchConnect is only supported on iOS. WatchConnectivity is not available on this platform.";

/** The error every method throws or rejects with: same shape as Expo's CodedError. */
function unsupported(): Error & { code: WatchConnectErrorCode } {
  return Object.assign(new Error(UNSUPPORTED_MESSAGE), { code: "ERR_UNSUPPORTED_PLATFORM" as const });
}

/**
 * Fallback stub for non-iOS platforms.
 * Properties return safe defaults and methods throw a descriptive error with code ERR_UNSUPPORTED_PLATFORM.
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
    return Promise.reject(unsupported());
  },
  sendMessageWithoutReply(): Promise<never> {
    return Promise.reject(unsupported());
  },
  replyToMessage(): Promise<never> {
    return Promise.reject(unsupported());
  },
  sendDataMessage(): Promise<never> {
    return Promise.reject(unsupported());
  },
  sendDataMessageWithoutReply(): Promise<never> {
    return Promise.reject(unsupported());
  },
  replyToDataMessage(): Promise<never> {
    return Promise.reject(unsupported());
  },
  updateApplicationContext(): Promise<never> {
    return Promise.reject(unsupported());
  },
  transferUserInfo(): OutstandingUserInfoTransfer {
    throw unsupported();
  },
  cancelUserInfoTransfer(): { id: string } {
    throw unsupported();
  },
  transferFile(): FileTransfer {
    throw unsupported();
  },
  cancelFileTransfer(): { id: string } {
    throw unsupported();
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
