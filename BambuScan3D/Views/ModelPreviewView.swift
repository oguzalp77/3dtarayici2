import SwiftUI

/// Taranan 3D modelin incelendiği ve Bambu Lab'a aktarıldığı detay ekranı
public struct ModelPreviewView: View {
    @State var mesh: ScannedMesh
    @Environment(\.dismiss) private var dismiss
    
    @State private var showWireframe: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var modelName: String = ""
    @State private var isRenaming: Bool = false
    
    public init(mesh: ScannedMesh) {
        _mesh = State(initialValue: mesh)
        _modelName = State(initialValue: mesh.name)
    }
    
    public var body: some View {
        ZStack {
            // 1. Arka Plan: 3D İnteraktif SceneKit Alanı
            ModelViewer3DContainer(mesh: mesh, showWireframe: showWireframe)
                .ignoresSafeArea()
            
            // 2. Üst ve Alt Arayüz Katmanları
            VStack {
                // Üst Bar: Model Adı ve Tel Çerçeve Modu Butonu
                topToolbar
                
                Spacer()
                
                // Alt Bölüm: Metrik Kartı & Bambu Lab Gönder Butonu
                bottomPanel
            }
            .padding()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showExportSheet) {
            BambuExportModalView(mesh: mesh)
        }
    }
    
    // Üst Bar
    private var topToolbar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // İsimlendirme
            HStack {
                Text(modelName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Tel Çerçeve / Katı Görünüm Geçişi
            Button(action: { showWireframe.toggle() }) {
                Image(systemName: showWireframe ? "grid" : "cube.fill")
                    .font(.subheadline)
                    .foregroundColor(showWireframe ? .green : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }
    
    // Alt Panel
    private var bottomPanel: some View {
        VStack(spacing: 12) {
            // Boyut ve Yüzey Kartı
            MeshStatsCard(mesh: mesh)
            
            // Bambu Lab'a Gönder Butonu
            Button(action: { showExportSheet = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.title3)
                    Text("Bambu Lab'a Gönder (.3MF / .STL)")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(red: 0.0, green: 0.68, blue: 0.26)) // Bambu Green
                .cornerRadius(16)
                .shadow(color: Color(red: 0.0, green: 0.68, blue: 0.26).opacity(0.4), radius: 8, y: 4)
            }
        }
    }
}
