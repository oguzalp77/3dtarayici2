import Foundation
import simd

/// 3D Baskı Hazırlık ve Koordinat Dönüştürme Yardımcısı
/// ARKit koordinat sistemini (Y-yukarı, Metre) Bambu Studio / 3D Baskı koordinat sistemine (Z-yukarı, Milimetre) dönüştürür.
public enum PrintingPrepUtils {
    
    /// ARKit dünya koordinatlarından (Metre, Y-yukarı) 3D Baskı koordinatlarına (Milimetre, Z-yukarı) çevirir.
    /// ARKit: X = sağ, Y = yukarı, Z = arkaya (kamera yönü)
    /// 3D Baskı: X = sağ, Y = ileri, Z = yukarı
    public static func arkitTo3DPrintCoordinates(_ point: SIMD3<Float>) -> SIMD3<Float> {
        // Metreden milimetreye çevirme (x1000)
        // Y -> Z (Yükseklik)
        // -Z -> Y (İleri derinlik)
        // X -> X (Genişlik)
        return SIMD3<Float>(
            point.x * 1000.0,
            -point.z * 1000.0,
            point.y * 1000.0
        )
    }
    
    /// Modeli otomatik olarak 3D yazıcı tablasına (Z = 0) hizalar ve X, Y ekseninde merkezler.
    public static func prepareMeshForPrintBed(
        vertices: [SIMD3<Float>],
        centerXY: Bool = true,
        alignBaseToZZero: Bool = true
    ) -> (vertices: [SIMD3<Float>], boundingMin: SIMD3<Float>, boundingMax: SIMD3<Float>) {
        guard !vertices.isEmpty else {
            return ([], SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, 0))
        }
        
        // 1. Min / Max sınırları hesapla
        var minV = vertices[0]
        var maxV = vertices[0]
        for v in vertices {
            minV = simd_min(minV, v)
            maxV = simd_max(maxV, v)
        }
        
        let center = (minV + maxV) / 2.0
        let shiftX = centerXY ? -center.x : 0.0
        let shiftY = centerXY ? -center.y : 0.0
        let shiftZ = alignBaseToZZero ? -minV.z : 0.0
        
        let offset = SIMD3<Float>(shiftX, shiftY, shiftZ)
        
        // 2. Noktaları ötele
        var adjustedVertices = [SIMD3<Float>]()
        adjustedVertices.reserveCapacity(vertices.count)
        
        var newMin = vertices[0] + offset
        var newMax = vertices[0] + offset
        
        for v in vertices {
            let transformed = v + offset
            adjustedVertices.append(transformed)
            newMin = simd_min(newMin, transformed)
            newMax = simd_max(newMax, transformed)
        }
        
        return (adjustedVertices, newMin, newMax)
    }
    
    /// Verilen 3 köşe noktasından üçgenin normal vektörünü hesaplar
    public static func calculateNormal(v1: SIMD3<Float>, v2: SIMD3<Float>, v3: SIMD3<Float>) -> SIMD3<Float> {
        let edge1 = v2 - v1
        let edge2 = v3 - v1
        let normal = simd_cross(edge1, edge2)
        let length = simd_length(normal)
        if length > 0.00001 {
            return normal / length
        }
        return SIMD3<Float>(0, 0, 1)
    }
}
