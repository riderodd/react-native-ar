import ARKit
import RealityKit

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
    
    /// Enable/Disable shadows
    func setShadowsVisibility(isVisible: Bool) {
        if (isVisible) {
            if (!renderOptions.contains(.disableGroundingShadows)) {
                renderOptions.insert(.disableGroundingShadows)
            }
        } else {
            if (renderOptions.contains(.disableGroundingShadows)) {
                renderOptions.remove(.disableGroundingShadows)
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
