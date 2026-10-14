import type { RnWatchConnectInterface } from "./RnWatchConnect.types";
import type { NativeRnWatchConnect } from "./RnWatchConnectNative.types";

type Listener = (...args: any[]) => void;

/**
 * Wraps the native module so the reply events carry a Reply function. Native events can only
 * carry plain values, so Swift sends a `replyId` and the `reply` function is added here.
 * Everything else, properties included, is read from the native module as is.
 */
export function withReplyFunctions(native: NativeRnWatchConnect): RnWatchConnectInterface {
  const addReply: Record<string, (event: any) => object> = {
    onMessageWithReply: (event) => ({
      ...event,
      reply: (reply: object) => native.replyToMessage(event.replyId, reply),
    }),
    onDataMessageWithReply: (event) => ({
      ...event,
      reply: (reply: string) => native.replyToDataMessage(event.replyId, reply),
    }),
  };

  // The wrapper given to the native module for each listener, so removeListener can find it.
  const wrappers = new Map<string, Map<Listener, Listener>>();

  function wrapperFor(eventName: string, listener: Listener): Listener {
    const transform = addReply[eventName];
    if (!transform) return listener;
    let byListener = wrappers.get(eventName);
    if (!byListener) wrappers.set(eventName, (byListener = new Map()));
    let wrapper = byListener.get(listener);
    if (!wrapper) {
      wrapper = (event: object) => listener(transform(event));
      byListener.set(listener, wrapper);
    }
    return wrapper;
  }

  const overrides = {
    addListener(eventName: string, listener: Listener) {
      const wrapper = wrapperFor(eventName, listener);
      const subscription = native.addListener(eventName as any, wrapper as any);
      return {
        remove() {
          subscription.remove();
          wrappers.get(eventName)?.delete(listener);
        },
      };
    },
    removeListener(eventName: string, listener: Listener) {
      native.removeListener(eventName as any, wrapperFor(eventName, listener) as any);
      wrappers.get(eventName)?.delete(listener);
    },
    removeAllListeners(eventName: string) {
      native.removeAllListeners(eventName as any);
      wrappers.delete(eventName);
    },
  };

  return new Proxy(native, {
    get(target, property) {
      if (Object.prototype.hasOwnProperty.call(overrides, property)) {
        return overrides[property as keyof typeof overrides];
      }
      const value = Reflect.get(target, property);
      // Native methods must be called on the native object.
      return typeof value === "function" ? value.bind(target) : value;
    },
  }) as unknown as RnWatchConnectInterface;
}
