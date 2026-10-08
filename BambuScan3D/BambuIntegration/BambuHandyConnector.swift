import UIKit
import UniformTypeIdentifiers

/// Bambu Handy uygulaması ile entegrasyonu sağlayan bağlayıcı
public final class BambuHandyConnector {
    public static let shared = BambuHandyConnector()
    
    // Bambu Handy App Store URL
    public static let appStoreURL = URL(string: "https://apps.apple.com/app/bambu-handy/id1632760572")!
    
    // Bambu Handy URL Scheme
    public static let bambuSchemeURL = URL(string: "bambu://")!
    
    private init() {}
    
    /// Cihazda Bambu Handy uygulamasının yüklü olup olmadığını kontrol eder
    public func isBambuHandyInstalled() -> Bool {
        return UIApplication.shared.canOpenURL(Self.bambuSchemeURL)
    }
    
    /// Bambu Handy uygulamasını doğrudan açar
    public func openBambuHandy() {
        if isBambuHandyInstalled() {
            UIApplication.shared.open(Self.bambuSchemeURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(Self.appStoreURL, options: [:], completionHandler: nil)
        }
    }
}
