import SwiftUI

struct ReplyEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    let email: EmailEntity

    @State private var bodyText = ""
    @State private var replyAll = false
    @State private var isSending = false
    @State private var showDiscardConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var toast: ToastData?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    LabeledReadOnlyField(title: "To", value: replyToAddress)
                    LabeledReadOnlyField(title: "Subject", value: replySubject)
                }

                Picker("Reply", selection: $replyAll) {
                    Text("Reply").tag(false)
                    Text("Reply All").tag(true)
                }
                .pickerStyle(.segmented)

                TextEditor(text: $bodyText)
                    .frame(minHeight: 180)
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                    .accessibilityLabel("Reply body")

                quoteView

                Spacer()
            }
            .appPadding()
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { handleCancel() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await sendReply() }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Send")
                        }
                    }
                    .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
            }
            .alert(EmailActionConfirmation.discardTitle, isPresented: $showDiscardConfirmation) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(EmailActionConfirmation.discardMessage)
            }
            .alert("Send Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(text: toast.message, style: toast.style)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
        }
    }

    private var replyToAddress: String {
        email.sender.firstEmailAddress()
    }

    private var replySubject: String {
        let subject = email.subject
        if subject.lowercased().hasPrefix("re:") {
            return subject
        }
        return "Re: \(subject)"
    }

    private var quoteView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("On \(email.receivedAt.formattedDate()), \(email.sender) wrote:")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text("> \(email.snippet)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd))
    }

    private var hasDraftContent: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleCancel() {
        if hasDraftContent {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func sendReply() async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }

        do {
            try await EmailActionService.shared.replyEmail(
                email: email,
                body: bodyText,
                replyAll: replyAll
            )
            toast = ToastData(message: "Reply sent", style: .success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } catch let error as AppError {
            handleError(error)
        } catch {
            handleError(AppError.unknown(error.localizedDescription))
        }
    }

    private func handleError(_ error: AppError) {
        if case .auth = error {
            Task { await authViewModel.logout() }
        }
        errorMessage = error.localizedDescription
        showErrorAlert = true
    }
}

private struct LabeledReadOnlyField: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(AppColor.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
        }
    }
}
