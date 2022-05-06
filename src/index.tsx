import React, { Component, createRef, RefObject, SyntheticEvent } from 'react';
import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewStyle,
  findNodeHandle,
  HostComponent,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-ar-viewer' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type ArEvent = SyntheticEvent<
  {},
  {
    requestId: number | string;
    result: string;
    error: string;
  }
>;
type ArErrorEvent = SyntheticEvent<{}, { message: string }>;

type ArViewerProps = {
  model: string;
  planeOrientation?: 'none' | 'vertical' | 'horizontal' | 'both';
  allowScale?: boolean;
  allowRotate?: boolean;
  allowTranslate?: boolean;
  lightEstimation?: boolean;
  manageDepth?: boolean;
  disableInstructions?: boolean;
  style?: ViewStyle;
  ref?: RefObject<HostComponent<ArViewerProps> | (() => never)>;
  onDataReturned: (e: ArEvent) => void;
  onError: (e: ArErrorEvent) => void | undefined;
};

type UIManagerArViewer = {
  Commands: {
    takeScreenshot: number;
  };
};

type ArViewUIManager = UIManager & {
  ArViewerView: UIManagerArViewer;
};

type ArInnerViewProps = Omit<
  ArViewerProps,
  'onDataReturned' | 'ref' | 'onError'
>;

const ComponentName = 'ArViewerView';

const ArViewerComponent =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ArViewerProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

export class ArViewerView extends Component<ArInnerViewProps> {
  // We need to keep track of all running requests, so we store a counter.
  private _nextRequestId = 1;
  // We also need to keep track of all the promises we created so we can
  // resolve them later.
  private _requestMap = new Map<
    number,
    {
      resolve: (result: string) => void;
      reject: (result: string) => void;
    }
  >();
  // Add a ref to the native view component
  private nativeRef: RefObject<HostComponent<ArViewerProps> | (() => never)>;

  constructor(props: ArInnerViewProps) {
    super(props);
    this.nativeRef = createRef<typeof ArViewerComponent>();
    // bind methods to current context
    this._onDataReturned = this._onDataReturned.bind(this);
    this._onError = this._onError.bind(this);
  }

  _onDataReturned(event: ArEvent) {
    // We grab the relevant data out of our event.
    const { result, error } = event.nativeEvent;
    const requestId = parseInt(event.nativeEvent.requestId as string, 10);
    // Then we get the promise we saved earlier for the given request ID.
    const promise = this._requestMap.get(requestId);
    if (promise) {
      if (result) {
        // If it was successful, we resolve the promise.
        promise.resolve(result);
      } else {
        // Otherwise, we reject it.
        promise.reject(error);
      }
      // Finally, we clean up our request map.
      this._requestMap.delete(requestId);
    }
  }

  _onError(event: ArErrorEvent) {
    // We grab the relevant data out of our event.
    const { message } = event.nativeEvent;
    console.warn(message);
  }

  /**
   * Takes a full screenshot of the rendered camera
   * @returns A promise resolving a base64 encoded image
   */
  takeScreenshot() {
    // Grab a new request ID and our request map.
    let requestId = this._nextRequestId++;
    let requestMap = this._requestMap;

    // We create a promise here that will be resolved once `_onRequestDone` is
    // called.
    let promise = new Promise<string>(function (resolve, reject) {
      requestMap.set(requestId, { resolve: resolve, reject: reject });
    });

    // Now just dispatch the command as before, adding the request ID to the
    // parameters.
    this.nativeRef.current &&
      UIManager.dispatchViewManagerCommand(
        findNodeHandle(this.nativeRef.current as unknown as number),
        (UIManager as ArViewUIManager)[
          ComponentName
        ].Commands.takeScreenshot.toString(),
        [requestId]
      );
    return promise;
  }

  render() {
    return (
      <ArViewerComponent
        ref={this.nativeRef}
        onDataReturned={this._onDataReturned}
        onError={this._onError}
        {...this.props}
      />
    );
  }
}
