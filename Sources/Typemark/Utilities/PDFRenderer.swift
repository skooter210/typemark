import Foundation
#if canImport(WebKit)
import WebKit
#endif

public enum PDFRenderer {

    #if canImport(AppKit)
    // Retains the web view and delegate until PDF export completes
    @MainActor private static var activeExport: PDFExportHelper?

    @MainActor
    static func render(html: String, to url: URL) {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = false
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = false
        config.defaultWebpagePreferences = pagePrefs
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 1200), configuration: config)

        let helper = PDFExportHelper(webView: webView, outputURL: url)
        activeExport = helper
        webView.navigationDelegate = helper
        webView.loadHTMLString(html, baseURL: nil)
    }

    @MainActor
    private final class PDFExportHelper: NSObject, WKNavigationDelegate {
        let webView: WKWebView
        let outputURL: URL

        init(webView: WKWebView, outputURL: URL) {
            self.webView = webView
            self.outputURL = outputURL
        }

        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            MainActor.assumeIsolated {
                webView.createPDF { [weak self] result in
                    if case .success(let data) = result {
                        try? data.write(to: self?.outputURL ?? URL(fileURLWithPath: "/dev/null"))
                    }
                    // Release the retained references
                    PDFRenderer.activeExport = nil
                }
            }
        }

        nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            MainActor.assumeIsolated {
                PDFRenderer.activeExport = nil
            }
        }
    }
    #else
    static func render(html: String, to url: URL) {
        // PDF export not available on this platform
    }
    #endif
}
