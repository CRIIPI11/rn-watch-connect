// On iOS this resolves to RnWatchConnectModule.ios.ts (native module), on all other platforms
// to the RnWatchConnectModule.ts fallback stub. Both are wrapped to add the Reply functions.
import nativeModule from "./RnWatchConnectModule";
import { withReplyFunctions } from "./withReplyFunctions";

export default withReplyFunctions(nativeModule);
export * from "./RnWatchConnect.types";
