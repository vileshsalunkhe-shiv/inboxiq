import SwiftUI
import UserNotifications

@main
struct InboxIQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let persistenceController = PersistenceController.shared

    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    TabView {
                        HomeView()
                            .tabItem {
                                Label("Inbox", systemImage: "tray")
                            }

                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                    }
                } else {
                    LoginView()
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(authViewModel)
            .onOpenURL { url in
                Task { await authViewModel.handleOAuthCallback(url: url) }
            }
            .onAppear {
                authViewModel.loadSession()
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        application.setMinimumBackgroundFetchInterval(Constants.backgroundFetchInterval)
        registerForPushNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Logger.info("Received silent push: \(userInfo)")
        completionHandler(.newData)
    }

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Logger.info("Background fetch triggered")
        completionHandler(.newData)
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
