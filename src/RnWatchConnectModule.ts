import { NativeModule, requireNativeModule } from 'expo';

import { RnWatchConnectModuleEvents } from './RnWatchConnect.types';

declare class RnWatchConnectModule extends NativeModule<RnWatchConnectModuleEvents> {
  isWatchSupported: boolean;
  isWatchPaired: boolean;
  isWatchAppInstalled: boolean;
  isWatchReachable: boolean;
  watchActivationState: string;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RnWatchConnectModule>('RnWatchConnect');
