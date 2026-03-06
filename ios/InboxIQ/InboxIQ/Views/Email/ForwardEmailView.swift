import SwiftUI
import UniformTypeIdentifiers

struct ForwardEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    let email: EmailEntity

    @State private var toRecipients = ""
    @State private var bodyText = ""
    @State private var attachments: [EmailAttachmentPayload] = []
    @State private var isSending = false
    @State private var showDiscardConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var toast: ToastData?
    @State private var showAttachmentPicker = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    LabeledField(title: "To", text: $toRecipients, placeholder: "email@example.com")
                    LabeledReadOnlyField(title: "Subject", value: forwardSubject)
                }

                TextEditor(text: $bodyText)
                    .frame(minHeight: 180)
                    .padding(AppSpacing.sm)
                    .background(AppColor.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd)
                            .stroke(AppColor.border, lineWidth: 1)
                    )
                    .accessibilityLabel("Forward body")

                forwardedBlock

                attachmentSection

                Spacer()
            }
            .appPadding()
            .navigationTitle("Forward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { handleCancel() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await sendForward() }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Send")
                        }
                    }
                    .disabled(!toRecipients.isValidEmailList() || isSending)
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
            .fileImporter(
                isPresented: $showAttachmentPicker,
                allowedContentTypes: [.data, .content],
                allowsMultipleSelection: true
            ) { result in
                handleAttachmentSelection(result)
            }
        }
    }

    private var forwardSubject: String {
        let subject = email.subject
        if subject.lowercased().hasPrefix("fwd:") {
            return subject
        }
        return "Fwd: \(subject)"
    }

    private var forwardedBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("---------- Forwarded message ----------")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text("From: \(email.sender)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text("Date: \(email.receivedAt.formattedDate())")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text("Subject: \(email.subject)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            Text(email.snippet)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd))
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Attachments")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Button {
                    showAttachmentPicker = true
                } label: {
                    Label("Add", systemImage: "paperclip")
                }
            }

            if attachments.isEmpty {
                Text("No attachments")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textTertiary)
            } else {
                ForEach(attachments, id: \.self) { attachment in
                    HStack {
                        Image(systemName: "doc")
                        Text(attachment.filename)
                            .font(AppTypography.caption)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var hasDraftContent: Bool {
        !toRecipients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !attachments.isEmpty
    }

    private func handleCancel() {
        if hasDraftContent {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func sendForward() async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }

        do {
            try await EmailActionService.shared.forwardEmail(
                email: email,
                to: toRecipients.emailAddresses,
                body: bodyText,
                attachments: attachments
            )
            toast = ToastData(message: "Email forwarded", style: .success)
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

    private func handleAttachmentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            showErrorAlert = true
        case .success(let urls):
            for url in urls {
                guard let data = try? Data(contentsOf: url) else { continue }
                let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                let attachment = EmailAttachmentPayload(
                    filename: url.lastPathComponent,
                    contentType: mimeType,
                    data: data.base64EncodedString()
                )
                attachments.append(attachment)
            }
        }
    }
}

private struct LabeledField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .keyboardType(title == "To" ? .emailAddress : .default)
                .textFieldStyle(.roundedBorder)
        }
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
