import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var digestEnabled: Bool = true
    @State private var preferredTime: Date = DigestTimeFormatter.defaultPreferredTime
    @State private var lastSentAt: Date?
    @State private var isSending: Bool = false
    @State private var showSuccessToast: Bool = false
    @State private var showErrorToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isLoadingPreferences: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text(authViewModel.userEmail ?? "Signed In")
                    }
                }

                Section(header: digestHeader) {
                    if isLoadingPreferences {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        .padding(.vertical, AppSpacing.sm)
                    } else {
                        Toggle("Enable Daily Digest", isOn: $digestEnabled)
                            .onChange(of: digestEnabled) { _ in
                                persistPreferences()
                            }

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Preferred Time")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)

                            DatePicker("Preferred Time", selection: $preferredTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                                .disabled(!digestEnabled)
                                .onChange(of: preferredTime) { _ in
                                    persistPreferences()
                                }
                        }

                        PrimaryButton(
                            title: isSending ? "Sending..." : "Send Test Digest Now",
                            systemImage: "paperplane.fill",
                            isLoading: isSending
                        ) {
                            Task { await sendTestDigest() }
                        }
                        .disabled(isSending || !digestEnabled)

                        Text(lastSentLabel)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)

                        HStack(alignment: .top, spacing: AppSpacing.xs) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppColor.textSecondary)
                            Text("Receive a daily email summary of your inbox and calendar")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
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
            .overlay(alignment: .top) {
                if showSuccessToast {
                    ToastView(text: toastMessage, style: .success)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                } else if showErrorToast {
                    ToastView(text: toastMessage, style: .error)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 4) {
                    Text("InboxIQ")
                        .font(.headline)
                        .foregroundColor(AppColor.textPrimary)
                    Text("© 2026 VS Labs")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                    Text("Version 1.0")
                        .font(.caption2)
                        .foregroundColor(AppColor.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColor.backgroundPrimary)
            }
            .task {
                defer { isLoadingPreferences = false }
                await loadPreferences()
            }
        }
    }

    private var digestHeader: some View {
        HStack {
            Text("Daily Digest")
            Spacer()
            Image(systemName: "envelope.fill")
                .foregroundStyle(AppColor.secondary)
        }
    }

    private var lastSentLabel: String {
        if let lastSentAt {
            return "Last sent: \(lastSentFormatter.string(from: lastSentAt))"
        }
        return "Last sent: Never sent"
    }

    private var lastSentFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func loadPreferences() async {
        if let cached = loadPreferencesFromDefaults() {
            applyPreferences(cached)
        }

        do {
            let prefs = try await DigestService.shared.getPreferences()
            applyPreferences(prefs)
            savePreferencesToDefaults(prefs)
        } catch {
            // Keep cached values if available
        }
    }

    private func persistPreferences() {
        let prefs = DigestPreferences(
            enabled: digestEnabled,
            preferredTime: preferredTime,
            lastSentAt: lastSentAt
        )
        savePreferencesToDefaults(prefs)

        Task {
            do {
                try await DigestService.shared.updatePreferences(prefs)
            } catch {
                showToast(message: "Unable to update digest settings", style: .error)
            }
        }
    }

    private func sendTestDigest() async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }

        do {
            let result = try await DigestService.shared.sendDigest()
            lastSentAt = result.sentAt
            savePreferencesToDefaults(
                DigestPreferences(
                    enabled: digestEnabled,
                    preferredTime: preferredTime,
                    lastSentAt: lastSentAt
                )
            )
            showToast(message: "Digest sent to your email!", style: .success)
        } catch let error as AppError {
            handleDigestError(error)
        } catch {
            showToast(message: "Check your internet connection", style: .error)
        }
    }

    private func handleDigestError(_ error: AppError) {
        switch error {
        case .auth:
            showToast(message: "Please log in again", style: .error)
            Task { await authViewModel.logout() }
        case .network(let message):
            if message.contains("HTTP 429") {
                showToast(message: "Try again in a few minutes", style: .error)
            } else if message.contains("HTTP 500") {
                showToast(message: "Something went wrong", style: .error)
            } else if message.contains("HTTP 401") {
                showToast(message: "Please log in again", style: .error)
                Task { await authViewModel.logout() }
            } else {
                showToast(message: "Failed to send digest. Try again.", style: .error)
            }
        default:
            showToast(message: "Something went wrong", style: .error)
        }
    }

    private func showToast(message: String, style: ToastStyle) {
        toastMessage = message
        showSuccessToast = style == .success
        showErrorToast = style == .error

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessToast = false
            showErrorToast = false
        }
    }

    private func applyPreferences(_ prefs: DigestPreferences) {
        digestEnabled = prefs.enabled
        preferredTime = prefs.preferredTime
        lastSentAt = prefs.lastSentAt
    }

    private func savePreferencesToDefaults(_ prefs: DigestPreferences) {
        UserDefaults.standard.set(prefs.enabled, forKey: DigestDefaultsKeys.enabled)
        UserDefaults.standard.set(
            DigestTimeFormatter.timeString(from: prefs.preferredTime),
            forKey: DigestDefaultsKeys.preferredTime
        )
        UserDefaults.standard.set(prefs.lastSentAt, forKey: DigestDefaultsKeys.lastSentAt)
    }

    private func loadPreferencesFromDefaults() -> DigestPreferences? {
        let enabled = UserDefaults.standard.object(forKey: DigestDefaultsKeys.enabled) as? Bool ?? true
        let preferredTimeString = UserDefaults.standard.string(forKey: DigestDefaultsKeys.preferredTime)
        let preferred = preferredTimeString.flatMap { DigestTimeFormatter.timeOnlyDate(from: $0) }
            ?? DigestTimeFormatter.defaultPreferredTime
        let lastSent = UserDefaults.standard.object(forKey: DigestDefaultsKeys.lastSentAt) as? Date

        return DigestPreferences(enabled: enabled, preferredTime: preferred, lastSentAt: lastSent)
    }
}

private enum DigestDefaultsKeys {
    static let enabled = "digest_enabled"
    static let preferredTime = "digest_preferred_time"
    static let lastSentAt = "digest_last_sent_at"
}
