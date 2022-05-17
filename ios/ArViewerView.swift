import SwiftUI

class ArViewerView: UIView {

    var arViewController: RealityKitViewController!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        if arViewController == nil {
            // setup subview
            guard let parentViewController = parentViewController else { return }

            arViewController = RealityKitViewController()
            arViewController.view.frame = bounds
            parentViewController.addChild(arViewController)
            addSubview(arViewController.view)
            arViewController.didMove(toParent: parentViewController)
            
            arViewController.setUp()
            // re-run all setters now that the view is mounted
            arViewController.changePlaneOrientation(planeOrientation: planeOrientation)
            arViewController.changeInstructionVisibility(isVisible: !disableInstructions)
            arViewController.changeLightEstimationEnabled(isEnabled: lightEstimation)
            arViewController.changeDepthManagementEnabled(isEnabled: manageDepth)
            arViewController.changeInstantPlacementEnabled(isEnabled: !disableInstantPlacement)
            arViewController.changeAllowScale(isAllowed: allowScale)
            arViewController.changeAllowRotate(isAllowed: allowRotate)
            arViewController.changeAllowTranslate(isAllowed: allowTranslate)
            arViewController.changeModel(model: model)
            // set events
            if (onError != nil) {
                arViewController.setOnErrorHandler(handler: onError!)
            }
            if (onStarted != nil) {
                arViewController.setOnStartedHandler(handler: onStarted!)
            }
            if (onDataReturned != nil) {
                arViewController.setOnDataReturnedHandler(handler: onDataReturned!)
            }
            if (onEnded != nil) {
                arViewController.setOnEndedHandler(handler: onEnded!)
            }
            if (onModelPlaced != nil) {
                arViewController.setOnModelPlacedHandler(handler: onModelPlaced!)
            }
            if (onModelRemoved != nil) {
                arViewController.setOnModelRemovedHandler(handler: onModelRemoved!)
            }
            // and start session
            arViewController.run()
        } else {
            // update frame
            arViewController?.view.frame = bounds
        }
    }
    
    // reset the view
    @objc func reset() -> Void {
        arViewController?.arView.reset()
    }
    
    // take a snapshot
    @objc func takeScreenshot(requestId: Int) -> Void {
        arViewController?.arView.takeSnapshot(requestId: requestId)
    }
    
    // rotate model
    @objc func rotateModel(pitch: Int, yaw: Int, roll: Int) -> Void {
        arViewController?.arView.rotateModel(pitch: pitch, yaw: yaw, roll: roll)
    }
    
    /// Remind that properties can be set before the view has been initialized
    @objc var model: String = "" {
      didSet {
          arViewController?.changeModel(model: model)
      }
    }
    
    @objc var planeOrientation: String = "" {
      didSet {
          arViewController?.changePlaneOrientation(planeOrientation: planeOrientation)
      }
    }
    
    @objc var disableInstructions: Bool = false {
      didSet {
          arViewController?.changeInstructionVisibility(isVisible: !disableInstructions)
      }
    }
    
    @objc var lightEstimation: Bool = false {
      didSet {
          arViewController?.changeLightEstimationEnabled(isEnabled: lightEstimation)
      }
    }
    
    @objc var manageDepth: Bool = false {
      didSet {
          arViewController?.changeDepthManagementEnabled(isEnabled: manageDepth)
      }
    }
    
    @objc var disableInstantPlacement: Bool = false {
      didSet {
          arViewController?.changeInstantPlacementEnabled(isEnabled: !disableInstantPlacement)
      }
    }
    
    @objc var allowRotate: Bool = false {
      didSet {
          arViewController?.changeAllowRotate(isAllowed: allowRotate)
      }
    }
    
    @objc var allowScale: Bool = false {
      didSet {
          arViewController?.changeAllowScale(isAllowed: allowScale)
      }
    }
    
    @objc var allowTranslate: Bool = false {
      didSet {
          arViewController?.changeAllowTranslate(isAllowed: allowTranslate)
      }
    }
    
    @objc var onStarted: RCTDirectEventBlock? {
        didSet {
            arViewController?.setOnStartedHandler(handler: onStarted!)
        }
    }
    
    @objc var onDataReturned: RCTDirectEventBlock? {
        didSet {
            arViewController?.setOnDataReturnedHandler(handler: onDataReturned!)
        }
    }
    
    @objc var onError: RCTDirectEventBlock? {
        didSet {
            arViewController?.setOnErrorHandler(handler: onError!)
        }
    }
    
    @objc var onEnded: RCTDirectEventBlock? {
        didSet {
            arViewController?.setOnEndedHandler(handler: onError!)
        }
    }
    
    @objc var onModelPlaced: RCTDirectEventBlock? {
        didSet {
            arViewController?.setOnModelPlacedHandler(handler: onError!)
        }
    }
    
    @objc var onModelRemoved: RCTDirectEventBlock? {
        didSet {
            arViewController?.setOnModelRemovedHandler(handler: onError!)
        }
    }
}
