import { ReactNode } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  View,
  ViewStyle,
} from "react-native";

import { useTheme } from "./theme";

export function Section({
  title,
  footer,
  children,
}: {
  title: string;
  footer?: string;
  children: ReactNode;
}) {
  const theme = useTheme();
  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: theme.secondaryText }]}>
        {title.toUpperCase()}
      </Text>
      <View style={[styles.card, { backgroundColor: theme.card }]}>
        {children}
      </View>
      {footer ? (
        <Text style={[styles.sectionFooter, { color: theme.secondaryText }]}>
          {footer}
        </Text>
      ) : null}
    </View>
  );
}

export function StatusPill({ label, on }: { label: string; on: boolean }) {
  const theme = useTheme();
  const color = on ? theme.success : theme.secondaryText;
  return (
    <View style={[styles.pill, { backgroundColor: theme.fill }]}>
      <View style={[styles.dot, { backgroundColor: color }]} />
      <Text style={[styles.pillText, { color: theme.text }]}>{label}</Text>
    </View>
  );
}

export function ActionButton({
  title,
  onPress,
  variant = "filled",
  busy = false,
  style,
}: {
  title: string;
  onPress: () => void | Promise<void>;
  variant?: "filled" | "tinted";
  busy?: boolean;
  style?: ViewStyle;
}) {
  const theme = useTheme();
  const filled = variant === "filled";
  return (
    <Pressable
      accessibilityRole="button"
      disabled={busy}
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: filled ? theme.tint : theme.fill },
        pressed && { opacity: 0.6 },
        style,
      ]}
    >
      {busy ? (
        <ActivityIndicator color={filled ? "#fff" : theme.tint} />
      ) : (
        <Text
          style={[styles.buttonText, { color: filled ? "#fff" : theme.tint }]}
        >
          {title}
        </Text>
      )}
    </Pressable>
  );
}

export function ButtonRow({ children }: { children: ReactNode }) {
  return <View style={styles.buttonRow}>{children}</View>;
}

export function ValueRow({ label, value }: { label: string; value: string }) {
  const theme = useTheme();
  return (
    <View style={styles.valueRow}>
      <Text style={[styles.valueLabel, { color: theme.secondaryText }]}>
        {label}
      </Text>
      <Text
        style={[styles.valueText, { color: theme.text }]}
        numberOfLines={3}
        selectable
      >
        {value}
      </Text>
    </View>
  );
}

export function ProgressBar({ progress }: { progress: number }) {
  const theme = useTheme();
  const clamped = Math.max(0, Math.min(1, progress || 0));
  return (
    <View style={[styles.track, { backgroundColor: theme.fill }]}>
      <View
        style={[
          styles.fill,
          { width: `${clamped * 100}%`, backgroundColor: theme.tint },
        ]}
      />
    </View>
  );
}

export const styles = StyleSheet.create({
  section: {
    marginHorizontal: 16,
    marginTop: 24,
  },
  sectionTitle: {
    fontSize: 13,
    marginBottom: 6,
    marginLeft: 16,
  },
  sectionFooter: {
    fontSize: 13,
    marginTop: 6,
    marginHorizontal: 16,
  },
  card: {
    borderRadius: 12,
    borderCurve: "continuous",
    padding: 16,
    gap: 12,
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  pillText: {
    fontSize: 13,
    fontWeight: "500",
  },
  button: {
    flex: 1,
    minHeight: 44,
    borderRadius: 10,
    borderCurve: "continuous",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 12,
  },
  buttonText: {
    fontSize: 15,
    fontWeight: "600",
    textAlign: "center",
  },
  buttonRow: {
    flexDirection: "row",
    gap: 10,
  },
  valueRow: {
    gap: 2,
  },
  valueLabel: {
    fontSize: 12,
  },
  valueText: {
    fontSize: 15,
    fontVariant: ["tabular-nums"],
  },
  track: {
    height: 6,
    borderRadius: 3,
    overflow: "hidden",
  },
  fill: {
    height: "100%",
    borderRadius: 3,
  },
});
