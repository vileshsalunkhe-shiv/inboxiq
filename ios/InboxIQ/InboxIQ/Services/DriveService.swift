import Foundation

final class DriveService {
    static let shared = DriveService()

    private init() {}

    func uploadAttachment(emailId: String, attachmentIndex: Int) async throws -> DriveFile {
        let response: DriveUploadResponse = try await APIClient.shared.request(
            "/drive/upload",
            method: "POST",
            body: DriveUploadRequest(emailId: emailId, attachmentIndex: attachmentIndex)
        )
        return DriveFile(from: response)
    }

    func listFiles(limit: Int = 30) async throws -> [DriveFile] {
        let response: DriveFileListResponse = try await APIClient.shared.request(
            "/drive/files?limit=\(limit)"
        )
        return response.files.map { DriveFile(from: $0) }
    }

    func getDownloadUrl(fileId: String) async throws -> URL {
        let response: DriveDownloadUrlResponse = try await APIClient.shared.request(
            "/drive/files/\(fileId)/download-url"
        )

        guard let url = URL(string: response.downloadUrl) else {
            throw AppError.decoding("Invalid Drive download URL")
        }

        return url
    }
}
