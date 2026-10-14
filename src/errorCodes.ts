import type { WatchConnectErrorCode } from "./RnWatchConnect.types";

/** The codes only the JS side produces (the non-iOS stub). */
export const JS_ONLY_ERROR_CODES = ["ERR_UNSUPPORTED_PLATFORM"] as const satisfies readonly WatchConnectErrorCode[];

/**
 * Every Error code, as a runtime list. Mirrors `ErrorCodes.all` in ios/Session/ErrorCodes.swift
 * plus JS_ONLY_ERROR_CODES; src/__tests__/errorCodes.test.ts fails if they differ.
 * Internal: not exported from the package.
 */
export const ERROR_CODES = [
  ...JS_ONLY_ERROR_CODES,
  "ERR_UNEXPECTED",
  "ERR_WATCH_NOT_REACHABLE",
  "ERR_REPLY_NOT_PENDING",
  "ERR_INVALID_BASE64",
  "ERR_INVALID_TRANSFER_ID",
  "ERR_INVALID_FILE_URL",
  "ERR_FILE_NOT_FOUND",
  "ERR_TRANSFER_CANCELLED",
  "ERR_FILE_RECEIVE_FAILED",
  "ERR_GENERIC_ERROR",
  "ERR_SESSION_NOT_SUPPORTED",
  "ERR_SESSION_MISSING_DELEGATE",
  "ERR_SESSION_NOT_ACTIVATED",
  "ERR_DEVICE_NOT_PAIRED",
  "ERR_WATCH_APP_NOT_INSTALLED",
  "ERR_INVALID_PARAMETER",
  "ERR_PAYLOAD_TOO_LARGE",
  "ERR_PAYLOAD_UNSUPPORTED_TYPES",
  "ERR_MESSAGE_REPLY_FAILED",
  "ERR_MESSAGE_REPLY_TIMED_OUT",
  "ERR_FILE_ACCESS_DENIED",
  "ERR_DELIVERY_FAILED",
  "ERR_INSUFFICIENT_SPACE",
  "ERR_SESSION_INACTIVE",
  "ERR_TRANSFER_TIMED_OUT",
  "ERR_COMPANION_APP_NOT_INSTALLED",
  "ERR_WATCH_ONLY_APP",
] as const satisfies readonly WatchConnectErrorCode[];

// Compile-time check: every WatchConnectErrorCode is listed above.
type MissingErrorCodes = Exclude<WatchConnectErrorCode, (typeof ERROR_CODES)[number]>;
const allCodesListed: [MissingErrorCodes] extends [never] ? true : MissingErrorCodes = true;
void allCodesListed;
