import Foundation
#if canImport(WebKit)
import WebKit
#endif

enum PDFRenderer {

    #if canImport(AppKit)
    @MainActor
    static func render(html: String, to url: URL) {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false
        // Disable JavaScript to prevent script execution during PDF rendering
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = false
        config.defaultWebpagePreferences = pagePrefs
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 1200), configuration: config)
        webView.loadHTMLString(html, baseURL: nil)

        // Wait for content to load, then create PDF
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            webView.createPDF { result in
                if case .success(let data) = result {
                    try? data.write(to: url)
                }
            }
        }
    }
    #else
    static func render(html: String, to url: URL) {
        // PDF export not available on this platform
    }
    #endif
}
