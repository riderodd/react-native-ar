# react-native-ar-viewer
[![npm version](https://img.shields.io/npm/v/react-native-ar-viewer.svg)](https://www.npmjs.com/package/react-native-ar-viewer)

AR viewer for react native that uses Sceneform on Android and ARKit on iOS

## Installation

```sh
npm install react-native-ar-viewer
```

### Android
Required AR features:

- Add the following to your AndroidManifest.xml:

```xml
<meta-data android:name="com.google.ar.core" android:value="required" tools:replace="android:value" />
```

- If you already have `<meta-data android:name="com.google.ar.core" android:value="required" />` don't forget to add the `tools:replace="android:value"` attribute.

- Check that your `<manifest>` tag contains `xmlns:tools="http://schemas.android.com/tools"` attribute.

### iOS
- Remember to add `NSCameraUsageDescription` entry in your Info.plist with a text explaining why you request camera permission.

- In XCode file tree, go to Pods > Development pods > react-native-ar-viewer, right-click on "Add Files to Pods"... Then select the environment.skybox folder in your node_modules/react-native-ar-viewer/ios folder. In add file window, check "react-native-ar-viewer-ARViewerBundle". It should appear with a blue icon on the file tree. Check if res.hdr is present inside, if not, add it manually. It should look like that:
![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/mac-bundle-tree.png)

## File formats
The viewer only supports `USDZ` files for iOS and `GLB` for Android. Other formats may work, but are not officialy supported.

## Usage

You should download your model locally using for example React Native File System in order to run the viewer on iOS. Android supports natively file URL (https:// instead of file://)

```js
import { ArViewerView } from "react-native-ar-viewer";
import { Platform } from 'react-native';
// ...

<ArViewerView 
    style={{flex: 1}}
    model={Platform.OS === 'android' ? 'dice.glb' : 'dice.usdz'}
    lightEstimation
    manageDepth
    allowRotate
    allowScale
    allowTranslate
    disableInstantPlacement
    onStarted={() => console.log('started')}
    onEnded={() => console.log('ended')}
    onModelPlaced={() => console.log('model displayed')}
    onModelRemoved={() => console.log('model not visible anymore')}
    planeOrientation="both" />
```

### Props

| Prop | Type | Description | Required |
|---|---|---|---|
| `model`| `string` | Enables ambient light estimation (see below) | Yes |
| `lightEstimation`| `bool` | Enables ambient light estimation (see below) | No |
| `manageDepth` | `bool` | Enables depth estimation and occlusion (only iOS, see below) | No |
| `allowRotate` | `bool` | Allows to rotate model | No |
| `allowScale` | `bool` | Allows to scale model | No |
| `allowTranslate` | `bool` | Allows to translate model | No |
| `disableInstructions` | `bool` | Disables instructions view | No |
| `disableInstantPlacement` | `bool` | Disables placement on load | No |
| `planeOrientation` | `"horizontal"`, `"vertical"`, `"both"` or `"none"` | Sets plane orientation (default: `both`) | No |

#### lightEstimation:

| With | Without |
|---|---|
|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/light.jpg)|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/no-light.jpg)|

#### manageDepth:

| With | Without |
|---|---|
|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/depth.jpg)|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/no-depth.jpg)|

#### Others:

| allowRotate | allowScale | planeOrientation: both |
|---|---|---|
|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/rotate.gif)|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/scale.gif)|![](https://raw.githubusercontent.com/riderodd/react-native-ar/main/docs/planeOrientation.gif)|

### Events

| Prop | Parameter | Description |
|---|---|---|
| `onStarted` | `none` | Triggers on AR session started |
| `onEnded` | `none` | Triggers on AR session ended |
| `onModelPlaced` | `none` | Triggers when model is placed |
| `onModelRemoved` | `none` | Triggers when model is removed |
| `onError` | `{ message: string }` | Triggers on any error and returns an object containing the error message |

### Commands

Commands are sent using refs like the following example:

```js
  // ...
  const ref = React.useRef() as React.MutableRefObject<ArViewerView>;
  
  const reset = () => {
    ref.current?.reset();
  };
  
  return (
    <ArViewerView
      model={yourModel}
      ref={ref} />
  );
  // ...
```

| Command | Args | Return | Description |
|---|---|---|---|
| `reset()` | `none` | `void` | Removes model from plane |
| `rotate()` | `x, y, z` | `void` | Manually rotates the model using `yaw as x`, `pitch as y` and `roll as z` in degrees |
| `takeScreenshot()` | `none` | `Promise<String>` | Takes a screenshot of the current view (camera + model) and returns a base64 jpeg string as a promise |

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
