import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var summary: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(60 * 60)
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var attendees: String = ""

    let onCreate: (String, Date, Date, String?, String?, [String]?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $summary)
                    TextField("Location", text: $location)
                    TextField("Attendees (comma separated)", text: $attendees)
                }

                Section(header: Text("Time")) {
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let attendeeList = attendees
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        onCreate(summary, startDate, endDate, description, location, attendeeList)
                    }
                    .disabled(summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
