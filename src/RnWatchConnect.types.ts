export type RnWatchConnectModuleEvents = {
  onReachabilityChanged: (params: { isWatchReachable: boolean }) => void;
  onWatchAppInstallChanged: (params: { isWatchAppInstalled: boolean }) => void;
  onWatchPairedChanged: (params: { isWatchPaired: boolean }) => void;
};
