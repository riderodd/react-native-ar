import type * as React from 'react';
import {
  codegenNativeCommands,
  codegenNativeComponent,
  type CodegenTypes,
  type HostComponent,
  type ViewProps,
} from 'react-native';

export type DataReturnedEvent = Readonly<{
  requestId: CodegenTypes.Int32;
  result: string;
  error: string;
}>;

export type ErrorEvent = Readonly<{
  message: string;
}>;

export type StatelessEvent = Readonly<{}>;

export interface NativeProps extends ViewProps {
  model: string;
  planeOrientation?: CodegenTypes.WithDefault<
    'none' | 'vertical' | 'horizontal' | 'both',
    'both'
  >;
  allowScale?: CodegenTypes.WithDefault<boolean, false>;
  allowRotate?: CodegenTypes.WithDefault<boolean, false>;
  allowTranslate?: CodegenTypes.WithDefault<boolean, false>;
  lightEstimation?: CodegenTypes.WithDefault<boolean, false>;
  manageDepth?: CodegenTypes.WithDefault<boolean, false>;
  disableInstructions?: CodegenTypes.WithDefault<boolean, false>;
  disableInstantPlacement?: CodegenTypes.WithDefault<boolean, false>;
  onDataReturned?: CodegenTypes.DirectEventHandler<DataReturnedEvent>;
  onError?: CodegenTypes.DirectEventHandler<ErrorEvent>;
  onStarted?: CodegenTypes.DirectEventHandler<StatelessEvent>;
  onEnded?: CodegenTypes.DirectEventHandler<StatelessEvent>;
  onModelPlaced?: CodegenTypes.DirectEventHandler<StatelessEvent>;
  onModelRemoved?: CodegenTypes.DirectEventHandler<StatelessEvent>;
}

interface NativeCommands {
  takeScreenshot: (
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    requestId: CodegenTypes.Int32
  ) => void;
  reset: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
  rotateModel: (
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    pitch: CodegenTypes.Double,
    yaw: CodegenTypes.Double,
    roll: CodegenTypes.Double
  ) => void;
}

export const Commands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['takeScreenshot', 'reset', 'rotateModel'],
});

export default codegenNativeComponent<NativeProps>(
  'ArViewerView'
) as HostComponent<NativeProps>;
