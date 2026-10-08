import SwiftUI
import simd

/// Modelin fiziksel boyutlarını, poligon sayısını ve Bambu Lab tabla uyumluluğunu gösteren bilgi kartı
public struct MeshStatsCard: View {
    let mesh: ScannedMesh
    var printerModel: BambuPrinterModel = .p1s
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Başlık ve Tabla Uyumluluk Rozeti
            HStack {
                Label("3D Model Metrikleri", systemImage: "cube.transparent")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if fitsInBed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Tablaya Uygun")
                    }
                    .font(.caption.bold())
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.35))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.15).opacity(0.3))
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Tablayı Aşıyor")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            // Boyutlar (X, Y, Z mm)
            let dims = mesh.dimensions
            HStack(spacing: 12) {
                dimensionPill(title: "X (Genişlik)", value: String(format: "%.1f mm", dims.x), color: .blue)
                dimensionPill(title: "Y (Derinlik)", value: String(format: "%.1f mm", dims.y), color: .green)
                dimensionPill(title: "Z (Yükseklik)", value: String(format: "%.1f mm", dims.z), color: .purple)
            }
            
            // Geometri İstatistikleri
            HStack {
                metricItem(title: "Üçgen (Yüzey)", value: "\(mesh.triangleCount.formatted())", icon: "triangle.fill")
                Spacer()
                metricItem(title: "Köşe Noktası", value: "\(mesh.vertexCount.formatted())", icon: "circle.grid.3x3.fill")
                Spacer()
                metricItem(title: "Hedef Yazıcı", value: printerModel.rawValue.replacingOccurrences(of: "Bambu Lab ", with: ""), icon: "printer.fill")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var fitsInBed: Bool {
        let dims = mesh.dimensions
        let bed = printerModel.bedSize
        return dims.x <= bed.x && dims.y <= bed.y && dims.z <= bed.z
    }
    
    private func dimensionPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
    
    private func metricItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.gray)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
    }
}
