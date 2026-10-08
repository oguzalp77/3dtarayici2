import SwiftUI
import simd

/// Canlı LiDAR tarama ekranı üzerindeki kontroller ve bilgi katmanı
public struct ScanningHUDOverlay: View {
    @ObservedObject var engine: LidarScannerEngine
    @Binding var showBoxSettings: Bool
    let onFinish: () -> Void
    let onCancel: () -> Void
    
    public var body: some View {
        VStack {
            // Üst Bilgi Barı
            topMetricsBar
            
            Spacer()
            
            // Eğer ayarlar açıksa Kafes Ayarları Paneli
            if showBoxSettings {
                cageSettingsPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Alt Eylem Butonları
            bottomActionControls
        }
        .padding()
        .animation(.easeInOut, value: showBoxSettings)
    }
    
    // Üst Bar: Durum ve Sayaçlar
    private var topMetricsBar: some View {
        HStack {
            // Kayıt Göstergesi & Durum
            HStack(spacing: 8) {
                Circle()
                    .fill(engine.scanState == .scanning ? Color.red : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text(engine.statusMessage)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Poligon Sayacı
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(engine.scannedTriangleCount) Yüzey")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                    Text("\(engine.meshAnchors.count) Mesh Bloku")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // Kafes Ayarları Paneli
    private var cageSettingsPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tarama Kafesi Boyutları (cm)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showBoxSettings = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 8) {
                sliderRow(title: "Genişlik (X)", value: Binding(
                    get: { engine.boxSize.x * 100.0 },
                    set: { engine.boxSize.x = $0 / 100.0 }
                ), range: 5...60)
                
                sliderRow(title: "Yükseklik (Y)", value: Binding(
                    get: { engine.boxSize.y * 100.0 },
                    set: { newValue in
                        engine.boxSize.y = newValue / 100.0
                        if let tableY = engine.detectedTableHeightY {
                            engine.boxCenter.y = tableY + (engine.boxSize.y / 2.0)
                        }
                    }
                ), range: 5...60)
                
                sliderRow(title: "Derinlik (Z)", value: Binding(
                    get: { engine.boxSize.z * 100.0 },
                    set: { engine.boxSize.z = $0 / 100.0 }
                ), range: 5...60)
            }
            
            Button(action: {
                engine.detectedTableHeightY = nil
                engine.boxCenter = SIMD3<Float>(0, -0.1, -0.5)
                engine.isBoxPlaced = false
            }) {
                Label("Kafesi Kameranın Önüne Getir", systemImage: "arrow.triangle.2.circlepath.camera")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.4))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.bottom, 8)
    }
    
    private func sliderRow(title: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            Slider(value: value, in: range, step: 1.0)
                .accentColor(.green)
            Text("\(Int(value.wrappedValue)) cm")
                .font(.caption.monospacedDigit())
                .foregroundColor(.white)
                .frame(width: 45, alignment: .trailing)
        }
    }
    
    // Alt Kontroller
    private var bottomActionControls: some View {
        HStack(spacing: 14) {
            // İptal Butonu
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Kafes Boyutu Aç/Kapa Butonu
            Button(action: { showBoxSettings.toggle() }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundColor(showBoxSettings ? .green : .white)
                    .frame(width: 54, height: 54)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            // Taramayı Tamamla Butonu (Bambu Green)
            Button(action: onFinish) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Taramayı Bitir")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(red: 0.0, green: 0.68, blue: 0.26)) // Bambu Green
                .cornerRadius(27)
                .shadow(color: Color(red: 0.0, green: 0.68, blue: 0.26).opacity(0.4), radius: 8, y: 4)
            }
        }
    }
}
