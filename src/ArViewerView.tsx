import { Component, createRef, type ComponentRef } from 'react';
import {
  PermissionsAndroid,
  Platform,
  type NativeSyntheticEvent,
} from 'react-native';
import NativeArViewerView, {
  Commands,
  type DataReturnedEvent,
  type ErrorEvent,
  type NativeProps,
  type StatelessEvent,
} from './ArViewerViewNativeComponent';

export type ArDataReturnedEvent = NativeSyntheticEvent<DataReturnedEvent>;
export type ArErrorEvent = NativeSyntheticEvent<ErrorEvent>;
export type ArStatelessEvent = NativeSyntheticEvent<StatelessEvent>;

export type ArViewerProps = Omit<NativeProps, 'onDataReturned'>;

type ArViewerState = {
  cameraPermission: boolean;
};

type PendingRequest = {
  resolve: (result: string) => void;
  reject: (error: Error) => void;
};

export class ArViewerView extends Component<ArViewerProps, ArViewerState> {
  private nextRequestId = 1;
  private pendingRequests = new Map<number, PendingRequest>();
  private nativeRef = createRef<ComponentRef<typeof NativeArViewerView>>();

  state: ArViewerState = {
    cameraPermission: Platform.OS !== 'android',
  };

  componentDidMount() {
    if (this.state.cameraPermission) {
      return;
    }
    // The AR session cannot start before the camera permission is granted
    PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA).then(
      (status) => {
        if (status === PermissionsAndroid.RESULTS.GRANTED) {
          this.setState({ cameraPermission: true });
        } else {
          this.onError({
            nativeEvent: { message: 'Cannot start without camera permission' },
          } as ArErrorEvent);
        }
      }
    );
  }

  componentWillUnmount() {
    this.pendingRequests.forEach(({ reject }) =>
      reject(new Error('The AR view has been unmounted'))
    );
    this.pendingRequests.clear();
  }

  private onDataReturned = ({ nativeEvent }: ArDataReturnedEvent) => {
    const request = this.pendingRequests.get(nativeEvent.requestId);
    if (!request) {
      return;
    }
    this.pendingRequests.delete(nativeEvent.requestId);
    if (nativeEvent.result) {
      request.resolve(nativeEvent.result);
    } else {
      request.reject(new Error(nativeEvent.error || 'Unknown error'));
    }
  };

  private onError = (event: ArErrorEvent) => {
    if (this.props.onError) {
      this.props.onError(event);
    } else {
      console.warn(event.nativeEvent.message);
    }
  };

  /**
   * Takes a full screenshot of the rendered camera
   * @returns A promise resolving a base64 encoded JPEG image
   */
  takeScreenshot(): Promise<string> {
    const view = this.nativeRef.current;
    if (!view) {
      return Promise.reject(new Error('The AR view is not mounted'));
    }
    const requestId = this.nextRequestId++;
    const promise = new Promise<string>((resolve, reject) => {
      this.pendingRequests.set(requestId, { resolve, reject });
    });
    Commands.takeScreenshot(view, requestId);
    return promise;
  }

  /**
   * Removes the model from the scene and restarts plane detection
   */
  reset() {
    const view = this.nativeRef.current;
    if (view) {
      Commands.reset(view);
    }
  }

  /**
   * Rotates the model by the given angles, in degrees
   */
  rotate(pitch: number, yaw: number, roll: number) {
    const view = this.nativeRef.current;
    if (view) {
      Commands.rotateModel(view, pitch, yaw, roll);
    }
  }

  render() {
    if (!this.state.cameraPermission) {
      return null;
    }
    return (
      <NativeArViewerView
        {...this.props}
        ref={this.nativeRef}
        onDataReturned={this.onDataReturned}
        onError={this.onError}
      />
    );
  }
}
