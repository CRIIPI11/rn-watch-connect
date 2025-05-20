import { NativeModule, requireNativeModule } from 'expo';

import { RnWatchConnectModuleEvents } from './RnWatchConnect.types';

declare class RnWatchConnectModule extends NativeModule<RnWatchConnectModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RnWatchConnectModule>('RnWatchConnect');
