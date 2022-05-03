import * as React from 'react';

import { StyleSheet, View, Platform } from 'react-native';
import { ArViewerView } from 'react-native-ar-viewer';
import RNFS from 'react-native-fs';

export default function App() {
  const [localModelPath, setLocalModelPath] = React.useState<string>();

  const loadPath = async () => {
    const modelPath = (
      await (Platform.OS === 'android'
        ? {
            path: 'https://github.com/KhronosGroup/glTF-Sample-Models/blob/master/2.0/Box/glTF-Binary/Box.glb?raw=true',
          }
        : RNFS.stat(RNFS.MainBundlePath + '/assets/src/dice.usdz'))
    )?.path;
    setLocalModelPath(modelPath);
  };

  React.useEffect(() => {
    loadPath();
  });

  return (
    <View style={styles.container}>
      {localModelPath && (
        <ArViewerView
          model={localModelPath}
          style={styles.container}
          lightEstimation
          allowScale
          allowRotate
          allowTranslate
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
