import { readFileSync } from "node:fs";
import { join } from "node:path";

import { EVENT_NAMES } from "../eventNames";

/** The names in `static let names: [String] = [ ... ]` in ios/Session/JSEvents.swift. */
function swiftEventNames(): string[] {
  const source = readFileSync(join(__dirname, "../../ios/Session/JSEvents.swift"), "utf8");
  const list = source.match(/static let names: \[String\] = \[([\s\S]*?)\]/);
  if (!list) throw new Error("JSEvents.names not found in JSEvents.swift");
  return [...list[1].matchAll(/"(\w+)"/g)].map((match) => match[1]);
}

describe("JS event contract", () => {
  it("Swift sends exactly the events the TypeScript types declare", () => {
    expect([...swiftEventNames()].sort()).toEqual([...EVENT_NAMES].sort());
  });
});
