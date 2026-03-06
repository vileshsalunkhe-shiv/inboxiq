import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
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
    }
}
