import Foundation

/// 3D Dışa Aktarma Formatları
public enum ExportFormat: String, CaseIterable, Identifiable {
    case threeMF = "3mf"
    case stl = "stl"
    case obj = "obj"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .threeMF:
            return "Bambu Lab 3MF (.3mf)"
        case .stl:
            return "Standart STL (.stl)"
        case .obj:
            return "Wavefront OBJ (.obj)"
        }
    }
    
    public var badge: String {
        switch self {
        case .threeMF:
            return "Önerilen (Bambu)"
        case .stl:
            return "Evrensel 3D Baskı"
        case .obj:
            return "Genel 3D Mesh"
        }
    }
    
    public var fileExtension: String {
        return rawValue
    }
    
    public var mimeType: String {
        switch self {
        case .threeMF:
            return "application/vnd.ms-package.3dmanufacturing-3dmodel+xml"
        case .stl:
            return "model/stl"
        case .obj:
            return "model/obj"
        }
    }
    
    public var description: String {
        switch self {
        case .threeMF:
            return "Bambu Studio ve Bambu Handy için optimize edilmiş yerel format. Baskı tablaları, renk ve ölçek verilerini tam destekler."
        case .stl:
            return "Tüm 3D dilimleyiciler (Bambu Studio, OrcaSlicer, Cura, PrusaSlicer) ile %100 uyumlu ikili (binary) format."
        case .obj:
            return "Yüzey normalleri ve CAD/3D modelleme programları (Blender, Fusion 360 vb.) için ideal format."
        }
    }
}
