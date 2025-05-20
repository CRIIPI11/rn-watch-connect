import { requireNativeView } from 'expo';
import * as React from 'react';

import { RnWatchConnectViewProps } from './RnWatchConnect.types';

const NativeView: React.ComponentType<RnWatchConnectViewProps> =
  requireNativeView('RnWatchConnect');

export default function RnWatchConnectView(props: RnWatchConnectViewProps) {
  return <NativeView {...props} />;
}
