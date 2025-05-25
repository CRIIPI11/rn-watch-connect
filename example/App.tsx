import { useEvent } from "expo";
import RnWatchConnect from "rn-watch-connect";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";

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
