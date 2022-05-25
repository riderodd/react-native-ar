"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ArViewerView = void 0;

var _react = _interopRequireWildcard(require("react"));

var _reactNative = require("react-native");

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function (nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

const LINKING_ERROR = `The package 'react-native-ar-viewer' doesn't seem to be linked. Make sure: \n\n` + _reactNative.Platform.select({
  ios: "- You have run 'pod install'\n",
  default: ''
}) + '- You rebuilt the app after installing the package\n' + '- You are not using Expo managed workflow\n';
const ComponentName = 'ArViewerView';
const ArViewerComponent = _reactNative.UIManager.getViewManagerConfig(ComponentName) != null ? (0, _reactNative.requireNativeComponent)(ComponentName) : () => {
  throw new Error(LINKING_ERROR);
};

class ArViewerView extends _react.Component {
  // We need to keep track of all running requests, so we store a counter.
  // We also need to keep track of all the promises we created so we can
  // resolve them later.
  // Add a ref to the native view component
  constructor(props) {
    super(props);

    _defineProperty(this, "_nextRequestId", 1);

    _defineProperty(this, "_requestMap", new Map());

    _defineProperty(this, "nativeRef", void 0);

    this.state = {
      cameraPermission: _reactNative.Platform.OS !== 'android'
    };
    this.nativeRef = /*#__PURE__*/(0, _react.createRef)(); // bind methods to current context

    this._onDataReturned = this._onDataReturned.bind(this);
    this._onError = this._onError.bind(this);
  }

  componentDidMount() {
    if (!this.state.cameraPermission) {
      // asks permissions internally to correct a bug: https://github.com/SceneView/sceneview-android/issues/80
      _reactNative.PermissionsAndroid.request(_reactNative.PermissionsAndroid.PERMISSIONS.CAMERA).then(granted => {
        if (granted === _reactNative.PermissionsAndroid.RESULTS.GRANTED) {
          this.setState({
            cameraPermission: true
          });
        } else {
          this._onError({
            nativeEvent: {
              message: 'Cannot start without camera permission'
            }
          });
        }
      });
    }
  }

  _onDataReturned(event) {
    // We grab the relevant data out of our event.
    const {
      result,
      error
    } = event.nativeEvent;
    const requestId = parseInt(event.nativeEvent.requestId, 10); // Then we get the promise we saved earlier for the given request ID.

    const promise = this._requestMap.get(requestId);

    if (promise) {
      if (result) {
        // If it was successful, we resolve the promise.
        promise.resolve(result);
      } else {
        // Otherwise, we reject it.
        promise.reject(error);
      } // Finally, we clean up our request map.


      this._requestMap.delete(requestId);
    }
  }

  _onError(event) {
    // We grab the relevant data out of our event.
    const {
      message
    } = event.nativeEvent;
    console.warn(message);
  }
  /**
   * Takes a full screenshot of the rendered camera
   * @returns A promise resolving a base64 encoded image
   */


  takeScreenshot() {
    // Grab a new request ID and our request map.
    let requestId = this._nextRequestId++;
    let requestMap = this._requestMap; // We create a promise here that will be resolved once `_onRequestDone` is
    // called.

    let promise = new Promise(function (resolve, reject) {
      requestMap.set(requestId, {
        resolve: resolve,
        reject: reject
      });
    }); // Now just dispatch the command as before, adding the request ID to the
    // parameters.

    this.nativeRef.current && _reactNative.UIManager.dispatchViewManagerCommand((0, _reactNative.findNodeHandle)(this.nativeRef.current), _reactNative.UIManager[ComponentName].Commands.takeScreenshot, [requestId]);
    return promise;
  }
  /**
   * Reset the model positionning
   * @returns void
   */


  reset() {
    this.nativeRef.current && _reactNative.UIManager.dispatchViewManagerCommand((0, _reactNative.findNodeHandle)(this.nativeRef.current), _reactNative.UIManager[ComponentName].Commands.reset, []);
  }
  /**
   * Rotate the model
   * @returns void
   */


  rotate(pitch, yaw, roll) {
    this.nativeRef.current && _reactNative.UIManager.dispatchViewManagerCommand((0, _reactNative.findNodeHandle)(this.nativeRef.current), _reactNative.UIManager[ComponentName].Commands.rotateModel, [pitch, yaw, roll]);
  }

  render() {
    return this.state.cameraPermission && /*#__PURE__*/_react.default.createElement(ArViewerComponent, _extends({
      ref: this.nativeRef,
      onDataReturned: this._onDataReturned,
      onError: this._onError
    }, this.props));
  }

}

exports.ArViewerView = ArViewerView;
//# sourceMappingURL=index.js.map