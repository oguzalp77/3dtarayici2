import Foundation
import simd

/// Bambu Lab / Bambu Studio / Bambu Handy için Yerel 3MF (3D Manufacturing Format) Dışa Aktarıcı
/// 3MF Core Spesifikasyonu ve Open Packaging Conventions (OPC) standartlarına tam uyumludur.
public enum ThreeMFExporter {
    
    /// Modeli sıkıştırılmış .3mf konteyneri olarak `Data` formatında oluşturur
    public static func export(mesh: ScannedMesh) -> Data {
        let contentTypesXML = generateContentTypesXML()
        let relsXML = generateRelationshipsXML()
        let modelXML = generate3DModelXML(mesh: mesh)
        
        let entries = [
            ZipArchiveHelper.FileEntry(
                path: "[Content_Types].xml",
                data: contentTypesXML.data(using: .utf8) ?? Data()
            ),
            ZipArchiveHelper.FileEntry(
                path: "_rels/.rels",
                data: relsXML.data(using: .utf8) ?? Data()
            ),
            ZipArchiveHelper.FileEntry(
                path: "3D/3dmodel.model",
                data: modelXML.data(using: .utf8) ?? Data()
            )
        ]
        
        return ZipArchiveHelper.createZip(entries: entries)
    }
    
    private static func generateContentTypesXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
        </Types>
        """
    }
    
    private static func generateRelationshipsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
        </Relationships>
        """
    }
    
    private static func generate3DModelXML(mesh: ScannedMesh) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
          <metadata name="Title">\(escapeXML(mesh.name))</metadata>
          <metadata name="Designer">iPhone 14 Pro Max LiDAR</metadata>
          <metadata name="Application">BambuScan3D</metadata>
          <metadata name="CreationDate">\(ISO8601DateFormatter().string(from: mesh.date))</metadata>
          <resources>
            <object id="1" type="model">
              <mesh>
                <vertices>
        
        """
        
        // 1. Köşeler (Vertices)
        for v in mesh.vertices {
            xml += String(format: "          <vertex x=\"%.4f\" y=\"%.4f\" z=\"%.4f\" />\n", v.x, v.y, v.z)
        }
        
        xml += """
                </vertices>
                <triangles>
        
        """
        
        // 2. Üçgenler (Triangles: 0 tabanlı indeks)
        let indices = mesh.indices
        var i = 0
        while i + 2 < indices.count {
            let v1 = indices[i]
            let v2 = indices[i + 1]
            let v3 = indices[i + 2]
            xml += "          <triangle v1=\"\(v1)\" v2=\"\(v2)\" v3=\"\(v3)\" />\n"
            i += 3
        }
        
        xml += """
                </triangles>
              </mesh>
            </object>
          </resources>
          <build>
            <item objectid="1" />
          </build>
        </model>
        """
        
        return xml
    }
    
    private static func escapeXML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
