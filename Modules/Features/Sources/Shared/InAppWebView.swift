import SwiftUI

#if os(iOS)
import DesignSystem
import SafariServices

struct InAppWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(BrandPalette.green)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#elseif os(macOS)
import WebKit

struct InAppWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif

struct WebDestination: Identifiable, Equatable {
    let url: URL

    var id: String {
        url.absoluteString
    }
}
