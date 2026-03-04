import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var emailViewModel = EmailListViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CategoryFilterView(selectedCategory: $emailViewModel.selectedCategory)
                EmailListView(selectedCategory: emailViewModel.selectedCategory, searchText: emailViewModel.searchText)
            }
            .navigationTitle("InboxIQ")
            .searchable(text: $emailViewModel.searchText)
            .refreshable {
                await emailViewModel.refresh(context: viewContext)
            }
            .alert(item: $emailViewModel.error) { error in
                Alert(title: Text("Sync Error"), message: Text(error.localizedDescription))
            }
        }
    }
}
