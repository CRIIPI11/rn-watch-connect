// Node-only tests for the JS side (src/__tests__). Swift tests run with `npm run test:ios`.
// Babel instead of expo-module-scripts' SWC preset: its SWC plugin doesn't match the installed
// @swc/core, so that preset can't compile TypeScript here.
module.exports = {
  testEnvironment: "node",
  testRegex: "/__tests__/.*\\.test\\.ts$",
  transform: {
    "\\.ts$": ["babel-jest", { presets: ["@babel/preset-typescript"], plugins: ["@babel/plugin-transform-modules-commonjs"] }],
  },
};
