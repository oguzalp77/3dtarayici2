import Foundation
import simd

/// Taranacak nesneyi çevreleyen 3D Tarama Kutusu (Bounding Cage)
/// Bu kutu sadece hedeflenen nesnenin taranmasını sağlar, masa, zemin veya çevredeki gürültüleri eler.
public struct ScanningBoundingBox: Equatable {
    // Kutunun merkez konumu (ARKit dünya koordinatlarında, metre cinsinden)
    public var center: SIMD3<Float>
    
    // Boyutlar (Genişlik: X, Yükseklik: Y, Derinlik: Z - metre cinsinden)
    public var size: SIMD3<Float>
    
    // Kutunun yönelimi (Euler açıları veya rotasyon)
    public var rotationY: Float
    
    // Standart ev eşyası boyutu (Örn: 20cm x 20cm x 20cm)
    public static let standard = ScanningBoundingBox(
        center: SIMD3<Float>(0, 0, -0.6), // Kameranın 60 cm önünde
        size: SIMD3<Float>(0.25, 0.25, 0.25), // 25cm x 25cm x 25cm
        rotationY: 0.0
    )
    
    public init(center: SIMD3<Float>, size: SIMD3<Float>, rotationY: Float = 0.0) {
        self.center = center
        self.size = size
        self.rotationY = rotationY
    }
    
    // Belirtilen noktanın tarama kutusu içinde olup olmadığını test eder
    public func contains(point: SIMD3<Float>) -> Bool {
        let halfSize = size / 2.0
        let minBound = center - halfSize
        let maxBound = center + halfSize
        
        return point.x >= minBound.x && point.x <= maxBound.x &&
               point.y >= minBound.y && point.y <= maxBound.y &&
               point.z >= minBound.z && point.z <= maxBound.z
    }
    
    // Boyutları santimetre olarak okuma/yazma yardımcıları
    public var widthCm: Float {
        get { size.x * 100.0 }
        set { size.x = max(0.05, newValue / 100.0) }
    }
    
    public var heightCm: Float {
        get { size.y * 100.0 }
        set { size.y = max(0.05, newValue / 100.0) }
    }
    
    public var depthCm: Float {
        get { size.z * 100.0 }
        set { size.z = max(0.05, newValue / 100.0) }
    }
}
