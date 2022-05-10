import ARKit
import RealityKit
import SwiftUI

@available(iOS 13.0, *)
@objc(ArViewerViewManager)
class ArViewerViewManager: RCTViewManager {

  override func view() -> UIView {
      return ArViewerView()
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
                                            depth: planeAnchor.extent.z)
        let model = generatePlaneModel()
        self.addChild(model)
        self.generateCollisionShapes(recursive: true)
    }
    
    fileprivate func didUpdate(anchor: ARPlaneAnchor) {
        self.planeGeometry = .generatePlane(width: anchor.extent.x,
                                            depth: anchor.extent.z)
        let pose: SIMD3<Float> = [anchor.center.x, 0, anchor.center.z]
        for childEntity in self.children {
            if (childEntity.name == "plane") {
                childEntity.position = pose
            }
        }
    }
    required init() { fatalError("Hasn't been implemented yet") }
    
    
    func generatePlaneModel() -> ModelEntity {
        var material = UnlitMaterial()
        if #available(iOS 15.0, *) {
            material.color = .init(tint: .white.withAlphaComponent(0.25))
        }
        let model = ModelEntity(mesh: planeGeometry, materials: [material])
        model.position = [planeAnchor.center.x, 0, planeAnchor.center.z]
        model.name = "plane"
        return model
    }
    
    
    func replaceModel(model: Entity) {
        // remove all children
        for child in self.children {
            self.removeChild(child)
        }
        model.name = "model"
        self.addChild(model)
        self.generateCollisionShapes(recursive: true)
        isShowingModel = true
    }
    
    // reset the plane
    func reset() {
        for child in self.children {
            if(child.name == "model") {
                self.removeChild(child)
                let model = generatePlaneModel()
                self.addChild(model)
                self.generateCollisionShapes(recursive: true)
                isShowingModel = false
            }
        }
    }
}

@available(iOS 13.0, *)
class ModelARView: ARView, ARSessionDelegate {
    var modelEntity: Entity!
    var config: ARWorldTrackingConfiguration!
    var grids = [Grid]()
    var isModelVisible: Bool = false
    var coachingOverlay: ARCoachingOverlayView
    var isInstantPlacementEnabled: Bool = true
    var allowedGestures: ARView.EntityGestures = []
    var installedGestureRecognizers: [EntityGestureRecognizer] = []
    
    required init(frame: CGRect) {
        // Add coaching overlay
        coachingOverlay = ARCoachingOverlayView(frame: frame)
        super.init(frame: frame)
    }
    
    required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUp() {
        // setup the instructions
        coachingOverlay.goal = .anyPlane
        coachingOverlay.session = self.session
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
        self.addGestureRecognizer(tap)
        
        // updated instructions frame
        coachingOverlay.frame = self.frame
    }
    
    
    /// Replace a plane with the requested model when tapped
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
        
        self.showModel(grid: gridTapped, model: self.modelEntity)
    }
    
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
    
    // Reset the views and all grids
    func reset() {
        for grid in self.grids {
            grid.reset()
            grid.isEnabled = true
        }
        isModelVisible = false
    }
    
    // also can update session config
    func start() {
        self.session.run(self.config)
    }
    
    func pause() {
        self.session.pause()
    }
    
    func changePlaneDetection(planeDetection: String) {
        switch planeDetection {
            case "both":
                self.coachingOverlay.goal = .anyPlane
                self.config.planeDetection = [.horizontal, .vertical]
            case "horizontal":
                self.coachingOverlay.goal = .horizontalPlane
                self.config.planeDetection = .horizontal
            case "vertical":
                self.coachingOverlay.goal = .verticalPlane
                self.config.planeDetection = .vertical
            default:
                self.coachingOverlay.goal = .tracking
                self.config.planeDetection = []
        }
        // and update runtime config
        self.start()
    }
    
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
    
    func setInstructionsVisibility(isVisible: Bool) {
        guard let viewIndex = self.subviews.firstIndex(of: coachingOverlay) else {
            // no coaching view present
            if (isVisible) {
                addSubview(coachingOverlay)
            } else {
                coachingOverlay.removeFromSuperview()
            }
            return
        }
    }
    
    func setDepthManagement(isEnabled: Bool) {
        if #available(iOS 13.4, *) {
            if(isEnabled) {
                environment.sceneUnderstanding.options.insert(.occlusion)
            } else {
                environment.sceneUnderstanding.options.remove(.occlusion)
            }
        }
    }
    
    func setLightEstimationEnabled(isEnabled: Bool) {
        config.isLightEstimationEnabled = isEnabled
        start()
    }
    
    func setInstantPlacementEnabled(isEnabled: Bool) {
        self.isInstantPlacementEnabled = isEnabled
        tryInstantPlacement()
    }
    
    func tryInstantPlacement() {
        if (isInstantPlacementEnabled && !isModelVisible && grids.count > 0 && self.modelEntity != nil) {
            // place it on first anchor
            guard let grid: Grid = grids.first else {
                return
            }
            self.showModel(grid: grid, model: self.modelEntity)
        }
    }
    
    func setGestures() {
        // reset all gestures
        for gestureRecognizer in installedGestureRecognizers {
            guard let recognizerIndex = gestureRecognizers?.firstIndex(of: gestureRecognizer) else {
                continue
            }
            gestureRecognizers?.remove(at: recognizerIndex)
        }
        // install new gestures
        for grid in grids {
            if (grid.isShowingModel) {
                let installedRecognizers = self.installGestures(self.allowedGestures, for: grid)
                self.installedGestureRecognizers.append(contentsOf: installedRecognizers)
            }
        }
    }
    
    func setAllowRotate(isEnabled: Bool) {
        if (isEnabled) {
            self.allowedGestures.insert(.rotation)
        } else {
            self.allowedGestures.remove(.rotation)
        }
        setGestures()
    }
    
    func setAllowScale(isEnabled: Bool) {
        if (isEnabled) {
            self.allowedGestures.insert(.scale)
        } else {
            self.allowedGestures.remove(.scale)
        }
        setGestures()
    }
    
    func setAllowTranslate(isEnabled: Bool) {
        if (isEnabled) {
            self.allowedGestures.insert(.translation)
        } else {
            self.allowedGestures.remove(.translation)
        }
        setGestures()
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            let grid = Grid(planeAnchor: planeAnchor)
            grid.transform.matrix = planeAnchor.transform
            self.scene.anchors.append(grid)
            self.grids.append(grid)
            // try instant placement on first anchor placed
            tryInstantPlacement()
        }
    }
        
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            let updatedGrids: [Grid]? = grids.filter { grd in
                grd.planeAnchor.identifier == planeAnchor.identifier }
            for grid in updatedGrids ?? [] {
                grid.transform.matrix = planeAnchor.transform
                grid.didUpdate(anchor: planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            let deletedGrids: [Grid]? = grids.filter { grd in
                grd.planeAnchor.identifier == planeAnchor.identifier }
            for grid in deletedGrids ?? [] {
                self.scene.anchors.remove(grid)
                self.grids.remove(at: self.grids.firstIndex(of: grid)!)
            }
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
        
        arView.setUp()
        arView.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // pause session on view disappear
        arView.pause()
    }
    
    func loadEntity(src: String) -> Entity? {
        // load the model
        let url = URL(fileURLWithPath: src)
        if let modelEntity = try? ModelEntity.load(contentsOf: url) {
            return modelEntity;
        }
        
        // Create a new alert
        let dialogMessage = UIAlertController(title: "Error", message: "Cannot load the requested model file.", preferredStyle: .alert)

        // Present alert to user
        self.present(dialogMessage, animated: true, completion: nil)
        return nil
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

@available(iOS 13.0, *)
class ArViewerView: UIView {

    weak var arViewController: RealityKitViewController?

    var config: NSDictionary = [:] {
        didSet {
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) { fatalError("nope") }

    override func layoutSubviews() {
        super.layoutSubviews()

        if arViewController == nil {
            setup()
        } else {
            arViewController?.view.frame = bounds
        }
    }

    private func setup() {
        guard let parentVC = parentViewController else { return }

        let vc = RealityKitViewController()
        vc.view.frame = bounds
        parentVC.addChild(vc)
        addSubview(vc.view)
        vc.didMove(toParent: parentVC)
        self.arViewController = vc
        
        changeModel()
    }
    
    func changeModel() {
        guard let entity = self.arViewController?.loadEntity(src: model) else { return }
        self.arViewController?.arView.changeEntity(modelEntity: entity)
    }
    
    @objc var model: String = "" {
      didSet {
          changeModel()
      }
    }
    
    @objc var planeOrientation: String = "" {
      didSet {
          self.arViewController?.arView.changePlaneDetection(planeDetection: planeOrientation)
      }
    }
    
    @objc var disableInstructions: Bool = false {
      didSet {
          self.arViewController?.arView.setInstructionsVisibility(isVisible: !disableInstructions)
      }
    }
    
    @objc var lightEstimation: Bool = false {
      didSet {
          self.arViewController?.arView.setLightEstimationEnabled(isEnabled: lightEstimation)
      }
    }
    
    @objc var manageDepth: Bool = false {
      didSet {
          self.arViewController?.arView.setDepthManagement(isEnabled: manageDepth)
      }
    }
    
    @objc var disableInstantPlacement: Bool = false {
      didSet {
          self.arViewController?.arView.setInstantPlacementEnabled(isEnabled: !disableInstantPlacement)
      }
    }
    
    @objc var allowRotate: Bool = false {
      didSet {
          self.arViewController?.arView.setAllowRotate(isEnabled: allowRotate)
      }
    }
    
    @objc var allowScale: Bool = false {
      didSet {
          self.arViewController?.arView.setAllowScale(isEnabled: allowScale)
      }
    }
    
    @objc var allowTranslate: Bool = false {
      didSet {
          self.arViewController?.arView.setAllowTranslate(isEnabled: allowTranslate)
      }
    }
}


