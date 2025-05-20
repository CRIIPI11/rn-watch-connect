import * as React from 'react';

import { RnWatchConnectViewProps } from './RnWatchConnect.types';

export default function RnWatchConnectView(props: RnWatchConnectViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
