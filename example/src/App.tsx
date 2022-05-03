import * as React from 'react';

import { StyleSheet, View, Platform } from 'react-native';
import { ArViewerView } from 'react-native-ar-viewer';
import RNFS from 'react-native-fs'

export default function App() {
  const [localModelPath, setLocalModelPath] = React.useState<string>();

  const loadPath = async () => {
    const localModelPath = (await (Platform.OS === "android" ?
    (await RNFS.readDirAssets('/assets/src/dice.usdz')).pop() :
    RNFS.stat(RNFS.MainBundlePath + "/assets/src/dice.usdz")))?.path;
    setLocalModelPath(localModelPath);
  }

  React.useEffect(() => {
    loadPath();
  })
  
  return (
    <View style={styles.container}>
      {localModelPath && <ArViewerView model={localModelPath} style={styles.container} />}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
