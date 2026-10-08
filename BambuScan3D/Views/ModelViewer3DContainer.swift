import SwiftUI
import SceneKit
import simd

/// Taranan 3D modeli Bambu Lab baskı tablası üzerinde 360 derece döndürüp inceleme alanı
public struct ModelViewer3DContainer: UIViewRepresentable {
    let mesh: ScannedMesh
    let showWireframe: Bool
    
    public init(mesh: ScannedMesh, showWireframe: Bool = false) {
        self.mesh = mesh
        self.showWireframe = showWireframe
    }
    
    public func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        
        setupLighting(scene: scene)
        setupBuildPlate(scene: scene)
        setupCamera(scene: scene, bounds: mesh.boundingExtents)
        updateModelGeometry(scene: scene)
        
        return scnView
    }
    
    public func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else { return }
        
        if let existingNode = scene.rootNode.childNode(withName: "ScannedObjectNode", recursively: false) {
            existingNode.removeFromParentNode()
        }
        updateModelGeometry(scene: scene)
    }
    
    private func updateModelGeometry(scene: SCNScene) {
        guard let geometry = createSCNGeometry(from: mesh, wireframe: showWireframe) else { return }
        let objectNode = SCNNode(geometry: geometry)
        objectNode.name = "ScannedObjectNode"
        scene.rootNode.addChildNode(objectNode)
    }
    
    // SceneKit Geometrisi Oluşturma
    private func createSCNGeometry(from mesh: ScannedMesh, wireframe: Bool) -> SCNGeometry? {
        guard !mesh.vertices.isEmpty, !mesh.indices.isEmpty else { return nil }
        
        let vertexData = Data(bytes: mesh.vertices, count: mesh.vertices.count * MemoryLayout<SIMD3<Float>>.stride)
        let vertexSource = SCNGeometrySource(
            data: vertexData,
            semantic: .vertex,
            vectorCount: mesh.vertices.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD3<Float>>.stride
        )
        
        var normalSource: SCNGeometrySource?
        if !mesh.normals.isEmpty && mesh.normals.count == mesh.vertices.count {
            let normalData = Data(bytes: mesh.normals, count: mesh.normals.count * MemoryLayout<SIMD3<Float>>.stride)
            normalSource = SCNGeometrySource(
                data: normalData,
                semantic: .normal,
                vectorCount: mesh.normals.count,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )
        }
        
        let indexData = Data(bytes: mesh.indices, count: mesh.indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: mesh.triangleCount,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )
        
        var sources = [vertexSource]
        if let normalSource = normalSource {
            sources.append(normalSource)
        }
        
        let geometry = SCNGeometry(sources: sources, elements: [element])
        
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.fillMode = wireframe ? .lines : .fill
        material.diffuse.contents = wireframe ? UIColor.green : UIColor(red: 0.88, green: 0.9, blue: 0.92, alpha: 1.0)
        material.metalness.contents = 0.1
        material.roughness.contents = 0.5
        material.isDoubleSided = true
        
        geometry.materials = [material]
        return geometry
    }
    
    // Bambu Lab 256x256 mm Tabla Izgarası
    private func setupBuildPlate(scene: SCNScene) {
        let plateSize: CGFloat = 256.0
        let plateGeometry = SCNBox(width: plateSize, height: 1.0, length: plateSize, chamferRadius: 2.0)
        
        let plateMaterial = SCNMaterial()
        plateMaterial.diffuse.contents = UIColor(red: 0.15, green: 0.16, blue: 0.18, alpha: 1.0)
        plateMaterial.roughness.contents = 0.8
        plateGeometry.materials = [plateMaterial]
        
        let plateNode = SCNNode(geometry: plateGeometry)
        plateNode.position = SCNVector3(0, -0.5, 0)
        scene.rootNode.addChildNode(plateNode)
        
        // Tabla üzerine ızgara çizgileri (Grid)
        let gridPlane = SCNPlane(width: plateSize, height: plateSize)
        gridPlane.widthSegmentCount = 10
        gridPlane.heightSegmentCount = 10
        let gridMaterial = SCNMaterial()
        gridMaterial.fillMode = .lines
        gridMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.68, blue: 0.26, alpha: 0.4) // Bambu Green Grid
        gridPlane.materials = [gridMaterial]
        
        let gridNode = SCNNode(geometry: gridPlane)
        gridNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        gridNode.position = SCNVector3(0, 0.1, 0)
        scene.rootNode.addChildNode(gridNode)
    }
    
    private func setupLighting(scene: SCNScene) {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 400
        ambientLight.color = UIColor.white
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 900
        keyLight.castsShadow = true
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(150, 250, 200)
        keyNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyNode)
        
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.intensity = 500
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-150, 100, -100)
        fillNode.eulerAngles = SCNVector3(Float.pi / 6, -Float.pi / 4, 0)
        scene.rootNode.addChildNode(fillNode)
    }
    
    private func setupCamera(scene: SCNScene, bounds: (min: SIMD3<Float>, max: SIMD3<Float>)) {
        let camera = SCNCamera()
        camera.zNear = 1.0
        camera.zFar = 2000.0
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        let maxDim = max(bounds.max.x - bounds.min.x, max(bounds.max.y - bounds.min.y, bounds.max.z - bounds.min.z))
        let distance = max(Float(maxDim) * 2.2, 180.0)
        
        cameraNode.position = SCNVector3(0, distance * 0.7, distance)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }
}
