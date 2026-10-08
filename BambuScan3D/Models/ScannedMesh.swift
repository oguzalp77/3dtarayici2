import Foundation
import simd

/// 3D baskı için taranmış model veri yapısı
public struct ScannedMesh: Identifiable {
    public let id: UUID
    public var name: String
    public var date: Date
    
    // Ham köşe noktaları (3D baskı koordinatlarında: mm cinsinden, Z yukarı)
    public var vertices: [SIMD3<Float>]
    
    // Yüzey normalleri
    public var normals: [SIMD3<Float>]
    
    // Üçgen indeksleri (her üç eleman bir üçgen oluşturur)
    public var indices: [UInt32]
    
    // Modelin fiziksel boyutları (milimetre cinsinden)
    public var dimensions: SIMD3<Float> {
        let (minBounds, maxBounds) = boundingExtents
        return maxBounds - minBounds
    }
    
    // Minimum ve maksimum sınırlar
    public var boundingExtents: (min: SIMD3<Float>, max: SIMD3<Float>) {
        guard !vertices.isEmpty else {
            return (SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, 0))
        }
        var minV = vertices[0]
        var maxV = vertices[0]
        for v in vertices {
            minV = simd_min(minV, v)
            maxV = simd_max(maxV, v)
        }
        return (minV, maxV)
    }
    
    // Üçgen sayısı
    public var triangleCount: Int {
        return indices.count / 3
    }
    
    // Köşe sayısı
    public var vertexCount: Int {
        return vertices.count
    }
    
    public init(id: UUID = UUID(),
                name: String = "Bambu_Model_\(Date().formatted(.dateTime.month().day().hour().minute()))",
                date: Date = Date(),
                vertices: [SIMD3<Float>],
                normals: [SIMD3<Float>],
                indices: [UInt32]) {
        self.id = id
        self.name = name
        self.date = date
        self.vertices = vertices
        self.normals = normals
        self.indices = indices
    }
}
