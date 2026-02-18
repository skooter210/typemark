import Foundation
#if canImport(WebKit)
import WebKit
#endif

enum PDFRenderer {

    #if canImport(AppKit)
    @MainActor
    static func render(html: String, to url: URL) {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 1200))
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
