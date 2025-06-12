import { useEvent, useEventListener } from "expo";
import RnWatchConnect from "rn-watch-connect";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import { useState, useEffect } from "react";
import { File, Paths } from "expo-file-system/next";
import { Buffer } from "buffer";
global.Buffer = Buffer;

type MyMessage = {
  message: string;
};

type MyReply = {
  response: string;
};

type TransferProgress = {
  id: string;
  name: string;
  completed: number;
  total: number;
  fraction: number;
  isTransferring: boolean;
};

export default function App() {
  const onReachabilityChanged = useEvent(
    RnWatchConnect,
    "onReachabilityChanged",
    {
      isWatchReachable: RnWatchConnect.isWatchReachable,
    }
  );
  const onWatchPairedChanged = useEvent(
    RnWatchConnect,
    "onWatchPairedChanged",
    {
      isWatchPaired: RnWatchConnect.isWatchPaired,
    }
  );
  const onWatchAppInstallChanged = useEvent(
    RnWatchConnect,
    "onWatchAppInstallChanged",
    {
      isWatchAppInstalled: RnWatchConnect.isWatchAppInstalled,
    }
  );
  const [messageReceived, setMessageReceived] = useState("");
  const [messageWithReplyReceived, setMessageWithReplyReceived] = useState("");
  const [dataMessageReceived, setDataMessageReceived] = useState("");
  const [dataMessageWithReplyReceived, setDataMessageWithReplyReceived] =
    useState("");
  const [applicationContext, setApplicationContext] = useState<any>(null);
  const [userInfo, setUserInfo] = useState<any>(null);
  const [activeTransfers, setActiveTransfers] = useState<TransferProgress[]>(
    []
  );

  useEventListener(RnWatchConnect, "onMessageReceived", (event: MyMessage) => {
    console.log("Message Received:", event);
    setMessageReceived(event.message);
  });

  useEventListener(RnWatchConnect, "onMessageWithReply", (event) => {
    console.log("Message With Reply:", event);
    setMessageWithReplyReceived(event.message.message);

    RnWatchConnect.replyToMessage(event.replyId, {
      response: "Hello ",
    });
  });

  useEventListener(RnWatchConnect, "onDataMessageReceived", (event) => {
    console.log(
      "Data Message Received:",
      event.data,
      Buffer.from(event.data, "base64").toString()
    );
    setDataMessageReceived(Buffer.from(event.data, "base64").toString());
  });

  useEventListener(RnWatchConnect, "onDataMessageWithReply", (event) => {
    console.log("Data Message With Reply:", event);
    setDataMessageWithReplyReceived(
      Buffer.from(event.data, "base64").toString()
    );
    RnWatchConnect.replyToDataMessage(
      event.replyId,
      "TWVzc2FnZSByZWNlaXZlZCBvbiBSZWFjdCBOYXRpdmUh"
    );
  });

  useEventListener(RnWatchConnect, "onApplicationContextChanged", (event) => {
    console.log("ApplicationContext Changed:", event);
    setApplicationContext(event);
  });

  useEventListener(RnWatchConnect, "onUserInfoReceived", (event) => {
    console.log("User Info Received:", event);
    setUserInfo(event);
  });

  useEventListener(RnWatchConnect, "onFileReceived", (event) => {
    console.log("File Received:", event);
  });

  useEffect(() => {
    if (activeTransfers.length === 0) return;

    const interval = setInterval(() => {
      const currentTransfers = RnWatchConnect.outstandingFileTransfers;

      setActiveTransfers((prev) => {
        const updated = prev.map((transfer) => {
          const current = currentTransfers.find((t) => t.id === transfer.id);
          if (!current) {
            return {
              ...transfer,
              isTransferring: false,
            };
          }

          return {
            ...transfer,
            completed: current.progress.fractionCompleted * transfer.total,
            total: transfer.total,
            fraction: current.progress.fractionCompleted,
            isTransferring: current.isTransferring,
          };
        });

        return updated.filter(
          (t) => t.isTransferring || Date.now() - (t as any).completedAt < 2000
        );
      });
    }, 500);

    return () => clearInterval(interval);
  }, [activeTransfers.length]);

  const ProgressBar = ({ progress }: { progress: number }) => {
    const progressValue = Math.max(0, Math.min(1, progress || 0));
    return (
      <View style={styles.iosProgressBar}>
        <View
          style={[
            styles.iosProgressFill,
            { width: `${Math.min(Math.max(progressValue * 100, 0), 100)}%` },
          ]}
        />
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>
          Watch Connectivity Module API Example{" "}
        </Text>
        <Group name="Watch State Properties">
          <Text>
            {`Is Watch Connectivity Supported: ${RnWatchConnect.isWatchSupported}`}
          </Text>
          <Text>
            {`Activation State: ${RnWatchConnect.watchActivationState}`}
          </Text>
          <Text>{`Is Watch Paired: ${RnWatchConnect.isWatchPaired}`}</Text>
          <Text>
            {`Is Watch App Installed: ${RnWatchConnect.isWatchAppInstalled}`}
          </Text>
          <Text>
            {`Is Watch Reachable: ${RnWatchConnect.isWatchReachable}`}
          </Text>
        </Group>
        <Group name="Watch State Events">
          <Text>{`Is Watch Paired: ${JSON.stringify(onWatchPairedChanged)}`}</Text>
          <Text>{`Is Watch App Installed: ${JSON.stringify(onWatchAppInstallChanged)}`}</Text>
          <Text>{`Is Watch Reachable: ${JSON.stringify(onReachabilityChanged)}`}</Text>
        </Group>
        <Group name="Send Message">
          <Button
            title="Send Message"
            onPress={async () => {
              try {
                const reply = await RnWatchConnect.sendMessage<
                  MyMessage,
                  MyReply
                >({
                  message: "Hello from React Native",
                });
                console.log("Reply:", reply);
              } catch (error) {
                console.log("Error:", error);
              }
            }}
          />
          <Button
            title="Send Message Without Reply"
            onPress={async () => {
              try {
                await RnWatchConnect.sendMessageWithoutReply({
                  message: "Hello from React Native without reply",
                });
              } catch (error) {
                console.log("Error:", error);
              }
            }}
          />
          <Text>{`Message With Reply Received: ${messageWithReplyReceived}`}</Text>
          <Text>{`Message Received: ${messageReceived}`}</Text>
        </Group>
        <Group name="Send Data Message">
          <Button
            title="Send Data Message"
            onPress={async () => {
              try {
                const reply = await RnWatchConnect.sendDataMessage(
                  "RGF0YSBtZXNzYWdlIHNlbnQgZnJvbSBpcGhvbmU="
                );

                console.log("Reply:", Buffer.from(reply, "base64").toString());
              } catch (error) {
                console.log("Error:", error);
              }
            }}
          />
          <Text>{`Data Message With Reply Received: ${dataMessageWithReplyReceived}`}</Text>
          <Text>{`Data Message Received: ${dataMessageReceived}`}</Text>
          <Button
            title="Send Data Message Without Reply"
            onPress={async () => {
              try {
                await RnWatchConnect.sendDataMessageWithoutReply(
                  "RGF0YSBtZXNzYWdlIHNlbnQgZnJvbSBpcGhvbmUgd2l0aG91dCByZXBseQ=="
                );
              } catch (error) {
                console.log("Error:", error);
              }
            }}
          />
        </Group>
        <Group name="ApplicationContext">
          <Text>{`ApplicationContext: ${JSON.stringify(applicationContext)}`}</Text>
          <Button
            title="Update Application Context"
            onPress={async () => {
              try {
                await RnWatchConnect.updateApplicationContext({
                  theme: "red",
                });
              } catch (error) {
                console.log("Error:", error);
              }
            }}
          />
        </Group>
        <Group name="User Info">
          <Text>{`User Info: ${JSON.stringify(userInfo)}`}</Text>
          <Button
            title="Transfer User Info"
            onPress={async () => {
              RnWatchConnect.transferUserInfo({
                name: `User`,
                age: 20,
                timestamp: Date.now(),
              });
            }}
          />
        </Group>
        <Group name="File Transfer">
          {activeTransfers.length > 0 ? (
            <View style={styles.transfersList}>
              {activeTransfers.map((transfer) => {
                // Calculate sizes in MB with proper precision
                const completedMB = (
                  transfer.completed /
                  (1024 * 1024)
                ).toFixed(2);
                const totalMB = (transfer.total / (1024 * 1024)).toFixed(2);
                const percentage = (transfer.fraction * 100).toFixed(1);

                return (
                  <View key={transfer.id} style={styles.transferItem}>
                    <Text style={styles.transferName}>{transfer.name}</Text>
                    <ProgressBar progress={transfer.fraction} />
                    <Text style={styles.progressText}>
                      {`${completedMB}MB / ${totalMB}MB (${percentage}%)`}
                    </Text>
                    <Text style={styles.progressStatus}>
                      {transfer.isTransferring
                        ? "Transferring..."
                        : "Transfer Complete!"}
                    </Text>
                  </View>
                );
              })}
            </View>
          ) : (
            <Text>No active transfers</Text>
          )}
          <Button
            title="Transfer Large File"
            onPress={async () => {
              // Create a large file for testing progress
              try {
                const file = new File(Paths.cache, "large_example2.txt");
                if (!file.exists) {
                  file.create();
                  // Create a 10MB file by repeating text
                  const chunk =
                    "This is a test chunk of data that will be repeated many times to create a large file for testing transfer progress. ";
                  const repetitions = Math.ceil(
                    (34 * 1024 * 1024) / chunk.length
                  ); // Aim for ~10MB
                  let content = "";
                  for (let i = 0; i < repetitions; i++) {
                    content += chunk;
                  }
                  file.write(content);
                  console.log("Created file of size:", file.size, "bytes");
                }

                const transfer = RnWatchConnect.transferFile(
                  `${Paths.cache.uri}/large_example2.txt`,
                  {
                    name: "Large File Test 2",
                    size: file.size || 0,
                  }
                );
                console.log("Transfer started:", transfer);

                // Add new transfer to active transfers with correct size
                setActiveTransfers((prev) => [
                  ...prev,
                  {
                    id: transfer.id,
                    name: "Large File Test 2",
                    completed: 0,
                    total: file.size || 0,
                    fraction: 0,
                    isTransferring: true,
                  },
                ]);
              } catch (error) {
                console.error("Transfer error:", error);
              }
            }}
          />
          <Button
            title="Transfer Small File"
            onPress={async () => {
              try {
                const file = new File(Paths.cache, "example.txt");
                if (!file.exists) {
                  file.create();
                  file.write("Hello, world!");
                }

                const transfer = RnWatchConnect.transferFile(
                  `${Paths.cache.uri}/example.txt`,
                  {
                    name: "Small Text File",
                    size: file.size || 0,
                  }
                );
                console.log("Transfer:", transfer);

                // Add new transfer to active transfers with correct size
                setActiveTransfers((prev) => [
                  ...prev,
                  {
                    id: transfer.id,
                    name: "Small Text File",
                    completed: 0,
                    total: file.size || 0,
                    fraction: 0,
                    isTransferring: true,
                  },
                ]);
              } catch (error) {
                console.error(error);
              }
            }}
          />
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
  view: {
    flex: 1,
    height: 400,
  },
  iosProgressBar: {
    width: "100%" as any,
    height: 2,
    backgroundColor: "#e0e0e0",
    borderRadius: 2,
    marginVertical: 10,
    overflow: "hidden" as const,
  },
  iosProgressFill: {
    height: "100%" as any,
    backgroundColor: "#007AFF",
  },
  progressContainer: {
    marginVertical: 10,
    padding: 10,
    backgroundColor: "#f5f5f5",
    borderRadius: 8,
  },
  progressText: {
    textAlign: "center" as const,
    marginTop: 5,
    fontSize: 12,
    color: "#666",
  },
  progressStatus: {
    textAlign: "center" as const,
    marginTop: 5,
    fontSize: 14,
    fontWeight: "700" as const,
    color: "#007AFF",
  },
  transfersList: {
    marginBottom: 15,
  },
  transferItem: {
    marginBottom: 15,
    padding: 10,
    backgroundColor: "#f5f5f5",
    borderRadius: 8,
  },
  transferName: {
    fontSize: 16,
    fontWeight: "600" as const,
    marginBottom: 5,
  },
};
