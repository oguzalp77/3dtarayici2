import SwiftUI

/// 3D Modeli Bambu Lab ekosistemine (.3MF, .STL, .OBJ) aktarma ve gönderme modalı
public struct BambuExportModalView: View {
    let mesh: ScannedMesh
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ExportFormat = .threeMF
    @State private var exportedFileURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var showDirectPrinterSheet: Bool = false
    @State private var errorMessage: String?
    @State private var isExporting: Bool = false
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Format Seçici Kartları
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dışa Aktarma Formatı Seçin")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(ExportFormat.allCases) { format in
                            formatSelectionCard(format: format)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Hızlı Eylemler & Bambu Lab Entegrasyonu
                VStack(spacing: 12) {
                    // 1. Ana Eylem: Bambu Handy ile Aç
                    Button(action: exportAndShare) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title3)
                            Text("Bambu Handy ile Aç / Paylaş")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(red: 0.0, green: 0.68, blue: 0.26)) // Bambu Green
                        .cornerRadius(14)
                        .shadow(color: Color(red: 0.0, green: 0.68, blue: 0.26).opacity(0.3), radius: 6, y: 3)
                    }
                    
                    // 2. Wi-Fi ile Doğrudan Yazıcıya Gönder (X1C/P1S/P1P/A1)
                    Button(action: { showDirectPrinterSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi")
                            Text("Doğrudan Yazıcıya Gönder (Wi-Fi LAN)")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 0.16, green: 0.18, blue: 0.22))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top)
            .background(Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea())
            .navigationTitle("Bambu Lab'a Gönder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showDirectPrinterSheet) {
                DirectPrinterConnectView(mesh: mesh, format: selectedFormat)
            }
        }
    }
    
    private func formatSelectionCard(format: ExportFormat) -> some View {
        let isSelected = selectedFormat == format
        
        return Button(action: { selectedFormat = format }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(format.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(format.badge)
                            .font(.caption2.bold())
                            .foregroundColor(format == .threeMF ? Color(red: 0.0, green: 0.85, blue: 0.35) : .gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    Text(format.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 0.0, green: 0.68, blue: 0.26).opacity(0.12) : Color(red: 0.12, green: 0.13, blue: 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(red: 0.0, green: 0.68, blue: 0.26) : Color.white.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
    }
    
    private func exportAndShare() {
        isExporting = true
        do {
            let url = try MeshExportManager.shared.exportFile(mesh: mesh, format: selectedFormat)
            self.exportedFileURL = url
            self.showShareSheet = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isExporting = false
    }
}
