import { registerWebModule, NativeModule } from 'expo';

import { RnWatchConnectModuleEvents } from './RnWatchConnect.types';

class RnWatchConnectModule extends NativeModule<RnWatchConnectModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(RnWatchConnectModule, 'RnWatchConnectModule');
