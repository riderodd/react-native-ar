import UIKit

public typealias ArEventHandler = ([String: Any]) -> Void

@objc(ArViewerView)
public class ArViewerView: UIView {

    var arViewController: RealityKitViewController?

    @objc public var onStarted: ArEventHandler?
    @objc public var onDataReturned: ArEventHandler?
    @objc public var onError: ArEventHandler?
    @objc public var onEnded: ArEventHandler?
    @objc public var onModelPlaced: ArEventHandler?
    @objc public var onModelRemoved: ArEventHandler?

    public override func layoutSubviews() {
        super.layoutSubviews()

        if let arViewController = arViewController {
            arViewController.view.frame = bounds
            return
        }
        guard let parentViewController = parentViewController else { return }

        let controller = RealityKitViewController()
        arViewController = controller
        controller.view.frame = bounds
        parentViewController.addChild(controller)
        addSubview(controller.view)
        controller.didMove(toParent: parentViewController)

        controller.setUp()
        controller.setOnStartedHandler { [weak self] in self?.onStarted?($0) }
        controller.setOnErrorHandler { [weak self] in self?.onError?($0) }
        controller.setOnDataReturnedHandler { [weak self] in self?.onDataReturned?($0) }
        controller.setOnEndedHandler { [weak self] in self?.onEnded?($0) }
        controller.setOnModelPlacedHandler { [weak self] in self?.onModelPlaced?($0) }
        controller.setOnModelRemovedHandler { [weak self] in self?.onModelRemoved?($0) }
        // props may have been set before the view was mounted
        controller.changePlaneOrientation(planeOrientation: planeOrientation)
        controller.changeInstructionVisibility(isVisible: !disableInstructions)
        controller.changeLightEstimationEnabled(isEnabled: lightEstimation)
        controller.changeDepthManagementEnabled(isEnabled: manageDepth)
        controller.changeInstantPlacementEnabled(isEnabled: !disableInstantPlacement)
        controller.changeAllowScale(isAllowed: allowScale)
        controller.changeAllowRotate(isAllowed: allowRotate)
        controller.changeAllowTranslate(isAllowed: allowTranslate)
        controller.changeModel(model: model)
        controller.run()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            tearDown()
        } else {
            setNeedsLayout()
        }
    }

    /// Stops the AR session and detaches the view controller
    @objc public func tearDown() {
        guard let controller = arViewController else { return }
        arViewController = nil
        controller.tearDown()
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }

    @objc public func reset() {
        arViewController?.arView?.reset()
    }

    @objc public func takeScreenshot(requestId: Int) {
        guard let arView = arViewController?.arView else {
            onDataReturned?(["requestId": requestId, "result": "", "error": "The AR view is not ready"])
            return
        }
        arView.takeSnapshot(requestId: requestId)
    }

    @objc public func rotateModel(pitch: Float, yaw: Float, roll: Float) {
        arViewController?.arView?.rotateModel(pitch: pitch, yaw: yaw, roll: roll)
    }

    @objc public var model: String = "" {
        didSet { arViewController?.changeModel(model: model) }
    }

    @objc public var planeOrientation: String = "both" {
        didSet { arViewController?.changePlaneOrientation(planeOrientation: planeOrientation) }
    }

    @objc public var disableInstructions: Bool = false {
        didSet { arViewController?.changeInstructionVisibility(isVisible: !disableInstructions) }
    }

    @objc public var lightEstimation: Bool = false {
        didSet { arViewController?.changeLightEstimationEnabled(isEnabled: lightEstimation) }
    }

    @objc public var manageDepth: Bool = false {
        didSet { arViewController?.changeDepthManagementEnabled(isEnabled: manageDepth) }
    }

    @objc public var disableInstantPlacement: Bool = false {
        didSet { arViewController?.changeInstantPlacementEnabled(isEnabled: !disableInstantPlacement) }
    }

    @objc public var allowRotate: Bool = false {
        didSet { arViewController?.changeAllowRotate(isAllowed: allowRotate) }
    }

    @objc public var allowScale: Bool = false {
        didSet { arViewController?.changeAllowScale(isAllowed: allowScale) }
    }

    @objc public var allowTranslate: Bool = false {
        didSet { arViewController?.changeAllowTranslate(isAllowed: allowTranslate) }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let responder = parentResponder {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            parentResponder = responder.next
        }
        return nil
    }
}
