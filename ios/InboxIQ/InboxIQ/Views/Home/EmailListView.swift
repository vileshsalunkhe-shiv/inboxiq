import SwiftUI
import CoreData
import Combine
import UIKit

struct EmailListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authViewModel: AuthViewModel
    @FetchRequest private var emails: FetchedResults<EmailEntity>

    @State private var toast: ToastData?
    @State private var pendingDeleteEmail: EmailEntity?
    @State private var loadingEmailIds: Set<UUID> = []

    let selectedCategory: CategoryDefinition?
    let searchText: String
    let isLoading: Bool
    @Binding var scrollToTopTrigger: Bool

    init(
        selectedCategory: CategoryDefinition?,
        searchText: String,
        isLoading: Bool,
        scrollToTopTrigger: Binding<Bool>
    ) {
        self.selectedCategory = selectedCategory
        self.searchText = searchText
        self.isLoading = isLoading
        self._scrollToTopTrigger = scrollToTopTrigger
        _emails = FetchRequest(
            fetchRequest: EmailListViewModel.makeFetchRequest(
                selectedCategory: selectedCategory,
                searchText: searchText
            ),
            animation: .default
        )
    }

    private var filteredEmails: [EmailEntity] {
        let filtered = Array(emails).filter { !$0.isArchived }
        print("📊 Total emails from FetchRequest: \(emails.count)")
        print("📊 After filter (!isArchived): \(filtered.count)")
        
        // Debug: Print first 10 email subjects with dates
        for (i, email) in filtered.prefix(10).enumerated() {
            print("  \(i). [\(email.receivedAt)] \(email.subject ?? "No subject")")
        }
        
        return filtered
    }

    private var groupedEmails: [(String, [EmailEntity])] {
        // Group by date string but SORT by actual date, not string!
        let grouped = Dictionary(grouping: filteredEmails) { email in
            email.receivedAt.formattedDate(style: .medium)
        }
        
        // Sort by the ACTUAL dates of emails in each group, not the string key
        let sorted = grouped.sorted { group1, group2 in
            let date1 = group1.value.first?.receivedAt ?? Date.distantPast
            let date2 = group2.value.first?.receivedAt ?? Date.distantPast
            return date1 > date2  // Newest first
        }
        
        print("📊 Grouped into \(sorted.count) sections:")
        for (section, items) in sorted.prefix(5) {
            let firstDate = items.first?.receivedAt ?? Date()
            print("  Section '\(section)' [actual date: \(firstDate)]: \(items.count) emails")
        }
        
        return sorted
    }

    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if isLoading && filteredEmails.isEmpty {
                    skeletonList
                        .transition(.opacity)
                } else if filteredEmails.isEmpty {
                    emptyStateView
                        .transition(.opacity)
                } else {
                    List {
                        // Debug header to show we're at the top
                        Section {
                            Text("📬 Inbox (\(filteredEmails.count) emails)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(groupedEmails, id: \.0) { section, items in
                            Section(section) {
                                ForEach(items, id: \.self) { email in
                                    NavigationLink {
                                        EmailDetailView(email: email)
                                    } label: {
                                        EmailRowView(
                                            email: email,
                                            isStarred: email.isStarred,
                                            isLoading: loadingEmailIds.contains(email.id)
                                        )
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            pendingDeleteEmail = email
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            Task { await archiveEmail(email) }
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(AppColor.secondary)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            Task { await toggleStar(email) }
                                        } label: {
                                            Label(email.isStarred ? "Unstar" : "Star", systemImage: email.isStarred ? "star.slash" : "star")
                                        }
                                        .tint(AppColor.accent)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollIndicators(.visible) // Show scrollbars
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            .onChange(of: selectedCategory?.name) { _ in
                // DISABLED - was trying to scroll to removed "top" id
                // withAnimation(.easeInOut) {
                //     proxy.scrollTo("top", anchor: .top)
                // }
            }
            .onChange(of: scrollToTopTrigger) { shouldScroll in
                guard shouldScroll else { return }
                print("🔝 Scroll to top triggered - disabled for debugging")
                // TEMPORARILY DISABLED - was hiding first emails
                // withAnimation(.easeInOut) {
                //     proxy.scrollTo("top", anchor: .top)
                // }
                DispatchQueue.main.async {
                    scrollToTopTrigger = false
                }
            }
        }
        .alert(EmailActionConfirmation.deleteTitle, isPresented: Binding(
            get: { pendingDeleteEmail != nil },
            set: { isPresented in if !isPresented { pendingDeleteEmail = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let email = pendingDeleteEmail {
                    Task { await deleteEmail(email) }
                }
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

    private var emptyStateView: some View {
        EmptyStateView(
            title: emptyTitle,
            message: emptySubtitle,
            systemImage: "tray"
        )
    }

    private var emptyTitle: String {
        if let selectedCategory {
            return "No \(selectedCategory.name) emails"
        }
        return "No emails yet"
    }

    private var emptySubtitle: String {
        if let selectedCategory {
            return "Try a different filter or categorize your inbox."
        }
        return "Pull to refresh to sync your inbox"
    }

    private var skeletonList: some View {
        List {
            ForEach(0..<6, id: \.self) { _ in
                SkeletonEmailRow()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
            }
        }
        .listStyle(.insetGrouped)
        .redacted(reason: .placeholder)
    }

    private func archiveEmail(_ email: EmailEntity) async {
        guard !loadingEmailIds.contains(email.id) else { return }
        setLoading(true, for: email)
        defer { setLoading(false, for: email) }

        do {
            try await EmailActionService.shared.archiveEmail(email: email)
            email.isArchived = true
            triggerHaptic()
            showToast("Email archived", style: .success)
        } catch let error as AppError {
            handleError(error)
        } catch {
            handleError(AppError.unknown(error.localizedDescription))
        }
    }

    private func deleteEmail(_ email: EmailEntity) async {
        guard !loadingEmailIds.contains(email.id) else { return }
        setLoading(true, for: email)
        defer { setLoading(false, for: email) }

        do {
            try await EmailActionService.shared.deleteEmail(email: email)
            viewContext.delete(email)
            try viewContext.save()
            triggerHaptic()
            showToast("Email deleted", style: .success)
        } catch let error as AppError {
            handleError(error)
        } catch {
            handleError(AppError.unknown(error.localizedDescription))
        }
    }

    private func toggleStar(_ email: EmailEntity) async {
        guard !loadingEmailIds.contains(email.id) else { return }
        let newValue = !email.isStarred
        email.isStarred = newValue

        setLoading(true, for: email)
        defer { setLoading(false, for: email) }

        do {
            try await EmailActionService.shared.updateStar(email: email, starred: newValue)
            triggerHaptic()
            showToast(newValue ? "Starred" : "Unstarred", style: .success)
        } catch let error as AppError {
            email.isStarred.toggle()
            handleError(error)
        } catch {
            email.isStarred.toggle()
            handleError(AppError.unknown(error.localizedDescription))
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

    private func setLoading(_ isLoading: Bool, for email: EmailEntity) {
        if isLoading {
            loadingEmailIds.insert(email.id)
        } else {
            loadingEmailIds.remove(email.id)
        }
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

private struct SkeletonEmailRow: View {
    @State private var shimmerOffset: CGFloat = -120

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(height: 18)
                .overlay(shimmer)
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(height: 14)
                .overlay(shimmer)
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(width: 120, height: 12)
                .overlay(shimmer)
        }
        .padding(AppSpacing.sm)
        .background(AppColor.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMd))
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 220
            }
        }
    }

    private var shimmer: some View {
        LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.35), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .rotationEffect(.degrees(20))
        .offset(x: shimmerOffset)
        .blendMode(.screen)
        .clipped()
    }
}
