# BambuScan 3D 📱✨🖨️
### iPhone 14 Pro Max LiDAR ile Ev Eşyalarını 3D Tarama ve Bambu Lab'a Gönderme Uygulaması (iOS / Swift)

**BambuScan 3D**, iPhone 14 Pro Max'in dTOF LiDAR sensörünü ve yüksek çözünürlüklü kamera sistemini kullanarak evinizdeki fiziksel nesneleri milimetrik hassasiyetle 3 boyutlu tarayan, modeli otomatik olarak 3D baskı tablasına (Z=0) hizalayan ve tek dokunuşla **Bambu Handy** veya **Bambu Studio** uygulamasına aktaran yerel bir iOS (SwiftUI) uygulamasıdır.

---

## 🚀 Öne Çıkan Özellikler

1. **iPhone 14 Pro Max LiDAR ve ARKit Mesh Motoru (`LidarScannerEngine`)**:
   - `ARWorldTrackingConfiguration.sceneReconstruction = .meshWithClassification` ile gerçek zamanlı poligon yakalama.
   - Pürüzsüzleştirilmiş derinlik akışı (`smoothedSceneDepth`).
   - Saniyede milyonlarca derinlik noktası ile anlık 3D tel çerçeve (wireframe) oluşturma.

2. **Akıllı Tarama Kafesi (3D Bounding Cage)**:
   - Sıradan 3D tarayıcıların aksine masayı, zemini veya odadaki diğer eşyaları değil; **yalnızca taranmak istenen nesneyi** hedefler.
   - Genişlik, Yükseklik ve Derinlik (cm) gerçek zamanlı slider'lar ile ayarlanabilir.
   - Ekranda taranacak eşyaya dokunarak kafesi nesnenin üzerine kitleme (Raycast).

3. **3D Baskı Optimizasyonu ve Tabana Kilitleme (`PrintingPrepUtils` & `MeshOptimizer`)**:
   - **Metre -> Milimetre Dönüşümü**: ARKit koordinatlarını standart 3D dilimleyici ölçeğine (1:1 mm) çevirir.
   - **Z = 0 Otomatik Tabla Hizalama**: Taranan modelin en alt yüzeyini Bambu Lab baskı tablası zeminine kilitler, havada kalma veya tablaya batma sorunlarını önler.
   - **Taban Düzleştirme (Planar Bottom Cut)**: Bambu PEI tablasına kusursuz yapışması için zemin temas noktalarını düzleştirir.
   - **Çift Nokta Kaynağı (Vertex Welding)**: Gereksiz yüzeyleri ve dejenere poligonları eler.

4. **Bambu Lab Yerel Formatları ve Entegrasyonu**:
   - **.3MF (Bambu Lab Önerilen)**: Open Packaging Conventions uyumlu, XML tabanlı saf Swift 3MF oluşturucu (`ThreeMFExporter`). Bambu Studio ve Bambu Handy için en kusursuz formattır.
   - **.STL (İkili / Binary)**: 80 bayt başlık ve 50 bayt üçgen yapılı ultra hızlı ikili STL çıktısı.
   - **.OBJ**: CAD ve 3D modelleme programları için Wavefront formatı.

5. **Bambu Lab'a Gönderme Yöntemleri**:
   - **Bambu Handy ile Aç**: iOS Share Sheet ve URL Scheme (`bambu://`) ile tek tuşla model doğrudan telefondaki Bambu Handy uygulamasına aktarılır.
   - **AirDrop ile Bambu Studio**: Mac veya PC'deki Bambu Studio dilimleyicisine saniyeler içinde AirDrop.
   - **Wi-Fi LAN ile Doğrudan Yazıcıya Aktarım**: X1-Carbon, P1S, P1P, A1 veya A1 mini yazıcınızın IP ve Erişim Koduyla doğrudan MicroSD karta yükleme.

---

## 📂 Proje Dizin Yapısı

```
3dtarayici/
├── BambuScan3D.xcodeproj/       # Doğrudan Xcode ile açılabilen proje dosyası
├── project.yml                  # XcodeGen yapılandırma dosyası
├── BambuScan3D/
│   ├── App/
│   │   ├── BambuScan3DApp.swift      # Uygulama ana giriş noktası (@main)
│   │   └── Info.plist                # LiDAR, Kamera, Ağ izinleri ve 3MF/STL tanımları
│   ├── Models/
│   │   ├── ScannedMesh.swift         # 3D baskı geometri modeli (köşeler, normaller, üçgenler)
│   │   ├── ScanningBoundingBox.swift # 3D tarama kafesi ve uzamsal filtreleme
│   │   ├── ExportFormat.swift        # .3MF, .STL, .OBJ format tanımları
│   │   └── BambuPrinterConfig.swift  # Bambu Lab yazıcı modelleri ve tabla ölçüleri
│   ├── Scanning/
│   │   ├── LidarScannerEngine.swift  # ARKit LiDAR oturumu ve poligon yakalama
│   │   ├── ARScanningContainerView.swift # Canlı kamera ve tel çerçeve görünümü
│   │   └── BoundingBoxNode.swift     # Sahnedeki yeşil 3D kafes düğümü
│   ├── Processing/
│   │   ├── PrintingPrepUtils.swift   # ARKit -> 3D Baskı koordinat dönüşümü ve Z=0 hizalama
│   │   └── MeshOptimizer.swift       # Köşe birleştirme ve taban düzleştirme filtresi
│   ├── Exporters/
│   │   ├── ThreeMFExporter.swift     # Yerel 3MF paketleme motoru
│   │   ├── STLExporter.swift         # Binary ve ASCII STL dışa aktarıcı
│   │   ├── OBJExporter.swift         # Wavefront OBJ dışa aktarıcı
│   │   ├── ZipArchiveHelper.swift    # Sıfır harici kütüphane, saf Swift ZIP oluşturucu
│   │   └── MeshExportManager.swift   # Dosya depolama ve önbellek yönetimi
│   ├── BambuIntegration/
│   │   ├── BambuHandyConnector.swift # Bambu Handy entegrasyonu ve URL scheme
│   │   ├── BambuDirectUploader.swift # Wi-Fi LAN üzerinden yazıcıya aktarım servisi
│   │   └── ShareSheetPresenter.swift # iOS Paylaşım Sayfası (UIActivityViewController)
│   └── Views/
│       ├── MainDashboardView.swift   # Donanım durumu, rehber ve test modelleri
│       ├── ScanView.swift            # Canlı tarama ekranı
│       ├── ModelPreviewView.swift    # 3D SceneKit model inceleme ve tabla gridi
│       ├── ModelViewer3DContainer.swift # 256x256 mm Bambu tablası üzerinde 3D gösterim
│       ├── BambuExportModalView.swift# Format seçimi ve Bambu Handy'e gönderme
│       ├── DirectPrinterConnectView.swift # Wi-Fi ile yazıcıya doğrudan yükleme
│       └── Components/
│           ├── MeshStatsCard.swift   # Milimetrik boyutlar (X, Y, Z) ve tabla uyumluluğu
│           └── ScanningHUDOverlay.swift # Tarama sırasındaki HUD kontrolleri
└── README.md
```

---

## 🛠️ Kurulum ve iPhone 14 Pro Max'e Yükleme

### Gereksinimler
- macOS işletim sistemi (veya macOS sanal makine / MacinCloud)
- Xcode 15 veya üzeri
- iOS 16.0 veya üzeri yüklü **iPhone 14 Pro Max** (veya LiDAR sensörüne sahip herhangi bir Pro iPhone)
- Apple Kimliği (Ücretsiz kişisel geliştirici hesabı yeterlidir)

### Adım 1: Projeyi Xcode ile Açın
Proje kök dizinindeki `BambuScan3D.xcodeproj` dosyasını Xcode ile açın:
```bash
open BambuScan3D.xcodeproj
```
*(Alternatif olarak XcodeGen kullanıyorsanız terminalden `xcodegen generate` komutunu çalıştırabilirsiniz).*

### Adım 2: Geliştirici Sertifikanızı Seçin
1. Xcode sol menüsünden en üstteki **BambuScan3D** proje simgesine tıklayın.
2. **Signing & Capabilities** sekmesine gelin.
3. **Team** kısmından kendi Apple kimliğinizi seçin.
4. Gerekirse Bundle Identifier kısmını özelleştirin (Örn: `com.adiniz.BambuScan3D`).

### Adım 3: iPhone 14 Pro Max'e Yükleyin
1. iPhone 14 Pro Max cihazınızı Lightning/USB-C kablosu ile Mac'e bağlayın.
2. Xcode'un üst menüsünden hedef cihaz olarak bağlı iPhone'unuzu seçin.
3. **Çalıştır (Run / Cmd + R)** butonuna basın.
4. iPhone ekranında *"Güvenilmeyen Geliştirici"* uyarısı çıkarsa:
   - **Ayarlar > Genel > VPN ve Aygıt Yönetimi** yolunu izleyin.
   - Geliştirici hesabınıza tıklayıp **Güven** seçeneğini onaylayın.

---

## 🎯 Kullanım Rehberi (Adım Adım 3D Tarama)

### 1. Nesneyi Hazırlayın
- Taramak istediğiniz eşyayı (örneğin bir bardak, el aleti, oyuncak, vazo, plastik parça vb.) düz ve aydınlık bir masa üzerine koyun.

### 2. Taramayı Başlatın
- Uygulamayı açın ve **"Yeni Tarama Başlat"** butonuna dokunun.
- Ekranda Bambu Lab yeşili bir **3D Tarama Kafesi** belirecektir.
- Parmağınızla ekrandaki eşyaya dokunun; kafes otomatik olarak nesnenin üzerine taşınacaktır.
- Alt kısımdaki ayar simgesine basarak Genişlik, Yükseklik ve Derinlik boyutlarını nesnenize tam oturacak şekilde ayarlayın.

### 3. LiDAR ile Nesnenin Etrafında Dönün
- iPhone 14 Pro Max'i nesnenin etrafında 360 derece yavaşça gezdirin.
- LiDAR sensörü yüzeyleri anlık olarak yakalayacak ve poligon sayacı artacaktır.
- Nesnenin tüm açıları tamamlandığında yeşil **"Taramayı Bitir"** butonuna dokunun.

### 4. 3D Modeli İnceleyin
- Model otomatik olarak SceneKit motorunda **256x256 mm Bambu Lab PEI Tablası** üzerinde açılır.
- Parmağınızla modeli 360° döndürebilir, yakınlaştırabilir, tel çerçeve (wireframe) modunda poligon yapısını inceleyebilirsiniz.
- Kart üzerinde modelin **Genişlik (X)**, **Derinlik (Y)** ve **Yükseklik (Z)** değerlerini gerçek milimetre cinsinden görebilirsiniz.

### 5. Bambu Lab'a Gönderin!
- **"Bambu Lab'a Gönder"** butonuna dokunun:
  - **Bambu Handy ile Aç**: Model `.3mf` formatında derlenir ve telefonunuzdaki Bambu Handy uygulamasına aktarılır. Buradan doğrudan baskı başlatabilir veya profil seçebilirsiniz.
  - **AirDrop ile Bambu Studio**: Yanınızdaki Mac/PC'ye AirDrop ile göndererek Bambu Studio veya OrcaSlicer'da hemen dilimleyin.
  - **Doğrudan Yazıcıya Gönder (Wi-Fi)**: Bambu X1-Carbon, P1S, P1P veya A1 yazıcınızın yerel IP ve erişim kodunu girerek doğrudan yazıcının hafızasına gönderin.

---

## 🛡️ Gizlilik ve İzinler

- **Kamera İzni (`NSCameraUsageDescription`)**: Yalnızca yerel ortamda LiDAR nokta bulutu ve yüzey geometrisi oluşturmak için kullanılır. Görüntüler üçüncü şahıslara veya sunuculara aktarılmaz.
- **Yerel Ağ İzni (`NSLocalNetworkUsageDescription`)**: Sadece evinizdeki Wi-Fi ağı üzerinden Bambu Lab yazıcınıza dosya iletmek için kullanılır.

---

## 📄 Lisans
Bu proje MIT lisansı ile lisanslanmıştır. Bambu Lab yazıcı sahipleri ve 3D baskı meraklıları için geliştirilmiştir.
