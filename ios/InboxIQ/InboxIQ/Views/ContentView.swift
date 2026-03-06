import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var calendarAuthViewModel: CalendarAuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Inbox", systemImage: "tray")
                        }

                    Group {
                        if calendarAuthViewModel.isConnected {
                            CalendarListView()
                        } else {
                            CalendarConnectionView()
                        }
                    }
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    
                    DriveListView()
                        .tabItem {
                            Label("Drive", systemImage: "folder")
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
