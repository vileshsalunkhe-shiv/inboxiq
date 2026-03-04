import SwiftUI
import UserNotifications
import CoreData

@main
struct InboxIQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let persistenceController = PersistenceController.shared

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var calendarAuthViewModel = CalendarAuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authViewModel)
                .environmentObject(calendarAuthViewModel)
                .onOpenURL { url in
                    if isCalendarCallback(url) {
                        Task {
                            await calendarAuthViewModel.handleOAuthCallback(url: url, context: persistenceController.container.viewContext)
                        }
                    } else {
                        Task {
                            await authViewModel.handleOAuthCallback(url: url)
                            // After successful login, check calendar status
                            if authViewModel.isAuthenticated {
                                await calendarAuthViewModel.checkStatus(context: persistenceController.container.viewContext)
                            }
                        }
                    }
                }
                .onAppear {
                    authViewModel.loadSession()
                    // Only check calendar if already authenticated
                    if authViewModel.isAuthenticated {
                        Task { await calendarAuthViewModel.checkStatus(context: persistenceController.container.viewContext) }
                    }
                }
        }
    }

    private func isCalendarCallback(_ url: URL) -> Bool {
        if url.host == "calendar" && url.path == "/callback" { return true }
        if url.path == Constants.calendarCallbackPath { return true }
        return url.absoluteString.contains("calendar/callback")
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
