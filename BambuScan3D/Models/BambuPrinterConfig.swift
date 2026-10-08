import Foundation

/// Bambu Lab 3D Yazıcı LAN Bağlantı Yapılandırması
public struct BambuPrinterConfig: Codable, Equatable {
    public var ipAddress: String
    public var accessCode: String
    public var serialNumber: String
    public var printerModel: BambuPrinterModel
    public var port: Int
    
    public init(ipAddress: String = "",
                accessCode: String = "",
                serialNumber: String = "",
                printerModel: BambuPrinterModel = .p1s,
                port: Int = 990) {
        self.ipAddress = ipAddress
        self.accessCode = accessCode
        self.serialNumber = serialNumber
        self.printerModel = printerModel
        self.port = port
    }
}

public enum BambuPrinterModel: String, CaseIterable, Codable, Identifiable {
    case x1Carbon = "Bambu Lab X1-Carbon"
    case p1s = "Bambu Lab P1S"
    case p1p = "Bambu Lab P1P"
    case a1 = "Bambu Lab A1"
    case a1Mini = "Bambu Lab A1 mini"
    
    public var id: String { rawValue }
    
    public var bedSize: SIMD3<Float> {
        switch self {
        case .a1Mini:
            return SIMD3<Float>(180, 180, 180) // 180x180x180 mm
        default:
            return SIMD3<Float>(256, 256, 256) // 256x256x256 mm
        }
    }
}
