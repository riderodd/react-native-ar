function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import React, { Component, createRef } from 'react';
import { requireNativeComponent, UIManager, Platform, findNodeHandle } from 'react-native';
const LINKING_ERROR = `The package 'react-native-ar-viewer' doesn't seem to be linked. Make sure: \n\n` + Platform.select({
  ios: "- You have run 'pod install'\n",
  default: ''
}) + '- You rebuilt the app after installing the package\n' + '- You are not using Expo managed workflow\n';
const ComponentName = 'ArViewerView';
const ArViewerComponent = UIManager.getViewManagerConfig(ComponentName) != null ? requireNativeComponent(ComponentName) : () => {
  throw new Error(LINKING_ERROR);
};
export class ArViewerView extends Component {
  // We need to keep track of all running requests, so we store a counter.
  // We also need to keep track of all the promises we created so we can
  // resolve them later.
  // Add a ref to the native view component
  constructor(props) {
    super(props);

    _defineProperty(this, "_nextRequestId", 1);

    _defineProperty(this, "_requestMap", new Map());

    _defineProperty(this, "nativeRef", void 0);

    this.nativeRef = /*#__PURE__*/createRef(); // bind methods to current context

    this._onDataReturned = this._onDataReturned.bind(this);
    this._onError = this._onError.bind(this);
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

    this.nativeRef.current && UIManager.dispatchViewManagerCommand(findNodeHandle(this.nativeRef.current), UIManager[ComponentName].Commands.takeScreenshot.toString(), [requestId]);
    return promise;
  }

  render() {
    return /*#__PURE__*/React.createElement(ArViewerComponent, _extends({
      ref: this.nativeRef,
      onDataReturned: this._onDataReturned,
      onError: this._onError
    }, this.props));
  }

}
//# sourceMappingURL=index.js.map