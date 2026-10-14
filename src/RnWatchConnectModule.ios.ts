import { requireNativeModule } from "expo";

import type { RnWatchConnectInterface } from "./RnWatchConnect.types";

// Loads the native module from JSI. RnWatchConnect.types.ts is the only description of its interface.
export default requireNativeModule<RnWatchConnectInterface>("RnWatchConnect");
