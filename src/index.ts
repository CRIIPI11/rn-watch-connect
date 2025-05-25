// Reexport the native module. On web, it will be resolved to RnWatchConnectModule.web.ts
// and on native platforms to RnWatchConnectModule.ts
export { default } from "./RnWatchConnectModule";
export * from "./RnWatchConnect.types";
