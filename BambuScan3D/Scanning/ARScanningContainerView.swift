import SwiftUI
import ARKit
import SceneKit
import simd

/// Tam ekran AR LiDAR Tarama Görünümü
/// - Gerçek dünya koordinatlarında sabitlenen 3D kafes
/// - Nesne taranırken taranan yerleri anlık NEON YEŞİLE boyayan görsel geri bildirim
/// - Ekrana dokunarak masaya sabitleme ve pinch ile büyütüp küçültme jestleri
public struct ARScanningContainerView: UIViewRepresentable {
    @ObservedObject var scannerEngine: LidarScannerEngine
    
    public init(scannerEngine: LidarScannerEngine) {
        self.scannerEngine = scannerEngine
    }
    
    public func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = scannerEngine.session
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // Sahneye sabit 3D kafesi ekle
        let boxNode = BoundingBoxNode()
        boxNode.name = "WorldAnchoredBoundingBox"
        arView.scene.rootNode.addChildNode(boxNode)
        
        context.coordinator.boundingBoxNode = boxNode
        context.coordinator.arView = arView
        
        // 1. Dokunma Jesti: Masaya dokunup kafesi gerçek dünyada oraya kilitle
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // 2. İki Parmak Pinch Jesti: Kafesi büyütüp küçültme
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // 3. Tek Parmak Sürükleme Jesti: Kafesi masada kaydırma
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(panGesture)
        
        return arView
    }
    
    public func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Kafes konumunu ve boyutunu gerçek dünya koordinatında güncelle
        context.coordinator.boundingBoxNode?.update(
            center: scannerEngine.boxCenter,
            size: scannerEngine.boxSize,
            isScanning: scannerEngine.scanState == .scanning
        )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator & ARSCNViewDelegate
    
    public class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARScanningContainerView
        var boundingBoxNode: BoundingBoxNode?
        weak var arView: ARSCNView?
        
        // Yeşil boyalı mesh görsel düğümleri (Anchor UUID -> SCNNode)
        private var visualMeshNodes = [UUID: SCNNode]()
        
        init(_ parent: ARScanningContainerView) {
            self.parent = parent
        }
        
        // MARK: - ARSCNViewDelegate: Canlı Mesh'i Yeşile Boyama
        
        public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return nil }
            
            let node = SCNNode()
            if let scnGeometry = createGreenHighlightGeometry(from: meshAnchor) {
                node.geometry = scnGeometry
            }
            visualMeshNodes[meshAnchor.identifier] = node
            return node
        }
        
        public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return }
            
            // Eğer tarama modundaysak kafes içindeki nesneyi anlık yeşile boya
            if parent.scannerEngine.scanState == .scanning {
                if let updatedGeo = createGreenHighlightGeometry(from: meshAnchor) {
                    node.geometry = updatedGeo
                } else {
                    node.geometry = nil
                }
            } else {
                node.geometry = nil
            }
        }
        
        public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            visualMeshNodes.removeValue(forKey: anchor.identifier)
        }
        
        /// Sadece kutunun içindeki poligonları seçip parlak NEON YEŞİLE boyayan geometri oluşturucu
        private func createGreenHighlightGeometry(from meshAnchor: ARMeshAnchor) -> SCNGeometry? {
            let geometry = meshAnchor.geometry
            let anchorTransform = meshAnchor.transform
            let verticesSource = geometry.vertices
            let faces = geometry.faces
            
            let boxCenter = parent.scannerEngine.boxCenter
            let boxSize = parent.scannerEngine.boxSize
            let halfSize = boxSize / 2.0
            let minB = boxCenter - halfSize
            let maxB = boxCenter + halfSize
            
            let tableCutoffY = parent.scannerEngine.detectedTableHeightY ?? minB.y
            
            // Köşeleri dünya koordinatına dönüştür
            var worldVertices = [SIMD3<Float>]()
            worldVertices.reserveCapacity(verticesSource.count)
            
            for i in 0..<verticesSource.count {
                let p = verticesSource.buffer.contents().advanced(by: verticesSource.offset + (verticesSource.stride * i))
                let localV = p.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                let w4 = anchorTransform * simd_float4(localV.x, localV.y, localV.z, 1.0)
                worldVertices.append(SIMD3<Float>(w4.x, w4.y, w4.z))
            }
            
            var greenVertices = [SIMD3<Float>]()
            var greenIndices = [UInt32]()
            
            let faceBuffer = faces.buffer.contents()
            let bytesPerIndex = faces.bytesPerIndex
            let faceStride = bytesPerIndex * faces.indexCountPerPrimitive
            
            for f in 0..<faces.count {
                let faceOffset = f * faceStride
                let i1, i2, i3: Int
                if bytesPerIndex == 2 {
                    let p = faceBuffer.advanced(by: faceOffset).assumingMemoryBound(to: UInt16.self)
                    i1 = Int(p.pointee); i2 = Int(p.advanced(by: 1).pointee); i3 = Int(p.advanced(by: 2).pointee)
                } else {
                    let p = faceBuffer.advanced(by: faceOffset).assumingMemoryBound(to: UInt32.self)
                    i1 = Int(p.pointee); i2 = Int(p.advanced(by: 1).pointee); i3 = Int(p.advanced(by: 2).pointee)
                }
                
                guard i1 < worldVertices.count, i2 < worldVertices.count, i3 < worldVertices.count else { continue }
                
                let v1 = worldVertices[i1]
                let v2 = worldVertices[i2]
                let v3 = worldVertices[i3]
                
                // Kutu içinde ve masanın üstünde mi?
                let inBox = (v1.x >= minB.x && v1.x <= maxB.x && v1.y >= minB.y && v1.y <= maxB.y && v1.z >= minB.z && v1.z <= maxB.z) ||
                            (v2.x >= minB.x && v2.x <= maxB.x && v2.y >= minB.y && v2.y <= maxB.y && v2.z >= minB.z && v2.z <= maxB.z)
                let aboveTable = v1.y > (tableCutoffY + 0.002)
                
                if inBox && aboveTable {
                    // Yerel anchor koordinatına geri çevirerek ekle (Node zaten anchor dönüşümüne sahip)
                    let invTransform = simd_inverse(anchorTransform)
                    let localV1 = invTransform * simd_float4(v1.x, v1.y, v1.z, 1.0)
                    let localV2 = invTransform * simd_float4(v2.x, v2.y, v2.z, 1.0)
                    let localV3 = invTransform * simd_float4(v3.x, v3.y, v3.z, 1.0)
                    
                    let base = UInt32(greenVertices.count)
                    greenVertices.append(SIMD3<Float>(localV1.x, localV1.y, localV1.z))
                    greenVertices.append(SIMD3<Float>(localV2.x, localV2.y, localV2.z))
                    greenVertices.append(SIMD3<Float>(localV3.x, localV3.y, localV3.z))
                    
                    greenIndices.append(base)
                    greenIndices.append(base + 1)
                    greenIndices.append(base + 2)
                }
            }
            
            guard !greenVertices.isEmpty else { return nil }
            
            let vData = Data(bytes: greenVertices, count: greenVertices.count * MemoryLayout<SIMD3<Float>>.stride)
            let vSource = SCNGeometrySource(
                data: vData,
                semantic: .vertex,
                vectorCount: greenVertices.count,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )
            
            let iData = Data(bytes: greenIndices, count: greenIndices.count * MemoryLayout<UInt32>.size)
            let element = SCNGeometryElement(
                data: iData,
                primitiveType: .triangles,
                primitiveCount: greenIndices.count / 3,
                bytesPerIndex: MemoryLayout<UInt32>.size
            )
            
            let scnGeo = SCNGeometry(sources: [vSource], elements: [element])
            
            // Neon Yeşil Parlayan Materyal (Kullanıcı nesneyi taradığını net görsün)
            let greenMat = SCNMaterial()
            greenMat.fillMode = .fill
            greenMat.diffuse.contents = UIColor(red: 0.0, green: 1.0, blue: 0.35, alpha: 0.75) // Parlak Neon Yeşil
            greenMat.emission.contents = UIColor(red: 0.0, green: 0.8, blue: 0.25, alpha: 0.6)
            greenMat.isDoubleSided = true
            
            scnGeo.materials = [greenMat]
            return scnGeo
        }
        
        // MARK: - Jest Yönetimi
        
        // 1. Dokunma: Masaya dokunarak kafesi oraya kilitle
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            // Masayı tespit et
            if let query = arView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal) {
                let results = arView.session.raycast(query)
                if let hit = results.first {
                    let worldPos = hit.worldTransform.columns.3
                    let targetPoint = SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)
                    
                    DispatchQueue.main.async {
                        self.parent.scannerEngine.placeBoxAt(worldPosition: targetPoint)
                    }
                    return
                }
            }
            
            // Herhangi bir yüzey raycast'i
            if let query = arView.raycastQuery(from: location, allowing: .any, alignment: .any) {
                let results = arView.session.raycast(query)
                if let hit = results.first {
                    let worldPos = hit.worldTransform.columns.3
                    let targetPoint = SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)
                    
                    DispatchQueue.main.async {
                        self.parent.scannerEngine.placeBoxAt(worldPosition: targetPoint)
                    }
                }
            }
        }
        
        // 2. İki Parmak Pinch: Küpü Büyüt / Küçült
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                let scaleDelta = Float(gesture.scale - 1.0) * 0.05
                DispatchQueue.main.async {
                    self.parent.scannerEngine.resizeBox(delta: scaleDelta)
                }
                gesture.scale = 1.0
            }
        }
        
        // 3. Tek Parmak Kaydırma: Küpü masada sağa/sola/öne kaydır
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView, gesture.state == .changed else { return }
            let location = gesture.location(in: arView)
            
            if let query = arView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal) {
                let results = arView.session.raycast(query)
                if let hit = results.first {
                    let worldPos = hit.worldTransform.columns.3
                    DispatchQueue.main.async {
                        self.parent.scannerEngine.placeBoxAt(worldPosition: SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z))
                    }
                }
            }
        }
    }
}
