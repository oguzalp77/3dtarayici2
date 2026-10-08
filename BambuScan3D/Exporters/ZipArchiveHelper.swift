import Foundation

/// 3MF dosyalarını harici kütüphane gerektirmeden paketlemek için hafif ve saf Swift ZIP arşivi oluşturucu
public enum ZipArchiveHelper {
    
    public struct FileEntry {
        public let path: String
        public let data: Data
        
        public init(path: String, data: Data) {
            self.path = path
            self.data = data
        }
    }
    
    /// Verilen dosya listesinden standart bir ZIP arşivi (3MF için OPC uyumlu) üretir
    public static func createZip(entries: [FileEntry]) -> Data {
        var zipData = Data()
        var centralDirectoryData = Data()
        var fileOffsets = [UInt32]()
        
        // 1. Yerel Dosya Başlıkları (Local File Headers) & Veri Blokları
        for entry in entries {
            let offset = UInt32(zipData.count)
            fileOffsets.append(offset)
            
            let pathData = entry.path.data(using: .utf8) ?? Data()
            let crc = calculateCRC32(data: entry.data)
            let size = UInt32(entry.data.count)
            
            // Signature: 0x04034b50
            zipData.appendUInt32(0x04034b50)
            zipData.appendUInt16(20) // Version needed to extract (2.0)
            zipData.appendUInt16(0)  // General purpose bit flag
            zipData.appendUInt16(0)  // Compression method (0 = Stored / No compression)
            zipData.appendUInt16(0)  // Last mod file time
            zipData.appendUInt16(0)  // Last mod file date
            zipData.appendUInt32(crc) // CRC-32
            zipData.appendUInt32(size) // Compressed size
            zipData.appendUInt32(size) // Uncompressed size
            zipData.appendUInt16(UInt16(pathData.count)) // File name length
            zipData.appendUInt16(0)  // Extra field length
            
            zipData.append(pathData)
            zipData.append(entry.data)
        }
        
        let centralDirectoryOffset = UInt32(zipData.count)
        
        // 2. Merkezi Dizin Başlıkları (Central Directory File Headers)
        for (index, entry) in entries.enumerated() {
            let pathData = entry.path.data(using: .utf8) ?? Data()
            let crc = calculateCRC32(data: entry.data)
            let size = UInt32(entry.data.count)
            let offset = fileOffsets[index]
            
            // Signature: 0x02014b50
            centralDirectoryData.appendUInt32(0x02014b50)
            centralDirectoryData.appendUInt16(20) // Version made by
            centralDirectoryData.appendUInt16(20) // Version needed to extract
            centralDirectoryData.appendUInt16(0)  // General purpose bit flag
            centralDirectoryData.appendUInt16(0)  // Compression method (0 = Stored)
            centralDirectoryData.appendUInt16(0)  // Last mod file time
            centralDirectoryData.appendUInt16(0)  // Last mod file date
            centralDirectoryData.appendUInt32(crc) // CRC-32
            centralDirectoryData.appendUInt32(size) // Compressed size
            centralDirectoryData.appendUInt32(size) // Uncompressed size
            centralDirectoryData.appendUInt16(UInt16(pathData.count)) // File name length
            centralDirectoryData.appendUInt16(0)  // Extra field length
            centralDirectoryData.appendUInt16(0)  // File comment length
            centralDirectoryData.appendUInt16(0)  // Disk number start
            centralDirectoryData.appendUInt16(0)  // Internal file attributes
            centralDirectoryData.appendUInt32(0)  // External file attributes
            centralDirectoryData.appendUInt32(offset) // Relative offset of local header
            
            centralDirectoryData.append(pathData)
        }
        
        let centralDirectorySize = UInt32(centralDirectoryData.count)
        zipData.append(centralDirectoryData)
        
        // 3. Merkezi Dizin Sonu Kaydı (End of Central Directory Record)
        // Signature: 0x06054b50
        zipData.appendUInt32(0x06054b50)
        zipData.appendUInt16(0) // Number of this disk
        zipData.appendUInt16(0) // Disk where central directory starts
        zipData.appendUInt16(UInt16(entries.count)) // Number of central directory records on this disk
        zipData.appendUInt16(UInt16(entries.count)) // Total number of central directory records
        zipData.appendUInt32(centralDirectorySize) // Size of central directory
        zipData.appendUInt32(centralDirectoryOffset) // Offset of start of central directory
        zipData.appendUInt16(0) // Comment length
        
        return zipData
    }
    
    // IEEE 802.3 CRC-32 Hesaplama
    public static func calculateCRC32(data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ crc32Table[index]
        }
        return ~crc
    }
    
    private static let crc32Table: [UInt32] = {
        (0...255).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 != 0) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var val = value.littleEndian
        append(UnsafeBufferPointer(start: &val, count: 1))
    }
    
    mutating func appendUInt32(_ value: UInt32) {
        var val = value.littleEndian
        append(UnsafeBufferPointer(start: &val, count: 1))
    }
}
