import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-ar-viewer' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type ArViewerProps = {
  model: string;
  planeOrientation?: "none" | "vertical" | "horizontal" | "both";
  style?: ViewStyle;
};

const ComponentName = 'ArViewerView';

export const ArViewerView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ArViewerProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };
