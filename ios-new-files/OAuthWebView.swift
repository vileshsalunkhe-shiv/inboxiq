import SwiftUI
import WebKit

struct OAuthWebView: UIViewRepresentable {
    let authURL: URL
    let callbackScheme: String
    let onCallback: (Result<URL, Error>) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: authURL)
        webView.load(request)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: OAuthWebView
        
        init(_ parent: OAuthWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.scheme == parent.callbackScheme {
                parent.onCallback(.success(url))
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onCallback(.failure(error))
        }
    }
}
