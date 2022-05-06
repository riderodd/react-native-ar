import * as React from 'react';

import {
  StyleSheet,
  View,
  Platform,
  TouchableHighlight,
  Text,
} from 'react-native';
import { ArViewerView } from 'react-native-ar-viewer';
import RNFS from 'react-native-fs';

export default function App() {
  const [localModelPath, setLocalModelPath] = React.useState<string>();
  const ref = React.useRef() as React.MutableRefObject<ArViewerView>;

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

  const takeSnapshot = () => {
    ref.current?.takeScreenshot().then(async (base64Image) => {
      const date = new Date();
      const filePath = `${
        RNFS.CachesDirectoryPath
      }/arscreenshot-${date.getFullYear()}-${date.getMonth()}-${date.getDay()}-${date.getHours()}-${date.getMinutes()}-${date.getSeconds()}.jpg`;
      await RNFS.writeFile(filePath, base64Image, 'base64');
      console.log('Screenshot written to ' + filePath);
    });
  };

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
          ref={ref}
        />
      )}
      <TouchableHighlight onPress={takeSnapshot} style={styles.button}>
        <Text>Take Snapshot</Text>
      </TouchableHighlight>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  button: {
    position: 'absolute',
    backgroundColor: 'white',
    padding: 10,
    bottom: 20,
    left: '35%',
  },
});
