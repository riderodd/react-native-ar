# AGENTS.md

Guide for coding agents working on `react-native-ar-viewer`.

## Overview

React Native library that renders an AR model viewer: ARCore through [SceneView](https://github.com/SceneView/sceneview-android) (`ARSceneView`) on Android, ARKit and RealityKit on iOS. It is a Fabric view (`create-react-native-library` 0.64, type `fabric-view`, Kotlin + Objective-C++/Swift) for React Native 0.88.1 and the **New Architecture only**.

## Layout

- `src/ArViewerViewNativeComponent.ts`: Codegen spec (props, events, native commands). Source of truth for the native API.
- `src/ArViewerView.tsx`: public `ArViewerView` class component. Wraps the native commands as `takeScreenshot()` (promise resolved through `requestId` + `onDataReturned`), `reset()` and `rotate()`.
- `src/index.tsx`: public exports. Tests in `src/__tests__/` (Jest + `@testing-library/react-native`, native component mocked).
- `android/src/main/java/com/reactnativearviewer/`: Kotlin. `ArViewerViewManager` implements the generated `ArViewerViewManagerInterface` / `ArViewerViewManagerDelegate`, `ArViewerView` is the SceneView-based view, events are dispatched with `ArViewerEvent`.
- `ios/`: `RNArViewerComponentView.{h,mm}` is the Fabric wrapper (props, events, commands). It hosts the Swift `ArViewerView` (ARKit/RealityKit), imported through `react_native_ar_viewer-Swift.h`. Podspec: `react-native-ar-viewer.podspec`.
- `example/`: React Native 0.88 app, a Yarn workspace consuming the local library.
- `docs/UPGRADING.md`: 0.1.x to 0.2 migration notes. `README.md`, `CONTRIBUTING.md`: user and contributor docs.

## Setup and commands

Yarn 4 workspaces (root + `example`), Node from `.nvmrc`. If `yarn` is not on the PATH, use `node .yarn/releases/yarn-4.18.1.cjs`. Do not use npm.

```sh
yarn                  # install
yarn lint             # eslint "**/*.{js,ts,tsx}" (add --fix to format)
yarn typecheck        # tsc
yarn test             # jest
yarn prepare          # bob build -> lib/ (ES modules + type declarations)
yarn example start    # Metro
yarn example android  # run the example app on Android
yarn example ios      # run the example app on iOS (macOS only)
```

CI (`.github/workflows/ci.yml`) runs lint, typecheck, test, `yarn prepare`, and builds the example for Android (Ubuntu) and iOS (macOS) through turbo. Run lint, typecheck and test before finishing a change.

## Changing the native API

1. Edit the Codegen spec `src/ArViewerViewNativeComponent.ts` first (props, events, `NativeCommands` and `supportedCommands`). Optional props use `CodegenTypes.WithDefault<type, default>`.
2. Android: update `ArViewerViewManager.kt` (a `@ReactProp` override per prop, command overrides, event names in `ArViewerEvent.NAMES`) and `ArViewerView.kt`.
3. iOS: update `RNArViewerComponentView.mm` (`updateProps:`, `handleCommand:`, event emitters) and the Swift `ArViewerView`. Swift members used from Objective-C need `@objc`.
4. Update `ArViewerView.tsx`, the tests, and the README when the public API changes.

Keep both platforms in sync: a spec change that compiles on one platform only breaks the other build.

## Conventions

- Conventional commits (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `feat!` for breaking changes), enforced by commitlint through the lefthook `commit-msg` hook. The pre-commit hook runs eslint on staged files and `tsc`.
- Prettier (run through ESLint): single quotes, 2 spaces, `trailingComma: es5`, `quoteProps: consistent`. LF line endings, final newline (`.editorconfig`).
- No useless comments: the code should speak for itself, and a needed comment is one short sentence.
- Longer documentation goes in separate `.md` files (`docs/`, `README.md`), not in code comments.
- Releases use `release-it` (`yarn release`); the npm publish runs from the GitHub release workflow.

## Constraints

- New Architecture only: do not add Legacy Architecture (Paper / bridge view manager) code. Peer dependency is `react-native >= 0.80.0`.
- Android: `compileSdkVersion` 36, `minSdkVersion` 24, JVM 17, SceneView version in `android/build.gradle` (overridable through `sceneViewVersion` in the root `ext`). Native dependencies must be 16 KB page-size compliant (Google Play requirement). Do not reintroduce Sceneform: it is abandoned and not 16 KB compliant.
- iOS cannot be built or tested on Linux. Review Objective-C++ and Swift changes carefully against the generated types, and say when they could not be built.
- `ios/generated`, `android/generated`, `lib/`, `node_modules` and `.yarn/*` (except `releases`, `patches`, `plugins`, `sdks`, `versions`) are gitignored: never commit generated output. Codegen is configured by `codegenConfig` in `package.json` (`RNArViewerSpec`, iOS component class `RNArViewerComponentView`, Android package `com.reactnativearviewer`).
- The package ships ES modules only (`lib/module`) plus type declarations in `lib/typescript`.
