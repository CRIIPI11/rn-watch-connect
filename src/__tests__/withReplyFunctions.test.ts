import type { NativeRnWatchConnect } from "../RnWatchConnectNative.types";
import { withReplyFunctions } from "../withReplyFunctions";

type Listener = (...args: any[]) => void;

/** Just enough of the native module: an event emitter, a property and the two reply methods. */
function makeFakeNative() {
  const listeners = new Map<string, Set<Listener>>();
  const fake = {
    isWatchReachable: true,
    replyToMessage: jest.fn((_replyId: string, _reply: object) => Promise.resolve()),
    replyToDataMessage: jest.fn((_replyId: string, _data: string) => Promise.resolve()),
    addListener(eventName: string, listener: Listener) {
      if (!listeners.has(eventName)) listeners.set(eventName, new Set());
      listeners.get(eventName)!.add(listener);
      return { remove: () => fake.removeListener(eventName, listener) };
    },
    removeListener(eventName: string, listener: Listener) {
      listeners.get(eventName)?.delete(listener);
    },
    removeAllListeners(eventName: string) {
      listeners.delete(eventName);
    },
    emit(eventName: string, ...args: any[]) {
      listeners.get(eventName)?.forEach((listener) => listener(...args));
    },
    listenerCount(eventName: string) {
      return listeners.get(eventName)?.size ?? 0;
    },
  };
  return fake;
}

function setUp() {
  const native = makeFakeNative();
  const module = withReplyFunctions(native as unknown as NativeRnWatchConnect);
  return { native, module };
}

describe("withReplyFunctions", () => {
  it("gives onMessageWithReply a reply function that replies to that Message", async () => {
    const { native, module } = setUp();
    const listener = jest.fn();
    module.addListener("onMessageWithReply", listener);

    native.emit("onMessageWithReply", { message: { q: 1 }, replyId: "r1" });

    const event = listener.mock.calls[0][0];
    expect(event.message).toEqual({ q: 1 });
    await event.reply({ ok: true });
    expect(native.replyToMessage).toHaveBeenCalledWith("r1", { ok: true });
  });

  it("gives onDataMessageWithReply a reply function that replies to that Data Message", async () => {
    const { native, module } = setUp();
    const listener = jest.fn();
    module.addListener("onDataMessageWithReply", listener);

    native.emit("onDataMessageWithReply", { data: "AQ==", replyId: "r2" });

    const event = listener.mock.calls[0][0];
    expect(event.data).toBe("AQ==");
    await event.reply("Ag==");
    expect(native.replyToDataMessage).toHaveBeenCalledWith("r2", "Ag==");
  });

  it("keeps the deprecated replyId and replyTo… methods working", async () => {
    const { native, module } = setUp();
    const listener = jest.fn();
    module.addListener("onMessageWithReply", listener);

    native.emit("onMessageWithReply", { message: {}, replyId: "r3" });

    expect(listener.mock.calls[0][0].replyId).toBe("r3");
    await module.replyToMessage("r3", { ok: true });
    expect(native.replyToMessage).toHaveBeenCalledWith("r3", { ok: true });
  });

  it("passes the reply function's rejection through", async () => {
    const { native, module } = setUp();
    native.replyToMessage.mockRejectedValueOnce(new Error("Already replied"));
    const listener = jest.fn();
    module.addListener("onMessageWithReply", listener);

    native.emit("onMessageWithReply", { message: {}, replyId: "r4" });

    await expect(listener.mock.calls[0][0].reply({})).rejects.toThrow("Already replied");
  });

  it("passes other events through unchanged", () => {
    const { native, module } = setUp();
    const listener = jest.fn();
    module.addListener("onMessageReceived", listener);

    const message = { text: "hi" };
    native.emit("onMessageReceived", message);

    expect(listener).toHaveBeenCalledWith(message);
  });

  it("stops calling a listener after its subscription is removed", () => {
    const { native, module } = setUp();
    const listener = jest.fn();
    const subscription = module.addListener("onMessageWithReply", listener);

    subscription.remove();
    native.emit("onMessageWithReply", { message: {}, replyId: "r5" });

    expect(listener).not.toHaveBeenCalled();
    expect(module.listenerCount("onMessageWithReply")).toBe(0);
  });

  it("removeListener removes a wrapped listener", () => {
    const { native, module } = setUp();
    const listener = jest.fn();
    module.addListener("onDataMessageWithReply", listener);

    module.removeListener("onDataMessageWithReply", listener);
    native.emit("onDataMessageWithReply", { data: "", replyId: "r6" });

    expect(listener).not.toHaveBeenCalled();
    expect(module.listenerCount("onDataMessageWithReply")).toBe(0);
  });

  it("reads properties live from the native module", () => {
    const { native, module } = setUp();
    expect(module.isWatchReachable).toBe(true);

    native.isWatchReachable = false;

    expect(module.isWatchReachable).toBe(false);
  });
});
