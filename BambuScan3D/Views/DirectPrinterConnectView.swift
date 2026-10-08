import SwiftUI

/// Yerel Wi-Fi ağındaki Bambu Lab 3D yazıcıya (X1C, P1S, P1P, A1, A1 mini) doğrudan gönderme ekranı
public struct DirectPrinterConnectView: View {
    let mesh: ScannedMesh
    let format: ExportFormat
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var uploader = BambuDirectUploader()
    
    @AppStorage("bambu_ip") private var ipAddress: String = "192.168.1."
    @AppStorage("bambu_access_code") private var accessCode: String = ""
    @AppStorage("bambu_serial") private var serialNumber: String = ""
    @State private var selectedModel: BambuPrinterModel = .p1s
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Yazıcı Bilgileri").foregroundColor(.green)) {
                    Picker("Yazıcı Modeli", selection: $selectedModel) {
                        ForEach(BambuPrinterModel.allCases) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                    
                    HStack {
                        Text("IP Adresi")
                        Spacer()
                        TextField("Örn: 192.168.1.150", text: $ipAddress)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                    }
                    
                    HStack {
                        Text("Erişim Kodu")
                        Spacer()
                        SecureField("Yazıcı ekranındaki 8 haneli kod", text: $accessCode)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Nasıl Bulunur?")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. Bambu Lab yazıcınızın dokunmatik ekranına gidin.")
                        Text("2. Ayarlar (Çark Simgesi) > WLAN / Ağ menüsünü açın.")
                        Text("3. IP adresini ve Erişim Kodunu (Access Code) buraya girin.")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Section {
                    switch uploader.state {
                    case .idle:
                        Button(action: startDirectUpload) {
                            HStack {
                                Spacer()
                                Label("Doğrudan Yazıcıya Yükle", systemImage: "printer.dotmatrix.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(red: 0.0, green: 0.68, blue: 0.26))
                        
                    case .connecting:
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Yazıcıya bağlanılıyor...")
                                .font(.subheadline)
                        }
                        
                    case .uploading(let progress):
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Yükleniyor: %\(Int(progress * 100))")
                                .font(.subheadline.bold())
                            ProgressView(value: progress)
                                .accentColor(.green)
                        }
                        
                    case .success(let message):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Aktarım Başarılı!")
                                    .font(.headline)
                            }
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Button("Kapat") {
                                dismiss()
                            }
                            .padding(.top, 4)
                        }
                        
                    case .failure(let error):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Bağlantı Hatası")
                                    .font(.headline)
                            }
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Button("Tekrar Dene") {
                                uploader.reset()
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationTitle("Bambu LAN Aktarımı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
    
    private func startDirectUpload() {
        do {
            let fileURL = try MeshExportManager.shared.exportFile(mesh: mesh, format: format)
            let config = BambuPrinterConfig(
                ipAddress: ipAddress,
                accessCode: accessCode,
                serialNumber: serialNumber,
                printerModel: selectedModel
            )
            uploader.upload(fileURL: fileURL, config: config)
        } catch {
            uploader.state = .failure(error: error.localizedDescription)
        }
    }
}
