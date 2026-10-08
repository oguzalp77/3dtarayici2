import Foundation

/// Dışa aktarma işlemlerini ve geçici dosya yönetimini koordine eden yönetici
public final class MeshExportManager {
    public static let shared = MeshExportManager()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Modeli belirtilen formatta dosyaya kaydeder ve yerel dosya URL'sini döner
    public func exportFile(mesh: ScannedMesh, format: ExportFormat) throws -> URL {
        let fileName = sanitizeFileName("\(mesh.name).\(format.fileExtension)")
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("BambuScanExports", isDirectory: true)
        
        if !fileManager.fileExists(atPath: tempDir.path) {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let data: Data
        switch format {
        case .threeMF:
            data = ThreeMFExporter.export(mesh: mesh)
        case .stl:
            data = STLExporter.exportBinary(mesh: mesh)
        case .obj:
            data = OBJExporter.export(mesh: mesh)
        }
        
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
    
    /// Geçici dışa aktarma dosyalarını temizler
    public func clearTempFiles() {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("BambuScanExports", isDirectory: true)
        try? fileManager.removeItem(at: tempDir)
    }
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>| ")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}
