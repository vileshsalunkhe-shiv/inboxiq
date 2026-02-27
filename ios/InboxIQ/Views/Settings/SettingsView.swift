import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var digestFrequency: Int = 12

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text(authViewModel.userEmail ?? "Signed In")
                    }
                }

                Section(header: Text("Daily Digest")) {
                    Stepper("Every \(digestFrequency) hours", value: $digestFrequency, in: 6...24, step: 6)
                    Toggle("Include action items", isOn: .constant(true))
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authViewModel.logout() }
                    } label: {
                        Text("Logout")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
