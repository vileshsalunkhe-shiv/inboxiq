import SwiftUI
import CoreData

struct CalendarConnectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var calendarAuthViewModel: CalendarAuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.inboxBlue)
                .accessibilityHidden(true)

            Text("Connect Google Calendar")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Link your calendar to see upcoming events and create new ones.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                Task { await calendarAuthViewModel.startAuth(context: viewContext) }
            } label: {
                HStack {
                    Image(systemName: "link")
                    Text("Connect Calendar")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.inboxBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(calendarAuthViewModel.isLoading)

            if calendarAuthViewModel.isLoading {
                ProgressView()
            }

            Spacer()
        }
        .padding()
        .onAppear {
            Task { await calendarAuthViewModel.checkStatus(context: viewContext) }
        }
        .sheet(isPresented: Binding(
            get: { calendarAuthViewModel.authURL != nil },
            set: { if !$0 { calendarAuthViewModel.authURL = nil } }
        )) {
            if let url = calendarAuthViewModel.authURL {
                OAuthWebView(authURL: url, callbackScheme: Constants.calendarCallbackScheme) { result in
                    calendarAuthViewModel.authURL = nil
                    switch result {
                    case .success(let callbackURL):
                        Task { await calendarAuthViewModel.handleOAuthCallback(url: callbackURL, context: viewContext) }
                    case .failure:
                        calendarAuthViewModel.error = AppError.auth("Calendar OAuth canceled")
                    }
                }
            }
        }
        .alert(item: $calendarAuthViewModel.error) { error in
            Alert(title: Text("Calendar Error"), message: Text(error.localizedDescription))
        }
    }
}
