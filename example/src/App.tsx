import { useEffect, useRef, useState } from 'react';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import {
  CachesDirectoryPath,
  DocumentDirectoryPath,
  downloadFile,
  exists,
  writeFile,
} from '@dr.pogodin/react-native-fs';
import { ArViewerView } from 'react-native-ar-viewer';

const extension = Platform.OS === 'android' ? 'glb' : 'usdz';
const modelUrl = `https://github.com/riderodd/react-native-ar/blob/main/example/src/dice.${extension}?raw=true`;

async function downloadModel() {
  const modelPath = `${DocumentDirectoryPath}/model.${extension}`;
  if (!(await exists(modelPath))) {
    await downloadFile({ fromUrl: modelUrl, toFile: modelPath }).promise;
  }
  return modelPath;
}

export default function App() {
  const [localModelPath, setLocalModelPath] = useState<string>();
  const [showArView, setShowArView] = useState(true);
  const ref = useRef<ArViewerView>(null);

  useEffect(() => {
    downloadModel().then(setLocalModelPath, console.error);
  }, []);

  const takeSnapshot = async () => {
    const base64Image = await ref.current?.takeScreenshot();
    if (!base64Image) {
      return;
    }
    const filePath = `${CachesDirectoryPath}/arscreenshot-${Date.now()}.jpg`;
    await writeFile(filePath, base64Image, 'base64');
    console.log('Screenshot written to ' + filePath);
  };

  return (
    <View style={styles.container}>
      {localModelPath && showArView && (
        <ArViewerView
          ref={ref}
          model={localModelPath}
          style={styles.arView}
          disableInstantPlacement
          manageDepth
          allowRotate
          allowScale
          allowTranslate
          onStarted={() => console.log('started')}
          onEnded={() => console.log('ended')}
          onModelPlaced={() => console.log('model displayed')}
          onModelRemoved={() => console.log('model not visible anymore')}
          onError={({ nativeEvent }) => console.warn(nativeEvent.message)}
        />
      )}
      <View style={styles.footer}>
        <Button title="Take Snapshot" onPress={takeSnapshot} />
        <Button
          title={showArView ? 'Unmount' : 'Mount'}
          onPress={() => setShowArView(!showArView)}
        />
        <Button title="Reset" onPress={() => ref.current?.reset()} />
        <Button title="Rotate" onPress={() => ref.current?.rotate(0, 25, 0)} />
      </View>
    </View>
  );
}

function Button({ title, onPress }: { title: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.button}>
      <Text>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
  },
  arView: {
    flex: 2,
  },
  footer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    flexWrap: 'wrap',
    flexDirection: 'row',
    backgroundColor: 'white',
  },
  button: {
    borderColor: 'black',
    borderWidth: 1,
    backgroundColor: 'white',
    padding: 10,
    margin: 5,
  },
});
