import ARKit
import RealityKit
import SwiftUI

@available(iOS 13.0, *)
@objc(ArViewerViewManager)
class ArViewerViewManager: RCTViewManager {
    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }
        
    override func view() -> UIView {
        return ArViewerView()
    }
    
    @objc func reset(_ node : NSNumber){
        RCTExecuteOnMainQueue {
            if let view = self.bridge.uiManager.view(forReactTag: node) as? ArViewerView {
                view.reset()
            }
        }
    }
    
    @objc func takeScreenshot(_ node : NSNumber, withRequestId requestId: NSNumber){
        RCTExecuteOnMainQueue {
            if let view = self.bridge.uiManager.view(forReactTag: node) as? ArViewerView {
                view.takeScreenshot(requestId: requestId.intValue)
            }
        }
    }
    
    @objc func rotateModel(_ node : NSNumber, withPitch pitch: NSNumber, withYaw yaw: NSNumber, withRoll roll: NSNumber){
        RCTExecuteOnMainQueue {
            if let view = self.bridge.uiManager.view(forReactTag: node) as? ArViewerView {
                view.rotateModel(pitch: pitch.intValue, yaw: yaw.intValue, roll: roll.intValue)
            }
        }
    }
}


extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
