import { readFileSync } from "node:fs";
import { join } from "node:path";

import { ERROR_CODES, JS_ONLY_ERROR_CODES } from "../errorCodes";
import stub from "../RnWatchConnectModule";

/** The codes in `static let all: [String] = [ ... ]` in ios/Session/ErrorCodes.swift. */
function swiftErrorCodes(): string[] {
  const source = readFileSync(join(__dirname, "../../ios/Session/ErrorCodes.swift"), "utf8");
  const list = source.match(/static let all: \[String\] = \[([\s\S]*?)\]/);
  if (!list) throw new Error("ErrorCodes.all not found in ErrorCodes.swift");
  return [...list[1].matchAll(/"(\w+)"/g)].map((match) => match[1]);
}

describe("Error codes", () => {
  it("TypeScript lists exactly the codes Swift produces, plus the JS-only ones", () => {
    expect([...ERROR_CODES].sort()).toEqual([...swiftErrorCodes(), ...JS_ONLY_ERROR_CODES].sort());
  });

  it("has no duplicates", () => {
    expect(new Set(ERROR_CODES).size).toBe(ERROR_CODES.length);
  });

  it("the non-iOS stub reports WatchConnectivity as unsupported", () => {
    expect(stub.isWatchSupported).toBe(false);
    expect(stub.watchActivationState).toBe("unknown");
  });

  it("the non-iOS stub rejects and throws with ERR_UNSUPPORTED_PLATFORM", async () => {
    await expect(stub.sendMessage({})).rejects.toMatchObject({ code: "ERR_UNSUPPORTED_PLATFORM" });
    expect(() => stub.transferFile("file:///a.txt")).toThrow(
      expect.objectContaining({ code: "ERR_UNSUPPORTED_PLATFORM" }),
    );
  });
});
