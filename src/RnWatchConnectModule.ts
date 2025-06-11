import { NativeModule, requireNativeModule } from "expo";

import {
  RnWatchConnectModuleEvents,
  RnWatchConnectInterface,
  OutstandingUserInfoTransfer,
  UserInfoTransfer,
} from "./RnWatchConnect.types";

// Declare the native module class with our strict interface
declare class RnWatchConnectModule
  extends NativeModule<RnWatchConnectModuleEvents>
  implements RnWatchConnectInterface
{
  // Properties
  readonly isWatchSupported: boolean;
  readonly isWatchPaired: boolean;
  readonly isWatchAppInstalled: boolean;
  readonly isWatchReachable: boolean;
  readonly watchActivationState: string;
  readonly applicationContext: any;
  readonly receivedApplicationContext: any;
  readonly outstandingUserInfoTransfers: OutstandingUserInfoTransfer[];

  // Message Methods
  sendMessage<T = Record<string, any>, R = Record<string, any>>(
    message: T
  ): Promise<R>;
  sendMessageWithoutReply<T = Record<string, any>>(message: T): Promise<void>;
  replyToMessage(replyId: string, reply: Record<string, any>): void;
  sendDataMessage(data: string): Promise<string>;
  sendDataMessageWithoutReply(data: string): Promise<void>;
  replyToDataMessage(replyId: string, response: string): void;
  updateApplicationContext<T = Record<string, any>>(
    applicationContext: T
  ): Promise<void>;
  transferUserInfo<T = Record<string, any>>(userInfo: T): UserInfoTransfer;
  cancelUserInfoTransfer(transferId: string): Promise<void>;
}

// This call loads the native module object from the JSI.
const module = requireNativeModule<RnWatchConnectModule>("RnWatchConnect");

// Export the module with the strict interface type
export default module as RnWatchConnectInterface;
