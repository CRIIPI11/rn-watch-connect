/** @type {import('@bacons/apple-targets/app.plugin').ConfigFunction} */
module.exports = () => ({
  type: "watch",
  name: "WatchConnectExample",
  displayName: "Watch Connect",
  // Resolves to `<ios.bundleIdentifier>.watchkitapp`, the id WatchConnectivity expects for the companion app.
  bundleIdentifier: ".watchkitapp",
  deploymentTarget: "11.0",
  icon: "../../assets/icon.png",
  colors: {
    $accent: "#0A84FF",
  },
  frameworks: ["SwiftUI", "WatchConnectivity"],
});
