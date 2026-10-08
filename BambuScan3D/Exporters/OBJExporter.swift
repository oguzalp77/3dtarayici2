import Foundation
import simd

/// Wavefront OBJ 3D Model Dışa Aktarıcı
public enum OBJExporter {
    
    /// Modeli OBJ formatında UTF-8 `Data` olarak oluşturur
    public static func export(mesh: ScannedMesh) -> Data {
        var objText = "# BambuScan3D OBJ Export\n"
        objText += "# Cihaz: iPhone 14 Pro Max LiDAR\n"
        objText += "# Olcek: Milimetre (mm)\n"
        objText += "o \(mesh.name.replacingOccurrences(of: " ", with: "_"))\n\n"
        
        // 1. Köşeler (Vertices: v x y z)
        for v in mesh.vertices {
            objText += String(format: "v %.4f %.4f %.4f\n", v.x, v.y, v.z)
        }
        objText += "\n"
        
        // 2. Normaller (Normals: vn x y z)
        for n in mesh.normals {
            objText += String(format: "vn %.4f %.4f %.4f\n", n.x, n.y, n.z)
        }
        objText += "\ns 1\n\n"
        
        // 3. Yüzeyler (Faces: f v1//vn1 v2//vn2 v3//vn3 - 1 Tabanlı İndeks)
        let indices = mesh.indices
        var i = 0
        let hasNormals = mesh.normals.count == mesh.vertices.count
        
        while i + 2 < indices.count {
            let i1 = indices[i] + 1
            let i2 = indices[i + 1] + 1
            let i3 = indices[i + 2] + 1
            
            if hasNormals {
                objText += "f \(i1)//\(i1) \(i2)//\(i2) \(i3)//\(i3)\n"
            } else {
                objText += "f \(i1) \(i2) \(i3)\n"
            }
            i += 3
        }
        
        return objText.data(using: .utf8) ?? Data()
    }
}
