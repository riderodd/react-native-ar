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

@available(iOS 13.0, *)
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


class Grid: Entity, HasModel, HasAnchoring, HasCollision {
    var planeAnchor: ARPlaneAnchor
    var planeGeometry: MeshResource!
    var isShowingModel: Bool = false
    
    init(planeAnchor: ARPlaneAnchor) {
        self.planeAnchor = planeAnchor
        super.init()
        self.didSetup()
    }
        
    fileprivate func didSetup() {
        self.name = "planeEntity"
        self.planeGeometry = .generatePlane(width: planeAnchor.extent.x,
                                            depth: planeAnchor.extent.z,
                                            cornerRadius: 0.5)
        let model = generatePlaneModel()
        self.addChild(model)
        self.generateCollisionShapes(recursive: true)
    }
    
    fileprivate func didUpdate(anchor: ARPlaneAnchor) {
        self.planeGeometry = .generatePlane(width: anchor.extent.x,
                                            depth: anchor.extent.z)
        let pose: SIMD3<Float> = [anchor.center.x, 0, anchor.center.z]
        for childEntity in self.children {
            childEntity.position = pose
        }
    }
    required init() { fatalError("Hasn't been implemented yet") }
    
    
    func generatePlaneModel() -> ModelEntity {
        var material = UnlitMaterial()
        if #available(iOS 15.0, *) {
            let frameworkBundle = Bundle(for: ArViewerViewManager.self)
            let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("ArViewerBundle.bundle")
            let resourceBundle = Bundle(url: bundleURL!)
            let resourceUrl = resourceBundle?.url(forResource: "grid", withExtension: "png")
            material.color = .init(tint: .white.withAlphaComponent(0.9999),
                                   texture: .init(try! .load(contentsOf: resourceUrl!)))
        }
        
        let model = ModelEntity(mesh: planeGeometry, materials: [material])
        model.position = [planeAnchor.center.x, 0, planeAnchor.center.z]
        model.name = "plane"
        return model
    }
    
    
    func replaceModel(model: Entity) {
        // remove all children
        children.removeAll()
        model.name = "model"
        self.addChild(model)
        self.generateCollisionShapes(recursive: true)
        isShowingModel = true
    }
    
    // reset the plane
    func reset() {
        children.removeAll()
        let model = generatePlaneModel()
        addChild(model)
        generateCollisionShapes(recursive: true)
        isShowingModel = false
    }
}

@available(iOS 13.0, *)
class ModelARView: ARView, ARSessionDelegate {
    var modelEntity: Entity!
    var config: ARWorldTrackingConfiguration!
    var grids = [Grid]()
    var isModelVisible: Bool = false {
        didSet {
            if (isModelVisible && self.onModelPlacedHandler != nil) {
                self.onModelPlacedHandler([:])
            } else if(!isModelVisible && self.onModelRemovedHandler != nil) {
                self.onModelRemovedHandler([:])
            }
        }
    }
    var coachingOverlay: ARCoachingOverlayView!
    var isInstantPlacementEnabled: Bool = true
    var allowedGestures: ARView.EntityGestures = []
    var installedGestureRecognizers: [EntityGestureRecognizer] = []
    var isSetup: Bool = false
    var readyToStart: Bool = false
    var sessionStarted: Bool = false
    
    var onStartedHandler: RCTDirectEventBlock!
    var onErrorHandler: RCTDirectEventBlock!
    var onDataReturnedHandler: RCTDirectEventBlock!
    var onEndedHandler: RCTDirectEventBlock!
    var onModelPlacedHandler: RCTDirectEventBlock!
    var onModelRemovedHandler: RCTDirectEventBlock!
    
    required init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required dynamic init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    /// Setup the view
    func setUp() {
        // manage orientation change
        self.autoresizingMask = [
            .flexibleWidth, .flexibleHeight
        ]
        // Add coaching overlay
        coachingOverlay = ARCoachingOverlayView(frame: frame)
        // setup the instructions
        coachingOverlay.goal = .anyPlane
        coachingOverlay.session = self.session
        // Make sure it rescales if the device orientation changes
        coachingOverlay.autoresizingMask = [
            .flexibleWidth, .flexibleHeight
        ]
        // update frame
        coachingOverlay.frame = self.frame
        self.addSubview(coachingOverlay)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.isLightEstimationEnabled = false
        if #available(iOS 13.4, *) {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                config.sceneReconstruction = .mesh
            }
        }
        self.config = config
        
        // manage session here
        self.session.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tap.name = "gridTap"
        self.addGestureRecognizer(tap)
        
        isSetup = true
    }
    
    /// Hide all grids and display the model on the provided one
    func showModel(grid: Grid, model: Entity) {
        for gr in grids {
            if (gr != grid) {
                gr.isEnabled = false
            }
        }
        
        grid.isEnabled = true
        grid.replaceModel(model: modelEntity)
        isModelVisible = true
        setGestures()
    }
    
    /// Reset the views and all grids
    func reset() {
        for grid in self.grids {
            grid.reset()
            grid.isEnabled = true
        }
        isModelVisible = false
        setGestures()
    }
    
    /// Start or update the AR session
    func start() {
        if (isSetup && readyToStart) {
            self.session.run(self.config)
            if(!sessionStarted) {
                sessionStarted = true
                if (onStartedHandler != nil) {
                    onStartedHandler([:])
                }
            }
        }
    }
    
    
    /// Pause the AR session
    func pause() {
        self.session.pause()
        sessionStarted = false
        if (onEndedHandler != nil) {
            onEndedHandler([:])
        }
    }
    
    
    /// Set the plane orientation to detect
    func changePlaneDetection(planeDetection: String) {
        switch planeDetection {
            case "none":
                self.coachingOverlay.goal = .tracking
                self.config.planeDetection = []
            case "horizontal":
                self.coachingOverlay.goal = .horizontalPlane
                self.config.planeDetection = .horizontal
            case "vertical":
                self.coachingOverlay.goal = .verticalPlane
                self.config.planeDetection = .vertical
            default:
                // both
                self.coachingOverlay.goal = .anyPlane
                self.config.planeDetection = [.horizontal, .vertical]
        }
        // and update runtime config
        self.start()
    }
    
    
    func takeSnapshot(requestId: Int) {
        snapshot(saveToHDR: false) { (image) in
            let imageString = image?.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
            if (self.onDataReturnedHandler != nil) {
                self.onDataReturnedHandler([
                    "requestId": requestId,
                    "result": imageString,
                    "error": ""
                ])
            } else if(self.onErrorHandler != nil) {
                self.onErrorHandler(["message": "No data handler found to return the snapshot"])
            }
        }
    }
    
    /// Change the model to render
    func changeEntity(modelEntity: Entity) {
        if (isModelVisible) {
            for grid in self.grids {
                if (grid.isShowingModel) {
                    grid.replaceModel(model: modelEntity)
                }
            }
        }
        self.modelEntity = modelEntity
        tryInstantPlacement()
    }
    
    /// Enable/Disable coaching view
    func setInstructionsVisibility(isVisible: Bool) {
        guard (self.subviews.firstIndex(of: coachingOverlay) != nil) else {
            // no coaching view present
            if (isVisible) {
                coachingOverlay.activatesAutomatically = true
                coachingOverlay.setActive(true, animated: true)
            }
            return
        }
        
        // coaching is present
        if (!isVisible) {
            coachingOverlay.activatesAutomatically = false
            coachingOverlay.setActive(false, animated: true)
        }
    }
    
    /// Enable/Disable environment occlusion
    func setDepthManagement(isEnabled: Bool) {
        if #available(iOS 13.4, *) {
            if(isEnabled) {
                environment.sceneUnderstanding.options.insert(.occlusion)
            } else {
                environment.sceneUnderstanding.options.remove(.occlusion)
            }
        }
    }
    
    /// Enable/Disable light estimation
    func setLightEstimationEnabled(isEnabled: Bool) {
        config.isLightEstimationEnabled = isEnabled
        start()
    }
    
    
    /// Enable/Disable instant placement mode
    func setInstantPlacementEnabled(isEnabled: Bool) {
        self.isInstantPlacementEnabled = isEnabled
        tryInstantPlacement()
    }
    
    
    /// Try to automatically add the model on the first anchor found
    func tryInstantPlacement() {
        if (isInstantPlacementEnabled && !isModelVisible && grids.count > 0 && self.modelEntity != nil) {
            // place it on first anchor
            guard let grid: Grid = grids.first else {
                return
            }
            self.showModel(grid: grid, model: self.modelEntity)
        }
    }
    
    /// Register all gesture handlers
    func setGestures() {
        // reset all gestures
        for gestureRecognizer in gestureRecognizers! {
            guard let index = gestureRecognizers?.firstIndex(of: gestureRecognizer) else {
                return
            }
            if (gestureRecognizer.name != "gridTap") {
                gestureRecognizers?.remove(at: index)
            }
        }
        // install new gestures
        for grid in grids {
            if (grid.isShowingModel) {
                installGestures(.init(arrayLiteral: self.allowedGestures), for: grid)
            }
        }
    }
    
    /// Enable/Disabled user gesture on model: rotation
    func setAllowRotate(isEnabled: Bool) {
        if (isEnabled) {
            self.allowedGestures.insert(.rotation)
        } else {
            self.allowedGestures.remove(.rotation)
        }
        setGestures()
    }
    
    /// Enable/Disable user gesture on model: scale
    func setAllowScale(isEnabled: Bool) {
        if (isEnabled) {
            self.allowedGestures.insert(.scale)
        } else {
            self.allowedGestures.remove(.scale)
        }
        setGestures()
    }
    
    
    /// Enable/Disable user gesture on model: translation
    func setAllowTranslate(isEnabled: Bool) {
        if (isEnabled) {
            self.allowedGestures.insert(.translation)
        } else {
            self.allowedGestures.remove(.translation)
        }
        setGestures()
    }
    
    
    /// Converts degrees to radians
    func deg2rad(_ number: Int) -> Float {
        return Float(number) * .pi / 180
    }
    
    /// Rotate the model
    func rotateModel(pitch: Int, yaw: Int, roll: Int) -> Void {
        guard isModelVisible else { return }
        for plane in self.grids {
            if (plane.isShowingModel) {
                let transform = Transform(pitch: deg2rad(pitch), yaw: deg2rad(yaw), roll: deg2rad(roll))
                let currentMatrix = plane.transform.matrix
                let calculated = simd_mul(currentMatrix, transform.matrix)
                plane.move(to: calculated, relativeTo: nil, duration: 1)
            }
        }
    }
    
    // Set our events handlers
    /// Set on started event
    func setOnStartedHandler(handler: @escaping RCTDirectEventBlock) {
        onStartedHandler = handler
    }
    
    /// Set on error event
    func setOnErrorHandler(handler: @escaping RCTDirectEventBlock) {
        onErrorHandler = handler
    }
    
    /// Set on data returned handler (used to resolve promises on JS side)
    func setOnDataReturnedHandler(handler: @escaping RCTDirectEventBlock) {
        onDataReturnedHandler = handler
    }
    
    /// Set on ended event
    func setOnEndedHandler(handler: @escaping RCTDirectEventBlock) {
        onEndedHandler = handler
    }
    
    /// Set on model placed handler
    func setOnModelPlacedHandler(handler: @escaping RCTDirectEventBlock) {
        onModelPlacedHandler = handler
    }
    
    /// Set on model removed handler
    func setOnModelRemovedHandler(handler: @escaping RCTDirectEventBlock) {
        onModelRemovedHandler = handler
    }
    
    /// Add a grid when an new anchor is found
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            let grid = Grid(planeAnchor: planeAnchor)
            grid.transform.matrix = planeAnchor.transform
            self.scene.anchors.append(grid)
            self.grids.append(grid)
            if (isModelVisible) {
                grid.isEnabled = false
            }
            // try instant placement on first anchor placed
            tryInstantPlacement()
        }
    }
        
    /// Update grid position when its anchor moves
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            let updatedGrids: [Grid]? = grids.filter { grd in
                grd.planeAnchor.identifier == planeAnchor.identifier }
            for grid in updatedGrids ?? [] {
                if (!grid.isShowingModel && grid.isEnabled) {
                    grid.transform.matrix = planeAnchor.transform
                }
                grid.didUpdate(anchor: planeAnchor)
            }
        }
    }
    
    /// Remove a grid from scene when its anchor is removed
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            let deletedGrids: [Grid]? = grids.filter { grd in
                grd.planeAnchor.identifier == planeAnchor.identifier }
            var modelRemoved = false
            for grid in deletedGrids ?? [] {
                if (grid.isShowingModel) {
                    self.isModelVisible = false
                    modelRemoved = true
                }
                self.scene.anchors.remove(grid)
                self.grids.remove(at: self.grids.firstIndex(of: grid)!)
            }
            if (modelRemoved) {
                self.reset()
            }
        }
    }
    
    /// Replace a Grid with the requested model when tapped
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: self) else {
            return
        }
        
        guard let modelTapped = self.entity(at: touchInView) else {
              // nothing hit
              return
        }
        
        guard let gridTapped = modelTapped.parent as? Grid else {
            return
        }
        
        if (self.modelEntity != nil) {
            self.showModel(grid: gridTapped, model: self.modelEntity)
        }
    }
}


@available(iOS 13.0, *)
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
