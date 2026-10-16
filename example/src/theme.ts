import { useColorScheme } from "react-native";

const light = {
  background: "#F2F2F7",
  card: "#FFFFFF",
  text: "#000000",
  secondaryText: "#6C6C70",
  separator: "#E5E5EA",
  fill: "#EFEFF4",
  tint: "#0A84FF",
  success: "#34C759",
  warning: "#FF9500",
  danger: "#FF3B30",
};

const dark: typeof light = {
  background: "#000000",
  card: "#1C1C1E",
  text: "#FFFFFF",
  secondaryText: "#8E8E93",
  separator: "#38383A",
  fill: "#2C2C2E",
  tint: "#0A84FF",
  success: "#30D158",
  warning: "#FF9F0A",
  danger: "#FF453A",
};

export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === "dark" ? dark : light;
}

/** Accent colors the phone can push to the watch through application context. */
export const ACCENTS = ["#0A84FF", "#30D158", "#FF9F0A", "#FF375F", "#BF5AF2"];
