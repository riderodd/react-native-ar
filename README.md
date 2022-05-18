# react-native-ar-viewer

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
    model={Platform.OS === 'android' ? 'Box.glb' : 'dice.usdz'}
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

| Prop | Type | Description |
|---|---|---|
| `lightEstimation`|| Enables ambient light estimation (see below) |
| `manageDepth` || Enables depth and occlusion estimation (see below) |
| `allowRotate` || Allows to rotate model |
| `allowScale` || Allows to scale model |
| `allowTranslate` || Allows to translate model |
| `disableInstructions` || Disables instructions messages |
| `disableInstantPlacement` || Disables placement on load |
| `planeOrientation` | `horizontal`, `vertical`, `both` or `none` | Sets plane orientation (default: `both`) |

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

- `onError`
- `onEnded`
- `onModelPlaced`
- `onModelRemoved`
- `onDataReturned`

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
      allowRotate
      allowScale
      allowTranslate
      ref={ref} />
  );
  // ...
```

| Command | Args | Description |
|---|---|---|
| `reset()` | `none` | Removes model from plane |
| `rotate()` | `x, y, z` | Manually rotates the model using euler angles |
| `takeScreenshot()` | `none` | Takes a screenshot of the current view (camera + model) |

### Android
Add/Merge and customize the following lines in your android/src/main/res/values/strings.xml
```
<resources>
    <string name="sceneview_searching_planes">Searching for surfaces...</string>
    <string name="sceneview_tap_on_surface">Tap on a surface to place an object.</string>
    <string name="sceneview_insufficient_features_message">Can\'t find anything.\n\nAim device at a surface with more texture or color.</string>
    <string name="sceneview_excessive_motion_message">Moving too fast.\n\nSlow down</string>
    <string name="sceneview_insufficient_light_message">Too dark.\n\nTry moving to a well-lit area.</string>
    <string name="sceneview_insufficient_light_android_s_message">Too dark. Try moving to a well-lit area.\n\nAlso, make sure the Block Camera is set to off in system settings.</string>
    <string name="sceneview_bad_state_message">Tracking lost due to bad internal state.\n\nPlease try restarting the AR experience.</string>
    <string name="sceneview_camera_unavailable_message">Another app is using the camera.\n\nTap on this app or try closing the other one.</string>
    <string name="sceneview_unknown_tracking_failure">Unknown tracking failure reason: %1$s</string>
    <string name="sceneview_camera_permission_required">Camera permission required</string>
</resources>
```


## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
