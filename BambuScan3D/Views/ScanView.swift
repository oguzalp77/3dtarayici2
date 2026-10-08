import SwiftUI

/// 100% Tam Ekran, Canlı Görsel Geri Bildirimli LiDAR Tarama Ekranı
public struct ScanView: View {
    @StateObject private var engine = LidarScannerEngine()
    @Environment(\.dismiss) private var dismiss
    
    @State private var scannedMesh: ScannedMesh?
    @State private var navigateToPreview: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if engine.isLiDARAvailable {
                // 1. TAM EKRAN CANLI KAMERA & LIDAR (Hiçbir boşluk yok!)
                ARScanningContainerView(scannerEngine: engine)
                    .edgesIgnoringSafeArea(.all)
                
                // 2. ÜST BİLGİ VE REHBER KATMANI
                VStack {
                    topStatusBar
                    
                    Spacer()
                    
                    // 3. ALT KONTROL KATMANI (Duruma Göre Değişir)
                    bottomControls
                }
                .padding()
            } else {
                noLidarFallbackView
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .onAppear {
            if engine.isLiDARAvailable {
                engine.startSession()
            }
        }
        .onDisappear {
            engine.session.pause()
        }
        .navigationDestination(isPresented: $navigateToPreview) {
            if let mesh = scannedMesh {
                ModelPreviewView(mesh: mesh)
            }
        }
    }
    
    // MARK: - Üst Bar (Durum ve Rehber)
    
    private var topStatusBar: some View {
        HStack(alignment: .top) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Canlı Durum Mesajı
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(engine.scanState == .scanning ? Color.green : Color.cyan)
                        .frame(width: 10, height: 10)
                    
                    Text(engine.scanState == .scanning ? "TARANIYOR (YEŞİLE BOYANAN YERLER)" : "HİZALAMA MODU")
                        .font(.caption2.bold())
                        .foregroundColor(engine.scanState == .scanning ? Color.green : Color.cyan)
                }
                
                Text(engine.statusMessage)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 240)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Alt Kontroller
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            if engine.scanState == .positioning {
                // AŞAMA 1: KUTUYU HİZALAMA VE BOYUTLANDIRMA
                VStack(spacing: 10) {
                    // Boyut Ayar Butonları (- / + cm)
                    HStack(spacing: 16) {
                        Button(action: { engine.resizeBox(delta: -0.05) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.magnifyingglass")
                                Text("Küçült")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        
                        Text("\(Int(engine.boxSize.x * 100)) cm")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        
                        Button(action: { engine.resizeBox(delta: 0.05) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.magnifyingglass")
                                Text("Büyüt")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }
                    
                    // Taramayı Başlat Butonu
                    Button(action: { engine.startScanning() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "record.circle.fill")
                                .font(.title3)
                            Text("Taramayı Başlat")
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
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                
            } else if engine.scanState == .scanning {
                // AŞAMA 2: TARAMA AKTİF (YEŞİLE BOYANAN YERLERİ İZLEME)
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yakalanan Yüzeyler")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("\(engine.scannedTriangleCount.formatted()) Üçgen")
                                .font(.headline.bold())
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Text("Nesnenin etrafında dönün 🔄")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    
                    // Taramayı Bitir ve 3D Göster Butonu
                    Button(action: finishScanAndShow3D) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Taramayı Bitir & 3D Modeli Göster")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.0, green: 0.68, blue: 0.26))
                        .cornerRadius(28)
                        .shadow(color: Color.green.opacity(0.4), radius: 10, y: 5)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
        .padding(.bottom, 24)
    }
    
    private func finishScanAndShow3D() {
        if let mesh = engine.finishScanning() {
            self.scannedMesh = mesh
            self.navigateToPreview = true
        }
    }
    
    private var noLidarFallbackView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sensor.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.red)
            Text("LiDAR Sensörü Bulunamadı")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Lütfen iPhone 14 Pro Max cihazınızda çalıştırın.")
                .font(.subheadline)
                .foregroundColor(.gray)
            Button("Kapat") { dismiss() }
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
