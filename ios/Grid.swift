import ARKit
import RealityKit

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
    
    open func didUpdate(anchor: ARPlaneAnchor) {
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
