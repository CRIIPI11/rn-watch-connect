import type { EventEmitter } from "expo";

import type {
  MessagePayload,
  RnWatchConnectInterface,
  RnWatchConnectModuleEvents,
} from "./RnWatchConnect.types";

/**
 * The events as the native module sends them. Mirrors `JSEvents` in ios/Session/JSEvents.swift.
 * Same as the public `RnWatchConnectModuleEvents`, except that the reply events carry only a
 * `replyId`: `withReplyFunctions` adds the `reply` function on the JS side.
 * Internal: not exported from the package.
 */
export type NativeModuleEvents = Omit<
  RnWatchConnectModuleEvents,
  "onMessageWithReply" | "onDataMessageWithReply"
> & {
  onMessageWithReply: (params: { message: MessagePayload; replyId: string }) => void;
  onDataMessageWithReply: (params: { data: string; replyId: string }) => void;
};

type EventEmitterMember = keyof InstanceType<typeof EventEmitter>;

/** The native module (or the non-iOS stub) before `withReplyFunctions` wraps it. Internal. */
export type NativeRnWatchConnect = Omit<RnWatchConnectInterface, EventEmitterMember> &
  InstanceType<typeof EventEmitter<NativeModuleEvents>>;
