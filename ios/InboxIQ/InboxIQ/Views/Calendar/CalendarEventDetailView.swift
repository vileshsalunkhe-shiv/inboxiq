import SwiftUI
import CoreData

struct CalendarEventDetailView: View {
    let event: CalendarEventEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.summary)
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 6) {
                    Label(event.startDate.formattedDate(), systemImage: "clock")
                    Label(event.endDate.formattedDate(), systemImage: "clock.badge.checkmark")
                }
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                }

                if let description = event.eventDescription, !description.isEmpty {
                    Divider()
                    Text(description)
                        .font(.body)
                }

                if let link = event.htmlLink, let url = URL(string: link) {
                    Link("Open in Google Calendar", destination: url)
                        .font(.headline)
                }
            }
            .padding()
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
    }
}
