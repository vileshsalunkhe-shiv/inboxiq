import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var emailViewModel = EmailListViewModel()

    @State private var isFilterSheetPresented = false
    @State private var showRecatDialog = false
    @State private var scrollToTopTrigger = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                EmailListView(
                    selectedCategory: emailViewModel.selectedCategory,
                    searchText: emailViewModel.searchText,
                    scrollToTopTrigger: $scrollToTopTrigger
                )
                .environment(\.managedObjectContext, viewContext)
            }
            .safeAreaInset(edge: .bottom) {
                categorizeButton
            }
            .navigationTitle("InboxIQ")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let selected = emailViewModel.selectedCategory {
                        CategoryBadge(
                            name: selected.name,
                            icon: selected.symbol,
                            color: selected.color
                        )
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isFilterSheetPresented = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    Button {
                        Task {
                            await emailViewModel.refresh(context: viewContext)
                        }
                    } label: {
                        Label("Sync", systemImage: "arrow.clockwise")
                    }
                    .disabled(emailViewModel.isLoading || emailViewModel.isCategorizing)
                }
            }
            .searchable(text: $emailViewModel.searchText)
            .refreshable {
                await emailViewModel.refresh(context: viewContext)
                showRecatDialog = true
            }
            .confirmationDialog(
                "Re-categorize emails?",
                isPresented: $showRecatDialog
            ) {
                Button("Categorize All Emails") {
                    Task {
                        await emailViewModel.categorizeAll(context: viewContext)
                    }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Use AI to re-apply categories to uncategorized emails.")
            }
            .sheet(isPresented: $isFilterSheetPresented) {
                CategoryFilterSheet(selectedCategory: $emailViewModel.selectedCategory) {
                    isFilterSheetPresented = false
                    scrollToTopTrigger = true
                }
                .presentationDetents([.medium, .large])
            }
            .overlay(alignment: .top) {
                if emailViewModel.showSuccessToast {
                    ToastView(text: "Categorization complete")
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .alert(item: $emailViewModel.error) { error in
                Alert(title: Text("Sync Error"), message: Text(error.localizedDescription))
            }
        }
    }

    private var categorizeButton: some View {
        Button {
            Task {
                await emailViewModel.categorizeAll(context: viewContext)
            }
        } label: {
            HStack(spacing: 8) {
                if emailViewModel.isCategorizing {
                    ProgressView()
                }
                Text(emailViewModel.isCategorizing ? "Categorizing..." : "Categorize All Emails")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.inboxBlue)
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
        .disabled(emailViewModel.isLoading || emailViewModel.isCategorizing)
        .accessibilityLabel("Categorize all emails")
    }
}

private struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 8)
            .accessibilityLabel(text)
    }
}
