// Reexport the native module. On iOS it resolves to RnWatchConnectModule.ios.ts (native module),
// on all other platforms it resolves to the RnWatchConnectModule.ts fallback stub.
export { default } from "./RnWatchConnectModule";
export * from "./RnWatchConnect.types";
