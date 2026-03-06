import SwiftUI
import CoreData
import UIKit

struct EmailDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var error: AppError?
    @State private var lastFailedOperation: (() async -> Void)?
    @State private var selectedCategoryName: String
    @State private var showReplySheet = false
    @State private var showForwardSheet = false
    @State private var showDeleteConfirmation = false
    @State private var toast: ToastData?
    @State private var isPerformingAction = false
    @State private var isSavingToDrive = false
    @State private var savingAttachmentIndex: Int?

    @State private var fullBody: EmailBody?
    @State private var isLoadingBody = false
    @State private var bodyLoadError: String?
    @State private var webViewHeight: CGFloat = 200

    private let bodyService = EmailBodyService()

    let email: EmailEntity

    init(email: EmailEntity) {
        self.email = email
        _selectedCategoryName = State(initialValue: email.category?.name ?? "None")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(email.subject)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(email.sender)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                        Text(email.receivedAt.formattedDate())
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer()
                    if email.isStarred {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppColor.accent)
                    }
                }

                if let category = email.category {
                    CategoryBadge(
                        name: category.name,
                        icon: CategoryColors.symbol(for: category.name),
                        color: Color.fromHex(CategoryColors.colorHex(for: category.name)),
                        isLarge: true
                    )
                }

                Picker("Category", selection: $selectedCategoryName) {
                    Text("None").tag("None")
                    ForEach(CategoryColors.all) { category in
                        Text(category.name).tag(category.name)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Change category")
                .onChange(of: selectedCategoryName) { newValue in
                    updateCategory(name: newValue)
                }

                if let summary = email.aiSummary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Summary")
                            .font(.headline)
                        Text(summary)
                            .foregroundStyle(.primary)
                    }
                }

                if confidenceValue > 0.8 {
                    Text("AI Confidence: \(Int(confidenceValue * 100))%")
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Divider()

                Text(email.snippet)
                    .font(.body)
                    .foregroundStyle(.primary)

                if fullBody == nil {
                    loadFullEmailButton
                    
                    if let bodyLoadError {
                        Text(bodyLoadError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let fullBody {
                    fullBodyContentView(fullBody)
                }

                HStack(spacing: 16) {
                    Button {
                        Task { await archiveEmail() }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    Task { await toggleReadStatus() }
                } label: {
                    Image(systemName: email.isUnread ? "envelope.open" : "envelope.badge")
                }
                .disabled(isPerformingAction)
            }

            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showReplySheet = true
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Spacer()

                Button {
                    showForwardSheet = true
                } label: {
                    Label("Forward", systemImage: "arrowshape.turn.up.right")
                }
            }
        }
        .sheet(isPresented: $showReplySheet) {
            ReplyEmailView(email: email)
        }
        .sheet(isPresented: $showForwardSheet) {
            ForwardEmailView(email: email)
        }
        .alert("Action Failed", isPresented: Binding(
            get: { error != nil },
            set: { isPresented in if !isPresented { error = nil } }
        )) {
            Button("Retry") {
                Task {
                    await retryLastOperation()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
        .alert(EmailActionConfirmation.deleteTitle, isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await deleteEmail() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(EmailActionConfirmation.deleteMessage)
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(text: toast.message, style: toast.style)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
    }

    private var confidenceValue: Double {
        email.confidenceScore ?? 0
    }
    
    private var loadFullEmailButton: some View {
        Group {
            if isLoadingBody {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                }
                .frame(maxWidth: .infinity)
            } else {
                Button {
                    Task { await loadFullBody() }
                } label: {
                    Label("Load Full Email", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func fullBodyContentView(_ body: EmailBody) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            if let html = body.htmlBody, !html.isEmpty {
                EmailBodyWebView(html: html, contentHeight: $webViewHeight)
                    .frame(minHeight: 200, maxHeight: webViewHeight)
            } else if let text = body.textBody, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
            } else {
                Text("No additional body content available.")
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            if !body.attachments.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Attachments")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    ForEach(body.attachments) { attachment in
                        SecondaryButton(
                            title: attachment.filename,
                            systemImage: attachmentIcon(for: attachment.mimeType),
                            action: {
                                Task {
                                    await saveToDrive(attachmentIndex: attachment.index)
                                }
                            }
                        )
                        .disabled(isSavingToDrive)
                    }
                }
            }
        }
    }

    private func attachmentIcon(for mimeType: String) -> String {
        if mimeType.starts(with: "image/") {
            return "photo"
        } else if mimeType == "application/pdf" {
            return "doc.text"
        } else if mimeType.contains("word") {
            return "doc"
        } else if mimeType.contains("excel") || mimeType.contains("spreadsheet") {
            return "tablecells"
        } else {
            return "paperclip"
        }
    }

    private func driveButtonTitle(for index: Int) -> String {
        if isSavingToDrive && savingAttachmentIndex == index {
            return "Saving..."
        }
        return "Save to Drive"
    }

    private func saveToDrive(attachmentIndex: Int) async {
        guard !isSavingToDrive else { return }
        isSavingToDrive = true
        savingAttachmentIndex = attachmentIndex
        defer {
            isSavingToDrive = false
            savingAttachmentIndex = nil
        }

        do {
            let driveFile = try await DriveService.shared.uploadAttachment(
                emailId: email.gmailId,
                attachmentIndex: attachmentIndex
            )
            showToast("Saved to Drive: \(driveFile.name)", style: .success)
        } catch let error as AppError {
            handleError(error)
        } catch {
            showToast("Failed to save to Drive", style: .error)
        }
    }

    private func loadFullBody() async {
        guard !isLoadingBody else { return }
        isLoadingBody = true
        bodyLoadError = nil

        defer { isLoadingBody = false }

        do {
            fullBody = try await bodyService.fetchEmailBody(gmailId: email.gmailId)
        } catch let error as AppError {
            // Handle specific error types
            switch error {
            case .network(let message) where message.contains("404"):
                bodyLoadError = "Email not synced yet. Try pulling to refresh the inbox."
            case .auth:
                bodyLoadError = "Authentication expired. Please log in again."
            default:
                bodyLoadError = "Failed to load: \(error.localizedDescription)"
            }
        } catch {
            bodyLoadError = "Failed to load email body. Tap to retry."
        }
    }

    private func updateCategory(name: String) {
        if name == "None" {
            email.category = nil
        } else {
            let category = CategoryEntity.fetchOrCreate(name: name, context: viewContext)
            email.category = category
        }

        do {
            try viewContext.save()
        } catch {
            lastFailedOperation = { @MainActor in
                self.updateCategory(name: name)
            }
            self.error = AppError.coreData("Failed to update category")
        }
    }

    private func archiveEmail() async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            try await EmailActionService.shared.archiveEmail(email: email)
            email.isArchived = true
            triggerHaptic()
            showToast("Email archived", style: .success)
            dismiss()
        } catch let error as AppError {
            handleError(error)
        } catch {
            handleError(AppError.unknown(error.localizedDescription))
        }
    }

    private func deleteEmail() async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        
        // For now, just delete locally (backend delete has sync issues)
        // TODO: Re-enable backend delete after fixing sync rate limiting
        await MainActor.run {
            viewContext.delete(email)
            do {
                try viewContext.save()
                triggerHaptic()
                showToast("Email deleted", style: .success)
                isPerformingAction = false
                dismiss()
            } catch {
                isPerformingAction = false
                handleError(AppError.coreData("Failed to delete email"))
            }
        }
    }

    private func toggleReadStatus() async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        let shouldMarkRead = email.isUnread
        
        // Update on main thread and ensure CoreData propagates changes
        await MainActor.run {
            email.isUnread.toggle()
            viewContext.processPendingChanges()
        }

        do {
            // Save CoreData changes
            try await MainActor.run {
                try viewContext.save()
                
                // Force refresh to ensure parent views see the change
                viewContext.refresh(email, mergeChanges: false)
            }
            
            // Update backend
            try await EmailActionService.shared.updateReadStatus(email: email, read: shouldMarkRead)
            
            await MainActor.run {
                triggerHaptic()
                showToast(shouldMarkRead ? "Marked as read" : "Marked as unread", style: .success)
                isPerformingAction = false
            }
        } catch let error as AppError {
            await MainActor.run {
                email.isUnread.toggle()
                try? viewContext.save()
                isPerformingAction = false
                handleError(error)
            }
        } catch {
            await MainActor.run {
                email.isUnread.toggle()
                try? viewContext.save()
                isPerformingAction = false
                handleError(AppError.unknown(error.localizedDescription))
            }
        }
    }

    private func handleError(_ error: AppError) {
        if case .auth = error {
            Task { await authViewModel.logout() }
        }
        showToast(error.localizedDescription, style: .error)
    }

    private func showToast(_ message: String, style: ToastStyle) {
        toast = ToastData(message: message, style: style)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if toast?.message == message {
                toast = nil
            }
        }
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func retryLastOperation() async {
        if let operation = lastFailedOperation {
            await operation()
        }
    }
}
