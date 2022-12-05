import { Component, RefObject, SyntheticEvent } from 'react';
import { ViewStyle, HostComponent } from 'react-native';
type ArEvent = SyntheticEvent<{}, {
    requestId: number | string;
    result: string;
    error: string;
}>;
type ArErrorEvent = SyntheticEvent<{}, {
    message: string;
}>;
type ArStatelessEvent = SyntheticEvent<{}, {}>;
type ArViewerProps = {
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
type ArInnerViewProps = Omit<ArViewerProps, 'onDataReturned' | 'ref' | 'onError'>;
type ArInnerViewState = {
    cameraPermission: boolean;
};
export declare class ArViewerView extends Component<ArInnerViewProps, ArInnerViewState> {
    private _nextRequestId;
    private _requestMap;
    private nativeRef;
    constructor(props: ArInnerViewProps);
    componentDidMount(): void;
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
//# sourceMappingURL=index.d.ts.map