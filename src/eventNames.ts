import type { RnWatchConnectModuleEvents } from "./RnWatchConnect.types";

type EventName = keyof RnWatchConnectModuleEvents;

/**
 * Every event the native module sends, as a runtime list. Mirrors `JSEvents.names` in
 * ios/Session/JSEvents.swift; src/__tests__/eventNames.test.ts fails if the two differ.
 * Internal: not exported from the package.
 */
export const EVENT_NAMES = [
  "onWatchPairedChanged",
  "onWatchAppInstallChanged",
  "onReachabilityChanged",
  "onMessageReceived",
  "onMessageWithReply",
  "onDataMessageReceived",
  "onDataMessageWithReply",
  "onApplicationContextChanged",
  "onUserInfoReceived",
  "onFileReceived",
  "onFileReceiveFailed",
  "onUserInfoTransferFinished",
  "onFileTransferFinished",
] as const satisfies readonly EventName[];

// Compile-time check: every event in RnWatchConnectModuleEvents is listed above.
type MissingEventNames = Exclude<EventName, (typeof EVENT_NAMES)[number]>;
const allEventsListed: [MissingEventNames] extends [never] ? true : MissingEventNames = true;
void allEventsListed;
