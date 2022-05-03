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

class Grid: Entity, HasModel, HasAnchoring {
    var planeAnchor: ARPlaneAnchor
    var planeGeometry: MeshResource!
    
    init(planeAnchor: ARPlaneAnchor) {
        self.planeAnchor = planeAnchor
        super.init()
        self.didSetup()
    }
        
    fileprivate func didSetup() {
        self.planeGeometry = .generatePlane(width: planeAnchor.extent.x,
                                            depth: planeAnchor.extent.z)
        var material = UnlitMaterial()
        if #available(iOS 15.0, *) {
            material.color = .init(tint: .white.withAlphaComponent(0.25))
        } else {
            // Fallback on earlier versions
        }
        let model = ModelEntity(mesh: planeGeometry, materials: [material])
        model.position = [planeAnchor.center.x, 0, planeAnchor.center.z]
        self.addChild(model)
    }
    
    fileprivate func didUpdate(anchor: ARPlaneAnchor) {
        self.planeGeometry = .generatePlane(width: anchor.extent.x,
                                            depth: anchor.extent.z)
        let pose: SIMD3<Float> = [anchor.center.x, 0, anchor.center.z]
        let model = self.children[0] as! ModelEntity
        model.position = pose
    }
    required init() { fatalError("Hasn't been implemented yet") }
}

@available(iOS 13.0, *)
class ModelARView: ARView, ARSessionDelegate {
    var modelEntity: Entity!
    var modelAnchor: AnchorEntity!
    var config: ARWorldTrackingConfiguration!
    var grids = [Grid]()
    
    required init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUp() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        self.config = config
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView(frame: self.frame)
        coachingOverlay.session = self.session
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
        
        // init the model anchor
        initAnchor()
        self.session.delegate = self
    }
    
    func start() {
        self.session.run(self.config)
    }
    
    func pause() {
        self.session.pause()
    }
    
    func initAnchor() {
        // init the model anchor
        let modelAnchor = AnchorEntity()
        self.scene.addAnchor(modelAnchor)
        self.modelAnchor = modelAnchor
    }
    
    func changePlaneDetection(planeDetection: String) {
        switch planeDetection {
            case "both":
                self.config.planeDetection = [.horizontal, .vertical]
            case "horizontal":
                self.config.planeDetection = .horizontal
            case "vertical":
                self.config.planeDetection = .vertical
            default:
                self.config.planeDetection = []
        }
        // and update runtime config
        self.start()
    }
    
    func changeEntity(modelEntity: Entity) {
        if (self.modelEntity != nil) {
            // let's remove the previous model
            self.scene.removeAnchor(self.modelAnchor)
            initAnchor()
        }
        
        // display the model
        self.modelEntity = modelEntity
        //self.modelAnchor.addChild(modelEntity)
    }

    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let planeAnchor = anchors.first as? ARPlaneAnchor else { return }
        let grid = Grid(planeAnchor: planeAnchor)
        grid.transform.matrix = planeAnchor.transform
        self.scene.anchors.append(grid)
        self.grids.append(grid)
    }
        
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let planeAnchor = anchors[0] as? ARPlaneAnchor else { return }
        let grid: Grid? = grids.filter { grd in
            grd.planeAnchor.identifier == planeAnchor.identifier }[0]
        guard let updatedGrid: Grid = grid else { return }
        updatedGrid.transform.matrix = planeAnchor.transform
        updatedGrid.didUpdate(anchor: planeAnchor)
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
        
        // setup tap gesture recognizer & add to arView
        let tapGesture = UITapGestureRecognizer(target: self, action:#selector(onTap))
        arView.addGestureRecognizer(tapGesture)
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
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer){
        let tapLocation = sender.location(in: arView)
        print("clicked on plane")
        
        if let blah = arView.entity(at: tapLocation){
            print(blah.name)
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
}


