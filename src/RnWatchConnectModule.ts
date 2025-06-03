import { NativeModule, requireNativeModule } from 'expo';

import { RnWatchConnectModuleEvents } from './RnWatchConnect.types';

declare class RnWatchConnectModule<
  T = Record<string, any>,
> extends NativeModule<RnWatchConnectModuleEvents<T>> {
  isWatchSupported: boolean;
  isWatchPaired: boolean;
  isWatchAppInstalled: boolean;
  isWatchReachable: boolean;
  watchActivationState: string;
  sendMessage<T = { [key: string]: any }, R = { [key: string]: any }>(
    message: T
  ): Promise<R>;
  sendMessageWithoutReply<T = { [key: string]: any }>(
    message: T
  ): Promise<void>;
  replyToMessage(replyId: string, reply: { [key: string]: any }): void;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RnWatchConnectModule>('RnWatchConnect');
