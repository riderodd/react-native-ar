import { Component, RefObject, SyntheticEvent } from 'react';
import { ViewStyle, HostComponent } from 'react-native';
declare type ArEvent = SyntheticEvent<{}, {
    requestId: number | string;
    result: string;
    error: string;
}>;
declare type ArErrorEvent = SyntheticEvent<{}, {
    message: string;
}>;
declare type ArStatelessEvent = SyntheticEvent<{}, {}>;
declare type ArViewerProps = {
    model: string;
    planeOrientation?: 'none' | 'vertical' | 'horizontal' | 'both';
    allowScale?: boolean;
    allowRotate?: boolean;
    allowTranslate?: boolean;
    lightEstimation?: boolean;
    manageDepth?: boolean;
    disableInstructions?: boolean;
    disableInstantPlacement?: boolean;
    style?: ViewStyle;
    ref?: RefObject<HostComponent<ArViewerProps> | (() => never)>;
    onDataReturned: (e: ArEvent) => void;
    onError?: (e: ArErrorEvent) => void | undefined;
    onStarted?: (e: ArStatelessEvent) => void | undefined;
    onEnded?: (e: ArStatelessEvent) => void | undefined;
    onModelPlaced?: (e: ArStatelessEvent) => void | undefined;
    onModelRemoved?: (e: ArStatelessEvent) => void | undefined;
};
declare type ArInnerViewProps = Omit<ArViewerProps, 'onDataReturned' | 'ref' | 'onError'>;
declare type ArInnerViewState = {
    cameraPermission: boolean;
};
export declare class ArViewerView extends Component<ArInnerViewProps, ArInnerViewState> {
    private _nextRequestId;
    private _requestMap;
    private nativeRef;
    constructor(props: ArInnerViewProps);
    _onDataReturned(event: ArEvent): void;
    _onError(event: ArErrorEvent): void;
    /**
     * Takes a full screenshot of the rendered camera
     * @returns A promise resolving a base64 encoded image
     */
    takeScreenshot(): Promise<string>;
    /**
     * Reset the model positionning
     * @returns void
     */
    reset(): void;
    /**
     * Rotate the model
     * @returns void
     */
    rotate(pitch: number, yaw: number, roll: number): void;
    render(): false | JSX.Element;
}
export {};
