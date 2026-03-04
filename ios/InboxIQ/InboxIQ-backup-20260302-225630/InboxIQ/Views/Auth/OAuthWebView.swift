import SwiftUI
import AuthenticationServices

struct OAuthWebView: UIViewControllerRepresentable {
    let authURL: URL
    let callbackScheme: String
    let onCallback: (Result<URL, Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Start authentication session
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            if let error = error {
                if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                    onCallback(.failure(NSError(domain: "OAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User canceled login"])))
                } else {
                    onCallback(.failure(error))
                }
            } else if let callbackURL = callbackURL {
                onCallback(.success(callbackURL))
            }
        }
        
        // Present as ephemeral session (doesn't save cookies)
        session.prefersEphemeralWebBrowserSession = false  // Use saved Google login if available
        session.presentationContextProvider = context.coordinator
        
        // Start the session
        DispatchQueue.main.async {
            session.start()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
