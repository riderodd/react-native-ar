# Upgrading from 0.1.x

Version 0.2 rewrites the native layer for the React Native New Architecture. The JavaScript API (`ArViewerView` props, events and ref commands) is unchanged.

## Requirements

- React Native 0.80 or later, with the New Architecture enabled. The Legacy Architecture is no longer supported.
- Android `compileSdkVersion` 36 (default since React Native 0.81).
- iOS minimum version is the one of your React Native version.

## Android

- Sceneform has been replaced by [SceneView](https://github.com/SceneView/sceneview-android) 2.3. Sceneform has not been maintained since 2023 and its native libraries are not compatible with 16 KB memory pages, which Google Play requires for apps targeting Android 15+.
- The SceneView version can be overridden with `sceneViewVersion` in your root `build.gradle` `ext` block.
- `model` paths starting with `/` are now read as local files. `file://`, `content://` and `https://` URIs keep working.
- `takeScreenshot()` now rejects instead of never resolving when the capture fails.
- The plane detection hint animation has been rewritten and looks slightly different.

## iOS

- The view is now a Fabric component. Run `pod install` after upgrading.
- `onEnded`, `onModelPlaced` and `onModelRemoved` were wired to `onError`; they now fire as documented.
- A model that cannot be loaded now triggers `onError` instead of showing an alert.

## JavaScript

- `onError` events are forwarded to your `onError` prop. Without one, they are logged with `console.warn`.
- The Android camera permission request no longer shows a rationale dialog with placeholder texts.
- The package ships ES modules only (`lib/module`). Metro, Jest and modern bundlers resolve it out of the box.
