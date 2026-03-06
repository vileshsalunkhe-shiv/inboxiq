import SwiftUI
import WebKit

struct EmailBodyWebView: UIViewRepresentable {
    let html: String
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html else { return }
        context.coordinator.lastHTML = html

        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    color: #000000;
                    margin: 0;
                    padding: 16px;
                    word-wrap: break-word;
                }
                img { max-width: 100%; height: auto; }
                a { color: #007AFF; }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFFFFF;
                        background-color: transparent;
                    }
                    a { color: #5AC8FA; }
                }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """

        webView.loadHTMLString(styledHTML, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: EmailBodyWebView
        var lastHTML: String?

        init(parent: EmailBodyWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let self = self, let height = result as? CGFloat else { return }
                DispatchQueue.main.async {
                    self.parent.contentHeight = height
                }
            }
        }
    }
}
