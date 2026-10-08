import Foundation
import simd

/// Standart 3D Baskı STL (Stereolithography) İkili (Binary) Dışa Aktarıcı
/// Bambu Studio, OrcaSlicer, Bambu Handy ve tüm FDM/SLA dilimleyiciler ile %100 uyumludur.
public enum STLExporter {
    
    /// Modeli ikili (Binary) STL formatında `Data` olarak oluşturur
    public static func exportBinary(mesh: ScannedMesh) -> Data {
        let triangleCount = UInt32(mesh.triangleCount)
        
        // Binary STL Dosya Boyutu: 80 byte başlık + 4 byte üçgen sayısı + (üçgen sayısı * 50 byte)
        let totalSize = 80 + 4 + (Int(triangleCount) * 50)
        var data = Data(capacity: totalSize)
        
        // 1. 80 Baytlık Başlık (Header)
        var headerString = "BambuScan3D - iPhone 14 Pro Max LiDAR Model for Bambu Lab"
        // 80 karaktere tamamla
        if headerString.count < 80 {
            headerString = headerString.padding(toLength: 80, withPad: " ", startingAt: 0)
        } else {
            headerString = String(headerString.prefix(80))
        }
        if let headerData = headerString.data(using: .ascii) {
            data.append(headerData)
        } else {
            data.append(Data(count: 80))
        }
        
        // 2. 4 Baytlık Üçgen Sayısı (Little Endian)
        var count = triangleCount.littleEndian
        data.append(UnsafeBufferPointer(start: &count, count: 1))
        
        // 3. Üçgenler (Her biri 50 Bayt)
        // [Normal: 12 byte] [V1: 12 byte] [V2: 12 byte] [V3: 12 byte] [Attr: 2 byte]
        let vertices = mesh.vertices
        let indices = mesh.indices
        var zeroAttr: UInt16 = 0
        
        var i = 0
        while i + 2 < indices.count {
            let idx1 = Int(indices[i])
            let idx2 = Int(indices[i + 1])
            let idx3 = Int(indices[i + 2])
            
            guard idx1 < vertices.count, idx2 < vertices.count, idx3 < vertices.count else {
                i += 3
                continue
            }
            
            let v1 = vertices[idx1]
            let v2 = vertices[idx2]
            let v3 = vertices[idx3]
            
            // Yüzey normali
            let normal = PrintingPrepUtils.calculateNormal(v1: v1, v2: v2, v3: v3)
            
            // Normal (nx, ny, nz) - Float32 Little Endian
            appendFloat3(&data, normal)
            
            // Köşeler (v1, v2, v3)
            appendFloat3(&data, v1)
            appendFloat3(&data, v2)
            appendFloat3(&data, v3)
            
            // Attribute byte count (2 bayt = 0)
            data.append(UnsafeBufferPointer(start: &zeroAttr, count: 1))
            
            i += 3
        }
        
        return data
    }
    
    // ASCII STL Dışa Aktarıcı (Metin formatı, hata ayıklama için)
    public static func exportASCII(mesh: ScannedMesh) -> String {
        var str = "solid BambuScan3D\n"
        let vertices = mesh.vertices
        let indices = mesh.indices
        
        var i = 0
        while i + 2 < indices.count {
            let v1 = vertices[Int(indices[i])]
            let v2 = vertices[Int(indices[i + 1])]
            let v3 = vertices[Int(indices[i + 2])]
            let normal = PrintingPrepUtils.calculateNormal(v1: v1, v2: v2, v3: v3)
            
            str += "  facet normal \(normal.x) \(normal.y) \(normal.z)\n"
            str += "    outer loop\n"
            str += "      vertex \(v1.x) \(v1.y) \(v1.z)\n"
            str += "      vertex \(v2.x) \(v2.y) \(v2.z)\n"
            str += "      vertex \(v3.x) \(v3.y) \(v3.z)\n"
            str += "    endloop\n"
            str += "  endfacet\n"
            
            i += 3
        }
        str += "endsolid BambuScan3D\n"
        return str
    }
    
    private static func appendFloat3(_ data: inout Data, _ v: SIMD3<Float>) {
        var x = v.x.bitPattern.littleEndian
        var y = v.y.bitPattern.littleEndian
        var z = v.z.bitPattern.littleEndian
        data.append(UnsafeBufferPointer(start: &x, count: 1))
        data.append(UnsafeBufferPointer(start: &y, count: 1))
        data.append(UnsafeBufferPointer(start: &z, count: 1))
    }
}
