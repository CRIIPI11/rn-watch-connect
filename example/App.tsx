import { useEvent, useEventListener } from "expo";
import { File } from "expo-file-system";
import { StatusBar } from "expo-status-bar";
import { useCallback, useRef, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from "react-native-safe-area-context";
import RnWatchConnect from "rn-watch-connect";

import {
  ActionButton,
  ButtonRow,
  ProgressBar,
  Section,
  StatusPill,
  ValueRow,
} from "./src/components";
import {
  base64ToText,
  describe,
  formatBytes,
  textToBase64,
} from "./src/encoding";
import { ACCENTS, useTheme } from "./src/theme";
import { useFileTransfers } from "./src/useFileTransfers";
import { useOutstandingUserInfo } from "./src/useOutstandingUserInfo";

// Shared with the watch app in targets/watch/ConnectivityStore.swift.
type TextMessage = { text: string };
type TextReply = { reply: string };

type LogEntry = {
  id: number;
  time: Date;
  kind: "in" | "out" | "error";
  title: string;
  detail: string;
};

/** A received file's text, or why it can't be read. */
function readText(uri: string): string {
  try {
    return new File(uri).textSync();
  } catch (error) {
    return `(can't read: ${error instanceof Error ? error.message : String(error)})`;
  }
}

/** Short Transfer id for the Activity log, to match a start with its finish event. */
const shortId = (id: string) => id.slice(0, 8);

const isEmpty = (value: unknown) =>
  value == null ||
  (typeof value === "object" && Object.keys(value).length === 0);

export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar style="auto" />
      <ExampleScreen />
    </SafeAreaProvider>
  );
}

function ExampleScreen() {
  const theme = useTheme();
  const insets = useSafeAreaInsets();

  const { isWatchPaired } = useEvent(RnWatchConnect, "onWatchPairedChanged", {
    isWatchPaired: RnWatchConnect.isWatchPaired,
  });
  const { isWatchAppInstalled } = useEvent(
    RnWatchConnect,
    "onWatchAppInstallChanged",
    { isWatchAppInstalled: RnWatchConnect.isWatchAppInstalled },
  );
  const { isWatchReachable } = useEvent(
    RnWatchConnect,
    "onReachabilityChanged",
    { isWatchReachable: RnWatchConnect.isWatchReachable },
  );

  const [messageText, setMessageText] = useState("Hello from React Native 👋");
  const [lastReply, setLastReply] = useState<string>();
  const [lastDataReply, setLastDataReply] = useState<string>();
  const [receivedContext, setReceivedContext] = useState<object>(
    RnWatchConnect.receivedApplicationContext,
  );
  const [sentAccent, setSentAccent] = useState<string>(
    RnWatchConnect.applicationContext?.accent,
  );
  const [receivedUserInfo, setReceivedUserInfo] = useState<object>();
  const [receivedFiles, setReceivedFiles] = useState<
    { name: string; uri: string; contents: string }[]
  >([]);
  const [log, setLog] = useState<LogEntry[]>([]);
  const [busy, setBusy] = useState<string>();
  // Lives in a ref so ids stay unique across Fast Refresh and repeated updater calls.
  const nextLogId = useRef(0);

  const {
    transfers,
    lastFinishedId,
    sendTestFile,
    sendMissingFile,
    cancel,
  } = useFileTransfers();
  const { outstanding: outstandingUserInfo, refresh: refreshUserInfo } =
    useOutstandingUserInfo();

  const addLog = useCallback(
    (kind: LogEntry["kind"], title: string, detail: unknown = "") => {
      const entry: LogEntry = {
        id: nextLogId.current++,
        time: new Date(),
        kind,
        title,
        detail: describe(detail),
      };
      setLog((prev) => [entry, ...prev].slice(0, 50));
    },
    [],
  );

  /** Runs an action, logging any error instead of letting it go unhandled. */
  const run = useCallback(
    async (key: string, action: () => unknown) => {
      setBusy(key);
      try {
        await action();
      } catch (error) {
        addLog("error", key, error instanceof Error ? error.message : error);
      } finally {
        setBusy(undefined);
      }
    },
    [addLog],
  );

  // ─── Incoming events from the watch ────────────────────────────────────────

  useEventListener(RnWatchConnect, "onMessageReceived", (message) => {
    addLog("in", "Message", message.text ?? message);
  });

  useEventListener(
    RnWatchConnect,
    "onMessageWithReply",
    ({ message, replyId }) => {
      addLog("in", "Message (replied)", message.text ?? message);
      RnWatchConnect.replyToMessage(replyId, {
        reply: `iPhone got: ${message.text ?? "your message"}`,
      } satisfies TextReply);
    },
  );

  useEventListener(RnWatchConnect, "onDataMessageReceived", ({ data }) => {
    addLog("in", "Data", base64ToText(data));
  });

  useEventListener(
    RnWatchConnect,
    "onDataMessageWithReply",
    ({ data, replyId }) => {
      const text = base64ToText(data);
      addLog("in", "Data (replied)", text);
      RnWatchConnect.replyToDataMessage(
        replyId,
        textToBase64(`iPhone got ${text.length} characters ✅`),
      );
    },
  );

  // Guard against empty payloads (older versions of the module replayed `{}` on subscribe).
  useEventListener(RnWatchConnect, "onApplicationContextChanged", (context) => {
    if (isEmpty(context)) return;
    setReceivedContext(context);
    addLog("in", "App context", context);
  });

  useEventListener(RnWatchConnect, "onUserInfoReceived", (userInfo) => {
    if (isEmpty(userInfo)) return;
    setReceivedUserInfo(userInfo);
    addLog("in", "User info", userInfo);
  });

  useEventListener(RnWatchConnect, "onFileReceived", (file) => {
    if (!file?.fileURL) return;
    const name = file.metadata?.name ?? file.fileURL.split("/").pop() ?? "file";
    // Read right away: "Re-read received files" later shows whether the file still holds this.
    const contents = readText(file.fileURL);
    setReceivedFiles((prev) => [{ name, uri: file.fileURL, contents }, ...prev]);
    addLog("in", "File", `${name}: ${contents}`);
  });

  useEventListener(RnWatchConnect, "onFileReceiveFailed", ({ message, fileName, metadata }) => {
    addLog("error", "File lost", `${metadata?.name ?? fileName}: ${message}`);
  });

  // Exactly one per transfer: delivered (error: null), failed, or cancelled.
  useEventListener(RnWatchConnect, "onFileTransferFinished", (transfer) => {
    const name = transfer.file.metadata?.name ?? "file";
    if (transfer.error) {
      addLog("error", "File transfer ended", `${name} · ${shortId(transfer.id)}: ${transfer.error.message}`);
    } else {
      addLog("in", "File delivered", `${name} · ${shortId(transfer.id)}`);
    }
  });

  useEventListener(RnWatchConnect, "onUserInfoTransferFinished", (transfer) => {
    if (transfer.error) {
      addLog(
        "error",
        "User info transfer ended",
        `${shortId(transfer.id)}: ${transfer.error.message}`,
      );
    } else {
      addLog("in", "User info delivered", shortId(transfer.id));
    }
  });
  // ─── UI ────────────────────────────────────────────────────────────────────

  return (
    <ScrollView
      style={{ backgroundColor: theme.background }}
      contentContainerStyle={{
        paddingTop: insets.top + 12,
        paddingBottom: insets.bottom + 32,
      }}
      contentInsetAdjustmentBehavior="never"
      keyboardDismissMode="interactive"
    >
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.text }]}>Watch Connect</Text>
        <Text style={[styles.subtitle, { color: theme.secondaryText }]}>
          rn-watch-connect example · session{" "}
          {RnWatchConnect.watchActivationState}
        </Text>
      </View>

      <Section
        title="Status"
        footer={
          RnWatchConnect.isWatchSupported
            ? isWatchReachable
              ? undefined
              : "Open the Watch Connect app on your Apple Watch to make it reachable for live messages."
            : "WatchConnectivity isn't supported on this device."
        }
      >
        <View style={styles.pills}>
          <StatusPill label="Supported" on={RnWatchConnect.isWatchSupported} />
          <StatusPill label="Paired" on={RnWatchConnect.isWatchPaired} />
          <StatusPill label="App installed" on={isWatchAppInstalled} />
          <StatusPill label="Reachable" on={isWatchReachable} />
        </View>
      </Section>

      <Section
        title="Messages"
        footer="Live messages need the watch app in the foreground."
      >
        <TextInput
          value={messageText}
          onChangeText={setMessageText}
          placeholder="Message text"
          placeholderTextColor={theme.secondaryText}
          style={[
            styles.input,
            { backgroundColor: theme.fill, color: theme.text },
          ]}
          returnKeyType="send"
        />
        <ButtonRow>
          <ActionButton
            title="Send"
            busy={busy === "Send message"}
            onPress={() =>
              run("Send message", async () => {
                addLog("out", "Message", messageText);
                const response = await RnWatchConnect.sendMessage<
                  TextMessage,
                  TextReply
                >({ text: messageText });
                setLastReply(response.reply);
                addLog("in", "Reply", response.reply);
              })
            }
          />
          <ActionButton
            title="Send, no reply"
            variant="tinted"
            onPress={() =>
              run("Send without reply", async () => {
                await RnWatchConnect.sendMessageWithoutReply<TextMessage>({
                  text: messageText,
                });
                addLog("out", "Message (no reply)", messageText);
              })
            }
          />
        </ButtonRow>
        <ValueRow label="Last reply" value={lastReply ?? "—"} />
      </Section>

      <Section
        title="Data messages"
        footer="Raw bytes, sent as base64 across the bridge."
      >
        <ButtonRow>
          <ActionButton
            title="Send data"
            busy={busy === "Send data"}
            onPress={() =>
              run("Send data", async () => {
                addLog("out", "Data", messageText);
                const reply = await RnWatchConnect.sendDataMessage(
                  textToBase64(messageText),
                );
                setLastDataReply(base64ToText(reply));
                addLog("in", "Data reply", base64ToText(reply));
              })
            }
          />
          <ActionButton
            title="Send, no reply"
            variant="tinted"
            onPress={() =>
              run("Send data without reply", async () => {
                await RnWatchConnect.sendDataMessageWithoutReply(
                  textToBase64(messageText),
                );
                addLog("out", "Data (no reply)", messageText);
              })
            }
          />
        </ButtonRow>
        <ValueRow label="Last data reply" value={lastDataReply ?? "—"} />
      </Section>

      <Section
        title="Application context"
        footer="Pick a color to tint the watch app. Only the latest context is delivered, even if the watch is asleep."
      >
        <View style={styles.swatches}>
          {ACCENTS.map((color) => (
            <Pressable
              key={color}
              accessibilityRole="button"
              accessibilityLabel={`Set watch accent to ${color}`}
              onPress={() =>
                run("Update app context", async () => {
                  const context = { accent: color, updatedAt: Date.now() };
                  await RnWatchConnect.updateApplicationContext(context);
                  setSentAccent(color);
                  addLog("out", "App context", context);
                })
              }
              style={[
                styles.swatch,
                { backgroundColor: color },
                sentAccent === color && {
                  borderColor: theme.text,
                  borderWidth: 3,
                },
              ]}
            />
          ))}
        </View>
        <ValueRow
          label="Received from watch"
          value={describe(isEmpty(receivedContext) ? null : receivedContext)}
        />
      </Section>

      <Section
        title="User info"
        footer="Queued and delivered in order, even in the background. Outstanding ones (including any from before a relaunch) are listed here and can be cancelled."
      >
        <ActionButton
          title="Transfer user info"
          onPress={() =>
            run("Transfer user info", () => {
              const info = { from: "iPhone", sentAt: new Date().toISOString() };
              const { id } = RnWatchConnect.transferUserInfo(info);
              addLog("out", "User info", `${shortId(id)} · ${describe(info)}`);
              refreshUserInfo();
            })
          }
        />
        {outstandingUserInfo.map((transfer) => (
          <View key={transfer.id} style={styles.transferHeader}>
            <Text style={[styles.caption, { color: theme.secondaryText }]}>
              {`Outstanding · ${shortId(transfer.id)}`}
            </Text>
            <Pressable
              onPress={() =>
                run("Cancel user info", () => {
                  RnWatchConnect.cancelUserInfoTransfer(transfer.id);
                  refreshUserInfo();
                })
              }
              hitSlop={8}
            >
              <Text style={{ color: theme.danger }}>Cancel</Text>
            </Pressable>
          </View>
        ))}
        <ValueRow
          label="Received from watch"
          value={describe(receivedUserInfo)}
        />
      </Section>

      <Section
        title="File transfers"
        footer={
          "Each transfer ends with exactly one finish event in Activity: delivered, failed, or cancelled.\n" +
          "Transfers still outstanding after a relaunch appear here with a new id, and can be cancelled.\n" +
          "Deleting the source file after starting doesn't stop a transfer: WatchConnectivity keeps its own copy. " +
          "Uninstalling the watch app leaves a transfer outstanding, with no finish event, until you cancel it (reinstalling doesn't deliver it)."
        }
      >
        <Text style={[styles.caption, { color: theme.secondaryText }]}>
          Succeeds
        </Text>
        <ButtonRow>
          <ActionButton
            title="Small file"
            onPress={() =>
              run("Transfer file", () => {
                const { id } = sendTestFile("hello.txt", 1024);
                addLog("out", "File", `hello.txt · 1 KB · ${shortId(id)}`);
              })
            }
          />
          <ActionButton
            title="5 MB file"
            variant="tinted"
            onPress={() =>
              run("Transfer file", () => {
                const { id } = sendTestFile("large.bin", 5 * 1024 * 1024);
                addLog("out", "File", `large.bin · 5 MB · ${shortId(id)}`);
              })
            }
          />
        </ButtonRow>
        <Text style={[styles.caption, { color: theme.secondaryText }]}>
          Slow enough to cancel while it sends
        </Text>
        <ActionButton
          title="Huge file · 50 MB"
          variant="tinted"
          onPress={() =>
            run("Transfer file", () => {
              const { id } = sendTestFile("huge.bin", 50 * 1024 * 1024);
              addLog("out", "File", `huge.bin · 50 MB · ${shortId(id)}`);
            })
          }
        />
        <Text style={[styles.caption, { color: theme.secondaryText }]}>
          Fails at start: throws, no transfer, no finish event
        </Text>
        <ButtonRow>
          <ActionButton
            title="Missing file"
            variant="tinted"
            onPress={() =>
              run("Missing file", () => {
                addLog("out", "File", "does-not-exist.bin");
                sendMissingFile();
              })
            }
          />
          <ActionButton
            title="Cancel finished"
            variant="tinted"
            onPress={() =>
              run("Cancel finished", () => {
                if (!lastFinishedId) {
                  addLog(
                    "error",
                    "Cancel finished",
                    "Send a file and let it finish first.",
                  );
                  return;
                }
                addLog(
                  "out",
                  "Cancel",
                  `finished transfer ${shortId(lastFinishedId)}`,
                );
                cancel(lastFinishedId);
              })
            }
          />
        </ButtonRow>
        {transfers.map((transfer) => (
          <View key={transfer.id} style={styles.transfer}>
            <View style={styles.transferHeader}>
              <Text style={[styles.transferName, { color: theme.text }]}>
                {transfer.name}
              </Text>
              {transfer.status === "sending" ? (
                <Pressable
                  onPress={() => run("Cancel", () => cancel(transfer.id))}
                  hitSlop={8}
                >
                  <Text style={{ color: theme.danger }}>Cancel</Text>
                </Pressable>
              ) : (
                <Text
                  style={{
                    color:
                      transfer.status === "delivered"
                        ? theme.success
                        : theme.danger,
                  }}
                >
                  {transfer.status === "delivered"
                    ? "Delivered"
                    : transfer.status === "cancelled"
                      ? "Cancelled"
                      : "Failed"}
                </Text>
              )}
            </View>
            <ProgressBar progress={transfer.fraction} />
            <Text style={[styles.caption, { color: theme.secondaryText }]}>
              {transfer.error && transfer.status === "failed"
                ? transfer.error
                : `${formatBytes(transfer.size * transfer.fraction)} of ${formatBytes(transfer.size)}`}
            </Text>
          </View>
        ))}
        <ValueRow
          label="Received from watch"
          value={
            receivedFiles.length
              ? receivedFiles.map((f) => f.name).join(", ")
              : "—"
          }
        />
        {receivedFiles.length > 0 && (
          <ActionButton
            title="Re-read received files"
            variant="tinted"
            onPress={() =>
              run("Re-read received files", () => {
                // Oldest first. A file whose contents changed since it arrived was overwritten.
                [...receivedFiles].reverse().forEach((file) => {
                  const now = readText(file.uri);
                  addLog(
                    now === file.contents ? "in" : "error",
                    now === file.contents
                      ? "Re-read: unchanged"
                      : "Re-read: overwritten",
                    `${file.name}: ${now}`,
                  );
                });
              })
            }
          />
        )}
      </Section>

      <Section title={`Activity${log.length ? ` (${log.length})` : ""}`}>
        {log.length === 0 ? (
          <Text style={{ color: theme.secondaryText }}>
            Events sent and received show up here.
          </Text>
        ) : (
          <>
            {log.map((entry) => (
              <View key={entry.id} style={styles.logRow}>
                <Text
                  style={[
                    styles.logIcon,
                    {
                      color:
                        entry.kind === "in"
                          ? theme.success
                          : entry.kind === "out"
                            ? theme.tint
                            : theme.danger,
                    },
                  ]}
                >
                  {entry.kind === "in" ? "↓" : entry.kind === "out" ? "↑" : "!"}
                </Text>
                <View style={styles.logBody}>
                  <Text style={[styles.logTitle, { color: theme.text }]}>
                    {entry.title}
                    <Text
                      style={{ color: theme.secondaryText, fontWeight: "400" }}
                    >
                      {"  "}
                      {entry.time.toLocaleTimeString()}
                    </Text>
                  </Text>
                  {entry.detail ? (
                    <Text
                      style={[styles.caption, { color: theme.secondaryText }]}
                      numberOfLines={3}
                    >
                      {entry.detail}
                    </Text>
                  ) : null}
                </View>
              </View>
            ))}
            <ActionButton
              title="Clear"
              variant="tinted"
              onPress={() => setLog([])}
            />
          </>
        )}
      </Section>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: 20,
    gap: 4,
  },
  title: {
    fontSize: 34,
    fontWeight: "700",
  },
  subtitle: {
    fontSize: 15,
  },
  pills: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  input: {
    minHeight: 44,
    borderRadius: 10,
    paddingHorizontal: 12,
    fontSize: 16,
  },
  swatches: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  swatch: {
    width: 44,
    height: 44,
    borderRadius: 22,
  },
  transfer: {
    gap: 6,
  },
  transferHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  transferName: {
    fontSize: 15,
    fontWeight: "600",
  },
  caption: {
    fontSize: 13,
  },
  logRow: {
    flexDirection: "row",
    gap: 10,
  },
  logIcon: {
    fontSize: 16,
    fontWeight: "700",
    width: 14,
    textAlign: "center",
  },
  logBody: {
    flex: 1,
    gap: 2,
  },
  logTitle: {
    fontSize: 15,
    fontWeight: "600",
  },
});
