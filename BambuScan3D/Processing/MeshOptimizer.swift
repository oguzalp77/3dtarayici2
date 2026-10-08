import Foundation
import simd

/// Taranan 3D model üzerindeki gürültüleri temizleyen ve baskı kalitesini artıran optimizasyon motoru
public enum MeshOptimizer {
    
    /// Modeli optimize eder: Çift köşeleri birleştirir, bozuk üçgenleri ayıklar ve isteğe bağlı taban düzleştirme uygular.
    public static func optimize(
        mesh: ScannedMesh,
        flattenBottomMm: Float? = nil,
        weldThresholdMm: Float = 0.5
    ) -> ScannedMesh {
        var vertices = mesh.vertices
        let indices = mesh.indices
        
        guard !vertices.isEmpty, !indices.isEmpty else {
            return mesh
        }
        
        // 1. Taban Düzleştirme (Baskı tablasına mükemmel yapışma için)
        // Eğer belirtilmişse, en alttaki tabaka noktalarını tabana kilitler
        if let flattenThreshold = flattenBottomMm, flattenThreshold > 0 {
            let minZ = mesh.boundingExtents.min.z
            let cutOffZ = minZ + flattenThreshold
            for i in 0..<vertices.count {
                if vertices[i].z <= cutOffZ {
                    vertices[i].z = minZ
                }
            }
        }
        
        // 2. Çift Köşeleri Birleştirme (Vertex Welding)
        // Uzamsal ızgara (Grid hash) kullanarak O(N) karmaşıklığında yakın noktaları birleştirir
        let (weldedVertices, indexMap) = weldVertices(vertices, threshold: weldThresholdMm)
        
        // İndeksleri yeni köşelere eşle
        var cleanedIndices = [UInt32]()
        cleanedIndices.reserveCapacity(indices.count)
        
        var i = 0
        while i + 2 < indices.count {
            let i1 = indexMap[Int(indices[i])]
            let i2 = indexMap[Int(indices[i + 1])]
            let i3 = indexMap[Int(indices[i + 2])]
            
            // Dejenere üçgen kontrolü (2 veya 3 köşesi aynı olan üçgenleri at)
            if i1 != i2 && i2 != i3 && i1 != i3 {
                let v1 = weldedVertices[Int(i1)]
                let v2 = weldedVertices[Int(i2)]
                let v3 = weldedVertices[Int(i3)]
                
                // Sıfır alanlı üçgen kontrolü
                let areaSquared = simd_length_squared(simd_cross(v2 - v1, v3 - v1))
                if areaSquared > 0.0001 {
                    cleanedIndices.append(i1)
                    cleanedIndices.append(i2)
                    cleanedIndices.append(i3)
                }
            }
            i += 3
        }
        
        // 3. Normalleri yeniden hesapla
        let recalculatedNormals = computeSmoothNormals(vertices: weldedVertices, indices: cleanedIndices)
        
        return ScannedMesh(
            id: mesh.id,
            name: mesh.name,
            date: mesh.date,
            vertices: weldedVertices,
            normals: recalculatedNormals,
            indices: cleanedIndices
        )
    }
    
    // Grid tabanlı köşe birleştirme
    private static func weldVertices(_ vertices: [SIMD3<Float>], threshold: Float) -> ([SIMD3<Float>], [UInt32]) {
        let invThresh = 1.0 / threshold
        var grid = [GridKey: UInt32]()
        var uniqueVertices = [SIMD3<Float>]()
        var indexMap = [UInt32](repeating: 0, count: vertices.count)
        
        uniqueVertices.reserveCapacity(vertices.count)
        
        for (idx, v) in vertices.enumerated() {
            let key = GridKey(
                x: Int(floor(v.x * invThresh)),
                y: Int(floor(v.y * invThresh)),
                z: Int(floor(v.z * invThresh))
            )
            
            if let existingIndex = grid[key] {
                indexMap[idx] = existingIndex
            } else {
                let newIndex = UInt32(uniqueVertices.count)
                uniqueVertices.append(v)
                grid[key] = newIndex
                indexMap[idx] = newIndex
            }
        }
        
        return (uniqueVertices, indexMap)
    }
    
    // Pürüzsüz yüzey normalleri hesaplama
    private static func computeSmoothNormals(vertices: [SIMD3<Float>], indices: [UInt32]) -> [SIMD3<Float>] {
        var vertexNormals = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: vertices.count)
        
        var i = 0
        while i + 2 < indices.count {
            let i1 = Int(indices[i])
            let i2 = Int(indices[i + 1])
            let i3 = Int(indices[i + 2])
            
            let v1 = vertices[i1]
            let v2 = vertices[i2]
            let v3 = vertices[i3]
            
            let normal = simd_cross(v2 - v1, v3 - v1)
            vertexNormals[i1] += normal
            vertexNormals[i2] += normal
            vertexNormals[i3] += normal
            
            i += 3
        }
        
        for j in 0..<vertexNormals.count {
            let len = simd_length(vertexNormals[j])
            if len > 0.00001 {
                vertexNormals[j] /= len
            } else {
                vertexNormals[j] = SIMD3<Float>(0, 0, 1)
            }
        }
        
        return vertexNormals
    }
    
    private struct GridKey: Hashable {
        let x: Int
        let y: Int
        let z: Int
    }
}
