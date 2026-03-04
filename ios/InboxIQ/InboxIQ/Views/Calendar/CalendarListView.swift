import SwiftUI
import CoreData

struct CalendarListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = CalendarListViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CalendarEventEntity.startDate, ascending: true)]
    ) private var events: FetchedResults<CalendarEventEntity>

    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No upcoming events")
                            .font(.headline)
                        Text("Pull down to refresh or create a new event.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(events, id: \.self) { event in
                            NavigationLink {
                                CalendarEventDetailView(event: event)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(event.summary)
                                        .font(.headline)
                                    Text(event.startDate.formattedDate())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refresh(context: viewContext) }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.refresh(context: viewContext)
            }
            .sheet(isPresented: $showCreate) {
                CreateEventView { summary, startDate, endDate, description, location, attendees in
                    Task {
                        await viewModel.createEvent(
                            context: viewContext,
                            summary: summary,
                            startDate: startDate,
                            endDate: endDate,
                            description: description,
                            location: location,
                            attendees: attendees
                        )
                        showCreate = false
                    }
                }
            }
            .alert(item: $viewModel.error) { error in
                Alert(title: Text("Calendar Error"), message: Text(error.localizedDescription))
            }
        }
        .onAppear {
            if events.isEmpty {
                Task { await viewModel.refresh(context: viewContext) }
            }
        }
    }
}
