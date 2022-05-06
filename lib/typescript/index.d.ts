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
    onError: (e: ArErrorEvent) => void | undefined;
};
declare type ArInnerViewProps = Omit<ArViewerProps, 'onDataReturned' | 'ref' | 'onError'>;
export declare class ArViewerView extends Component<ArInnerViewProps> {
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
    render(): JSX.Element;
}
export {};
