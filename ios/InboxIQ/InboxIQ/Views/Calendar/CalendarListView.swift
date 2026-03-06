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
                if viewModel.isLoading && events.isEmpty {
                    skeletonList
                        .transition(.opacity)
                } else if events.isEmpty {
                    EmptyStateView(
                        title: "No upcoming events",
                        message: "Your calendar is clear!",
                        systemImage: "calendar"
                    )
                    .transition(.opacity)
                } else {
                    List {
                        ForEach(events, id: \.self) { event in
                            NavigationLink {
                                CalendarEventDetailView(event: event)
                            } label: {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(event.summary)
                                        .font(.headline)
                                    Text(event.startDate.formattedDate())
                                        .font(.caption)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
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

    private var skeletonList: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonEventRow()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
            }
        }
        .listStyle(.insetGrouped)
        .redacted(reason: .placeholder)
    }
}

private struct SkeletonEventRow: View {
    @State private var shimmerOffset: CGFloat = -140

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(height: 18)
                .overlay(shimmer)
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                .fill(AppColor.backgroundSecondary)
                .frame(width: 140, height: 12)
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
