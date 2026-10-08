import SwiftUI
import ARKit

/// BambuScan3D Ana Kontrol Paneli (Dashboard)
public struct MainDashboardView: View {
    @State private var navigateToScan: Bool = false
    @State private var selectedSampleMesh: ScannedMesh?
    @State private var navigateToPreview: Bool = false
    
    // LiDAR Donanım Durumu
    private var isLiDARSupported: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // 1. Donanım Durum Rozeti (iPhone 14 Pro Max LiDAR)
                    hardwareStatusBanner
                    
                    // 2. Ana Tarama Başlat Kartı (Hero Card)
                    heroScanCard
                    
                    // 3. Bambu Lab Entegrasyon Akışı (Nasıl Çalışır?)
                    workflowGuideSection
                    
                    // 4. Hazır Örnek / Önceki Taramalar Galerisi
                    sampleModelsSection
                }
                .padding()
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea())
            .navigationTitle("BambuScan 3D")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { BambuHandyConnector.shared.openBambuHandy() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Bambu Handy")
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.35))
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToScan) {
                ScanView()
            }
            .navigationDestination(isPresented: $navigateToPreview) {
                if let mesh = selectedSampleMesh {
                    ModelPreviewView(mesh: mesh)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // Donanım Durumu
    private var hardwareStatusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: isLiDARSupported ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isLiDARSupported ? .green : .orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isLiDARSupported ? "iPhone 14 Pro Max LiDAR Aktif" : "LiDAR Sensörü Bekleniyor")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(isLiDARSupported ? "Milimetrik dTOF derinlik sensörü 3D taramaya hazır." : "Gerçek zamanlı tarama için LiDAR sensörlü bir cihaz kullanın.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.14, blue: 0.17))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isLiDARSupported ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Hero Tarama Kartı
    private var heroScanCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3D Nesne Tara")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Evdeki eşyaları milimetrik hassasiyetle yakalayın ve Bambu Lab'a aktarın.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "viewfinder.circle.fill")
                    .font(.system(size: 46))
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.35))
            }
            
            Button(action: { navigateToScan = true }) {
                HStack {
                    Spacer()
                    Image(systemName: "camera.metering.matrix")
                        .font(.headline)
                    Text("Yeni Tarama Başlat")
                        .font(.headline)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .background(Color(red: 0.0, green: 0.68, blue: 0.26)) // Bambu Green
                .cornerRadius(14)
                .shadow(color: Color(red: 0.0, green: 0.68, blue: 0.26).opacity(0.4), radius: 10, y: 5)
            }
        }
        .padding(18)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .cornerRadius(18)
    }
    
    // Bambu Lab Entegrasyon Rehberi
    private var workflowGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bambu Lab İle Nasıl Çalışır?")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                stepRow(number: "1", title: "Kafes ile Sınırla", description: "Nesnenin etrafında yeşil tarama kafesini konumlandırarak masayı ve odayı filtreleyin.")
                stepRow(number: "2", title: "360° LiDAR Taraması", description: "iPhone 14 Pro Max kamerasını nesnenin etrafında yavaşça gezdirin.")
                stepRow(number: "3", title: "Otomatik Tabana Hizalama", description: "Model milimetreye ölçeklenir ve Z=0 baskı tablası zeminine kilitlenir.")
                stepRow(number: "4", title: "Bambu Handy & Studio", description: ".3MF veya .STL formatında tek dokunuşla dilimleyin veya baskıyı başlatın.")
            }
        }
        .padding(16)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .cornerRadius(16)
    }
    
    private func stepRow(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundColor(.black)
                .frame(width: 22, height: 22)
                .background(Color(red: 0.0, green: 0.85, blue: 0.35))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // Örnek / Test Modelleri
    private var sampleModelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hazır Test Modelleri")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("İncele & Gönder")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: openDemoModel) {
                HStack(spacing: 14) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title)
                        .foregroundColor(.green)
                        .padding(12)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bambu Kalibrasyon Küpü (20x20 mm)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("3D baskı tabana hizalı, .3MF ve .STL aktarımı için hazır.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(14)
                .background(Color(red: 0.12, green: 0.13, blue: 0.16))
                .cornerRadius(14)
            }
        }
    }
    
    private func openDemoModel() {
        // Test amaçlı 20x20x20 mm kalibrasyon küpü geometrisi
        let s: Float = 20.0
        let v: [SIMD3<Float>] = [
            // Alt yüz (Z = 0)
            SIMD3<Float>(-s/2, -s/2, 0), SIMD3<Float>(s/2, -s/2, 0), SIMD3<Float>(s/2, s/2, 0), SIMD3<Float>(-s/2, s/2, 0),
            // Üst yüz (Z = 20)
            SIMD3<Float>(-s/2, -s/2, s), SIMD3<Float>(s/2, -s/2, s), SIMD3<Float>(s/2, s/2, s), SIMD3<Float>(-s/2, s/2, s)
        ]
        
        let indices: [UInt32] = [
            // Alt
            0, 2, 1, 0, 3, 2,
            // Üst
            4, 5, 6, 4, 6, 7,
            // Ön
            0, 1, 5, 0, 5, 4,
            // Arka
            2, 3, 7, 2, 7, 6,
            // Sol
            3, 0, 4, 3, 4, 7,
            // Sağ
            1, 2, 6, 1, 6, 5
        ]
        
        let mesh = ScannedMesh(
            name: "Bambu_Kalibrasyon_Kupu_20mm",
            vertices: v,
            normals: [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 1), count: v.count),
            indices: indices
        )
        
        self.selectedSampleMesh = mesh
        self.navigateToPreview = true
    }
}
