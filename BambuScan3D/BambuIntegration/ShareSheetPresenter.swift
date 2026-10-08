import SwiftUI
import UIKit

/// SwiftUI için yerel iOS Paylaşım Sayfası (UIActivityViewController)
public struct ShareSheet: UIViewControllerRepresentable {
    public let items: [Any]
    public let excludedActivityTypes: [UIActivity.ActivityType]?
    
    public init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
