import Foundation
import SwiftUI
import CoreData

@MainActor
final class CalendarAuthViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var authURL: URL?
    @Published var connectedEmail: String?

    private var pendingState: String?

    func checkStatus(context: NSManagedObjectContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = UserEntity.fetchOrCreateCurrent(context: context)
            let status = try await CalendarService.shared.checkStatus(userId: user.id)
            isConnected = status.connected
            connectedEmail = status.email
            user.calendarConnected = status.connected
            try context.save()
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to check calendar status")
        }
    }

    func startAuth(context: NSManagedObjectContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = UserEntity.fetchOrCreateCurrent(context: context)
            let response = try await CalendarService.shared.initiateAuth(userId: user.id)
            pendingState = response.state
            authURL = URL(string: response.authorizationURL)
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to start calendar OAuth")
        }
    }

    func handleOAuthCallback(url: URL, context: NSManagedObjectContext) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            error = AppError.auth("Invalid callback URL")
            return
        }

        if let errorParam = components.queryItems?.first(where: { $0.name == "error" })?.value {
            error = AppError.auth("OAuth error: \(errorParam)")
            return
        }

        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value else {
            error = AppError.auth("Missing code/state in callback")
            return
        }

        if let pendingState, pendingState != state {
            error = AppError.auth("Invalid OAuth state")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await CalendarService.shared.handleCallback(code: code, state: state)
            await checkStatus(context: context)
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to complete calendar OAuth")
        }
    }
}
