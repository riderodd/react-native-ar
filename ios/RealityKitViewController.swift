import RealityKit
import UIKit

class RealityKitViewController: UIViewController {
    var arView: ModelARView?
    private var onErrorHandler: ArEventHandler?

    override func viewDidLoad() {
        super.viewDidLoad()
        let arView = ModelARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)
        self.arView = arView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arView?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView?.pause()
    }

    func tearDown() {
        guard let arView = arView else { return }
        self.arView = nil
        arView.pause()
        arView.session.delegate = nil
        arView.scene.anchors.removeAll()
        arView.removeFromSuperview()
    }

    func setUp() {
        arView?.setUp()
    }

    func changePlaneOrientation(planeOrientation: String) {
        arView?.changePlaneDetection(planeDetection: planeOrientation)
    }

    func changeInstructionVisibility(isVisible: Bool) {
        arView?.setInstructionsVisibility(isVisible: isVisible)
    }

    func changeModel(model: String) {
        guard !model.isEmpty else { return }
        do {
            let entity = try ModelEntity.load(contentsOf: URL(fileURLWithPath: model))
            arView?.changeEntity(modelEntity: entity)
        } catch {
            onErrorHandler?(["message": "Cannot load the model: \(error.localizedDescription)"])
        }
    }

    func changeLightEstimationEnabled(isEnabled: Bool) {
        arView?.setLightEstimationEnabled(isEnabled: isEnabled)
    }

    func changeDepthManagementEnabled(isEnabled: Bool) {
        arView?.setDepthManagement(isEnabled: isEnabled)
    }

    func changeInstantPlacementEnabled(isEnabled: Bool) {
        arView?.setInstantPlacementEnabled(isEnabled: isEnabled)
    }

    func changeAllowRotate(isAllowed: Bool) {
        arView?.setAllowRotate(isEnabled: isAllowed)
    }

    func changeAllowTranslate(isAllowed: Bool) {
        arView?.setAllowTranslate(isEnabled: isAllowed)
    }

    func changeAllowScale(isAllowed: Bool) {
        arView?.setAllowScale(isEnabled: isAllowed)
    }

    func run() {
        arView?.readyToStart = true
        arView?.start()
    }

    func setOnStartedHandler(handler: @escaping ArEventHandler) {
        arView?.onStartedHandler = handler
    }

    func setOnErrorHandler(handler: @escaping ArEventHandler) {
        onErrorHandler = handler
        arView?.onErrorHandler = handler
    }

    func setOnDataReturnedHandler(handler: @escaping ArEventHandler) {
        arView?.onDataReturnedHandler = handler
    }

    func setOnEndedHandler(handler: @escaping ArEventHandler) {
        arView?.onEndedHandler = handler
    }

    func setOnModelPlacedHandler(handler: @escaping ArEventHandler) {
        arView?.onModelPlacedHandler = handler
    }

    func setOnModelRemovedHandler(handler: @escaping ArEventHandler) {
        arView?.onModelRemovedHandler = handler
    }
}
