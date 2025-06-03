import { useEventListener as expoUseEventListener } from "expo";
import { EventListener } from "./RnWatchConnect.types";

export function useEventListener<T>(
  module: any,
  eventName: string,
  listener: EventListener<T>
) {
  return expoUseEventListener(module, eventName, listener);
}
