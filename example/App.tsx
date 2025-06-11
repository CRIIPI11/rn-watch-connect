import { useEvent, useEventListener } from "expo";
import RnWatchConnect from "rn-watch-connect";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import { useState } from "react";
import { Buffer } from "buffer";
global.Buffer = Buffer;

type MyMessage = {
  message: string;
};

type MyReply = {
  response: string;
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
};
