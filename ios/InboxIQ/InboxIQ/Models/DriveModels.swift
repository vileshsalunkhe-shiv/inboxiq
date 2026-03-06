import Foundation

struct DriveFile: Identifiable, Codable {
    let id: String
    let name: String
    let mimeType: String
    let webViewLink: String
    let modifiedTime: Date
    let size: Int
    let thumbnailLink: String?

    init(
        id: String,
        name: String,
        mimeType: String,
        webViewLink: String,
        modifiedTime: Date,
        size: Int,
        thumbnailLink: String?
    ) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.webViewLink = webViewLink
        self.modifiedTime = modifiedTime
        self.size = size
        self.thumbnailLink = thumbnailLink
    }

    init(from response: DriveUploadResponse) {
        self.init(
            id: response.fileId,
            name: response.name,
            mimeType: response.mimeType,
            webViewLink: response.webViewLink,
            modifiedTime: response.createdTime,
            size: response.size,
            thumbnailLink: nil
        )
    }

    init(from response: DriveFileResponse) {
        self.init(
            id: response.id,
            name: response.name,
            mimeType: response.mimeType,
            webViewLink: response.webViewLink,
            modifiedTime: response.modifiedTime,
            size: response.size,
            thumbnailLink: response.thumbnailLink
        )
    }
}

struct DriveUploadRequest: Encodable {
    let emailId: String
    let attachmentIndex: Int

    enum CodingKeys: String, CodingKey {
        case emailId = "email_id"
        case attachmentIndex = "attachment_index"
    }
}

struct DriveUploadResponse: Codable {
    let fileId: String
    let name: String
    let mimeType: String
    let webViewLink: String
    let createdTime: Date
    let size: Int

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case name
        case mimeType = "mime_type"
        case webViewLink = "web_view_link"
        case createdTime = "created_time"
        case size
    }
}

struct DriveFileListResponse: Codable {
    let files: [DriveFileResponse]
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case files
        case nextPageToken = "next_page_token"
    }
}

struct DriveFileResponse: Codable {
    let id: String
    let name: String
    let mimeType: String
    let webViewLink: String
    let modifiedTime: Date
    let size: Int
    let thumbnailLink: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mimeType = "mime_type"
        case webViewLink = "web_view_link"
        case modifiedTime = "modified_time"
        case size
        case thumbnailLink = "thumbnail_link"
    }
}

struct DriveDownloadUrlResponse: Codable {
    let downloadUrl: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case downloadUrl = "download_url"
        case expiresAt = "expires_at"
    }
}
