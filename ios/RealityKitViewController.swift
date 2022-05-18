import RealityKit

class RealityKitViewController: UIViewController {
    @IBOutlet var arView: ModelARView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (arView == nil) {
            arView = ModelARView(frame: view.frame)
        }
        view.addSubview(arView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // pause session on view disappear
        arView.pause()
        arView.session.delegate = nil
        arView.scene.anchors.removeAll()
        arView.removeFromSuperview()
        arView = nil
    }
    
    func setUp() {
        arView.setUp()
    }
    
    func loadEntity(src: String) -> Entity? {
        // load the model
        let url = URL(fileURLWithPath: src)
        if let modelEntity = try? ModelEntity.load(contentsOf: url) {
            return modelEntity;
        }
        
        // Create a new alert
        let dialogMessage = UIAlertController(title: "Error", message: "Cannot load the requested model file.", preferredStyle: .alert)
        dialogMessage.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in }))
        // Present alert to user
        self.present(dialogMessage, animated: true, completion: nil)
        return nil
    }
    
    func changePlaneOrientation(planeOrientation: String) {
        arView.changePlaneDetection(planeDetection: planeOrientation)
    }
    
    func changeInstructionVisibility(isVisible: Bool) {
        arView.setInstructionsVisibility(isVisible: isVisible)
    }
    
    func changeModel(model: String) {
        guard let entity = loadEntity(src: model) else { return }
        arView.changeEntity(modelEntity: entity)
    }
    
    func changeLightEstimationEnabled(isEnabled: Bool) {
        arView.setLightEstimationEnabled(isEnabled: isEnabled)
    }
    
    func changeDepthManagementEnabled(isEnabled: Bool) {
        arView.setDepthManagement(isEnabled: isEnabled)
    }
    
    func changeInstantPlacementEnabled(isEnabled: Bool) {
        arView.setInstantPlacementEnabled(isEnabled: isEnabled)
    }
    
    func changeAllowRotate(isAllowed: Bool) {
        arView.setAllowRotate(isEnabled: isAllowed)
    }
    
    func changeAllowTranslate(isAllowed: Bool) {
        arView.setAllowTranslate(isEnabled: isAllowed)
    }
    
    func changeAllowScale(isAllowed: Bool) {
        arView.setAllowScale(isEnabled: isAllowed)
    }
    
    func setShadowsVisibility(isVisible: Bool) {
        arView.setShadowsVisibility(isVisible: isVisible)
    }
    
    func run() {
        arView.readyToStart = true
        arView.start()
    }
    
    /// Set on started event
    func setOnStartedHandler(handler: @escaping RCTDirectEventBlock) {
        arView.setOnStartedHandler(handler: handler)
    }
    
    /// Set on error event
    func setOnErrorHandler(handler: @escaping RCTDirectEventBlock) {
        arView.setOnErrorHandler(handler: handler)
    }
    
    /// Set on data returned handler (used to resolve promises on JS side)
    func setOnDataReturnedHandler(handler: @escaping RCTDirectEventBlock) {
        arView.setOnDataReturnedHandler(handler: handler)
    }
    
    /// Set on data returned handler (used to resolve promises on JS side)
    func setOnEndedHandler(handler: @escaping RCTDirectEventBlock) {
        arView.setOnEndedHandler(handler: handler)
    }
    
    /// Set on data returned handler (used to resolve promises on JS side)
    func setOnModelPlacedHandler(handler: @escaping RCTDirectEventBlock) {
        arView.setOnModelPlacedHandler(handler: handler)
    }
    
    /// Set on data returned handler (used to resolve promises on JS side)
    func setOnModelRemovedHandler(handler: @escaping RCTDirectEventBlock) {
        arView.setOnModelRemovedHandler(handler: handler)
    }
}
