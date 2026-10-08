import Foundation
import ARKit
import Combine
import simd

/// Gelişmiş LiDAR Tarama ve Gerçek Dünya Konumlandırma Motoru
public final class LidarScannerEngine: NSObject, ObservableObject, ARSessionDelegate {
    
    public let session = ARSession()
    
    // LiDAR Donanım Durumu
    @Published public private(set) var isLiDARAvailable: Bool = false
    
    // Tarama Aşamaları:
    // .positioning: Kullanıcı kutuyu masaya yerleştiriyor ve boyutunu ayarlıyor
    // .scanning: LiDAR taraması aktif, taranan yerler yeşile boyanıyor
    // .completed: Tarama bitti, 3D model hazırlandı
    public enum ScanState: Equatable {
        case positioning
        case scanning
        case completed
    }
    
    @Published public var scanState: ScanState = .positioning
    @Published public var isBoxPlaced: Bool = false
    
    // Anlık İstatistikler
    @Published public var scannedVertexCount: Int = 0
    @Published public var scannedTriangleCount: Int = 0
    @Published public var statusMessage: String = "Masaya dokunarak tarama kafesini nesnenin üzerine yerleştirin."
    
    // Gerçek Dünya Koordinatlarında Kilitli 3D Tarama Kutusu (Metre cinsinden)
    // Bu kutu dünyada sabittir; kamerayı nereye çevirirseniz çevirin o noktada kalır!
    @Published public var boxCenter: SIMD3<Float> = SIMD3<Float>(0, -0.1, -0.5)
    @Published public var boxSize: SIMD3<Float> = SIMD3<Float>(0.20, 0.20, 0.20) // 20cm x 20cm x 20cm
    
    // Masa / Zemin Yüksekliği (Nesneyi masadan ayırmak için alt kesme düzlemi)
    public var detectedTableHeightY: Float? = nil
    
    // Canlı ARMeshAnchor verileri
    public var meshAnchors = [UUID: ARMeshAnchor]()
    
    // Üretilen 3D Model
    @Published public var finalMesh: ScannedMesh?
    
    public override init() {
        super.init()
        checkLiDARCapabilities()
        session.delegate = self
    }
    
    private func checkLiDARCapabilities() {
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    /// AR Oturumunu Başlatır (Yatay masa tespiti ve LiDAR mesh ile)
    public func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        meshAnchors.removeAll()
        scannedVertexCount = 0
        scannedTriangleCount = 0
        finalMesh = nil
        scanState = .positioning
        isBoxPlaced = false
        statusMessage = "Masaya dokunarak tarama kafesini nesnenin üzerine yerleştirin."
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// Masaya dokunulduğunda kafesi o fiziksel noktaya kilitler (Gerçek dünya koordinatı)
    public func placeBoxAt(worldPosition: SIMD3<Float>) {
        // Masanın yüksekliğini kaydet
        self.detectedTableHeightY = worldPosition.y
        
        // Kutunun tabanı tam masaya bassın: Merkez Y = Masa Y + (Kutu Yüksekliği / 2)
        let centerY = worldPosition.y + (boxSize.y / 2.0)
        self.boxCenter = SIMD3<Float>(worldPosition.x, centerY, worldPosition.z)
        self.isBoxPlaced = true
        self.statusMessage = "Kafes masaya kilitlendi. Boyutunu ayarlayıp 'Taramayı Başlat'a basın."
    }
    
    /// Kutuyu büyüt / küçült (+/- cm)
    public func resizeBox(delta: Float) {
        let newX = max(0.05, min(0.60, boxSize.x + delta))
        let newY = max(0.05, min(0.60, boxSize.y + delta))
        let newZ = max(0.05, min(0.60, boxSize.z + delta))
        
        // Eğer masa tespit edilmişse, alt tabanı masada tutarak yüksekliği güncelle
        if let tableY = detectedTableHeightY {
            boxSize = SIMD3<Float>(newX, newY, newZ)
            boxCenter.y = tableY + (newY / 2.0)
        } else {
            boxSize = SIMD3<Float>(newX, newY, newZ)
        }
    }
    
    /// Taramayı Başlatır (Kullanıcı nesnenin etrafında döner, mesh yeşile boyanır)
    public func startScanning() {
        scanState = .scanning
        meshAnchors.removeAll()
        statusMessage = "Nesnenin etrafında yavaşça dönün. Yeşile boyanan yerler taranıyor!"
    }
    
    /// Taramayı Tamamlar ve Masadan Ayıklanmış 3D Modeli Üretir
    public func finishScanning() -> ScannedMesh? {
        scanState = .completed
        session.pause()
        statusMessage = "Model masadan ayrıştırılıyor ve 3D baskıya hazırlanıyor..."
        
        // 1. Sadece kutunun içindeki ve masa yüzeyinin üstündeki noktaları topla
        let (rawVertices, rawNormals, rawIndices) = extractIsolatedObjectMesh()
        
        guard !rawVertices.isEmpty, !rawIndices.isEmpty else {
            statusMessage = "Hata: Kafes içinde yeterli nesne geometrisi bulunamadı."
            return nil
        }
        
        // 2. ARKit (Metre, Y-yukarı) -> 3D Baskı (Milimetre, Z-yukarı)
        let mmVertices = rawVertices.map { PrintingPrepUtils.arkitTo3DPrintCoordinates($0) }
        let mmNormals = rawNormals.map { PrintingPrepUtils.arkitTo3DPrintCoordinates($0) }
        
        // 3. Tabana (Z=0) oturt ve merkezle
        let (alignedVertices, _, _) = PrintingPrepUtils.prepareMeshForPrintBed(
            vertices: mmVertices,
            centerXY: true,
            alignBaseToZZero: true
        )
        
        let initialMesh = ScannedMesh(
            name: "Bambu_Nesne_\(Date().formatted(.dateTime.hour().minute().second()))",
            vertices: alignedVertices,
            normals: mmNormals,
            indices: rawIndices
        )
        
        // 4. Optimizasyon: Çift noktaları birleştir ve tabanı düzle
        let optimized = MeshOptimizer.optimize(mesh: initialMesh, flattenBottomMm: 0.8, weldThresholdMm: 0.7)
        
        self.finalMesh = optimized
        self.statusMessage = "Tarama tamamlandı! \(optimized.triangleCount) yüzey oluşturuldu."
        return optimized
    }
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        updateMeshAnchors(anchors)
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        updateMeshAnchors(anchors)
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            meshAnchors.removeValue(forKey: anchor.identifier)
        }
    }
    
    private func updateMeshAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                meshAnchors[meshAnchor.identifier] = meshAnchor
            }
        }
        
        // Anlık sayaç
        if scanState == .scanning {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                var vCount = 0
                var fCount = 0
                for (_, anchor) in self.meshAnchors {
                    vCount += anchor.geometry.vertices.count
                    fCount += anchor.geometry.faces.count
                }
                self.scannedVertexCount = vCount
                self.scannedTriangleCount = fCount
            }
        }
    }
    
    // MARK: - Nesneyi Masadan Ayıklama ve Sadece Kutu İçini Alma
    
    private func extractIsolatedObjectMesh() -> (vertices: [SIMD3<Float>], normals: [SIMD3<Float>], indices: [UInt32]) {
        var worldVertices = [SIMD3<Float>]()
        var worldNormals = [SIMD3<Float>]()
        var accumulatedIndices = [UInt32]()
        
        let halfSize = boxSize / 2.0
        let minBound = boxCenter - halfSize
        let maxBound = boxCenter + halfSize
        
        // Masayı ayıklamak için alt eşik: Masanın 2-3 mm üstünden kes
        let tableFloorCutoffY: Float
        if let tableY = detectedTableHeightY {
            tableFloorCutoffY = tableY + 0.003 // Masadan 3 mm yukarısı (masayı tamamen siler!)
        } else {
            tableFloorCutoffY = minBound.y + 0.003
        }
        
        for (_, meshAnchor) in meshAnchors {
            let geometry = meshAnchor.geometry
            let anchorTransform = meshAnchor.transform
            let verticesSource = geometry.vertices
            let normalsSource = geometry.normals
            let faces = geometry.faces
            
            // Köşeleri dünya koordinatına çevir
            var anchorWorldVertices = [SIMD3<Float>]()
            anchorWorldVertices.reserveCapacity(verticesSource.count)
            
            for i in 0..<verticesSource.count {
                let vertexPointer = verticesSource.buffer.contents().advanced(by: verticesSource.offset + (verticesSource.stride * i))
                let localV = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                let worldPos4 = anchorTransform * simd_float4(localV.x, localV.y, localV.z, 1.0)
                anchorWorldVertices.append(SIMD3<Float>(worldPos4.x, worldPos4.y, worldPos4.z))
            }
            
            // Normalleri dünya koordinatına çevir
            var anchorWorldNormals = [SIMD3<Float>]()
            anchorWorldNormals.reserveCapacity(normalsSource.count)
            
            for i in 0..<normalsSource.count {
                let normalPointer = normalsSource.buffer.contents().advanced(by: normalsSource.offset + (normalsSource.stride * i))
                let localN = normalPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                let worldN4 = anchorTransform * simd_float4(localN.x, localN.y, localN.z, 0.0)
                anchorWorldNormals.append(simd_normalize(SIMD3<Float>(worldN4.x, worldN4.y, worldN4.z)))
            }
            
            // Üçgenleri filtrele
            let faceBuffer = faces.buffer.contents()
            let bytesPerIndex = faces.bytesPerIndex
            let faceStride = bytesPerIndex * faces.indexCountPerPrimitive
            
            for f in 0..<faces.count {
                let faceOffset = f * faceStride
                let idx1: Int
                let idx2: Int
                let idx3: Int
                
                if bytesPerIndex == 2 {
                    let p = faceBuffer.advanced(by: faceOffset).assumingMemoryBound(to: UInt16.self)
                    idx1 = Int(p.pointee)
                    idx2 = Int(p.advanced(by: 1).pointee)
                    idx3 = Int(p.advanced(by: 2).pointee)
                } else {
                    let p = faceBuffer.advanced(by: faceOffset).assumingMemoryBound(to: UInt32.self)
                    idx1 = Int(p.pointee)
                    idx2 = Int(p.advanced(by: 1).pointee)
                    idx3 = Int(p.advanced(by: 2).pointee)
                }
                
                guard idx1 < anchorWorldVertices.count,
                      idx2 < anchorWorldVertices.count,
                      idx3 < anchorWorldVertices.count else { continue }
                
                let v1 = anchorWorldVertices[idx1]
                let v2 = anchorWorldVertices[idx2]
                let v3 = anchorWorldVertices[idx3]
                
                // 1. Kutu içinde mi kontrolü?
                let inBox1 = isPointInBox(v1, minBound: minBound, maxBound: maxBound)
                let inBox2 = isPointInBox(v2, minBound: minBound, maxBound: maxBound)
                let inBox3 = isPointInBox(v3, minBound: minBound, maxBound: maxBound)
                
                // 2. Masadan yukarıda mı kontrolü (Masayı ayırma)?
                let aboveTable1 = v1.y >= tableFloorCutoffY
                let aboveTable2 = v2.y >= tableFloorCutoffY
                let aboveTable3 = v3.y >= tableFloorCutoffY
                
                // Üçgenin köşeleri hem kutunun içinde hem de masa tablasının üstünde olmalı!
                if inBox1 && inBox2 && inBox3 && aboveTable1 && aboveTable2 && aboveTable3 {
                    let baseIdx = UInt32(worldVertices.count)
                    worldVertices.append(v1)
                    worldVertices.append(v2)
                    worldVertices.append(v3)
                    
                    if idx1 < anchorWorldNormals.count && idx2 < anchorWorldNormals.count && idx3 < anchorWorldNormals.count {
                        worldNormals.append(anchorWorldNormals[idx1])
                        worldNormals.append(anchorWorldNormals[idx2])
                        worldNormals.append(anchorWorldNormals[idx3])
                    } else {
                        let normal = PrintingPrepUtils.calculateNormal(v1: v1, v2: v2, v3: v3)
                        worldNormals.append(normal)
                        worldNormals.append(normal)
                        worldNormals.append(normal)
                    }
                    
                    accumulatedIndices.append(baseIdx)
                    accumulatedIndices.append(baseIdx + 1)
                    accumulatedIndices.append(baseIdx + 2)
                }
            }
        }
        
        return (worldVertices, worldNormals, accumulatedIndices)
    }
    
    private func isPointInBox(_ p: SIMD3<Float>, minBound: SIMD3<Float>, maxBound: SIMD3<Float>) -> Bool {
        return p.x >= minBound.x && p.x <= maxBound.x &&
               p.y >= minBound.y && p.y <= maxBound.y &&
               p.z >= minBound.z && p.z <= maxBound.z
    }
}
