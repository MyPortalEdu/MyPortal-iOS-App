import QuickLook
import SwiftUI
import UIKit

/// SwiftUI wrapper around `QLPreviewController` for previewing a single file
/// the app has downloaded to a local URL. Use via `.sheet(item:)`.
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {
        context.coordinator.url = url
        controller.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

/// Wraps a `URL` in an Identifiable shell so it can be passed to `sheet(item:)`.
struct PreviewableFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}
