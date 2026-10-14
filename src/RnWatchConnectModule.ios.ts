import { requireNativeModule } from "expo";

import type { NativeRnWatchConnect } from "./RnWatchConnectNative.types";

// Loads the native module from JSI. RnWatchConnect.types.ts describes the public interface;
// RnWatchConnectNative.types.ts says how the native module differs from it (the reply events).
export default requireNativeModule<NativeRnWatchConnect>("RnWatchConnect");
