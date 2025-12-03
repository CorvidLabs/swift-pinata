import Foundation

/**
 Represents a file stored on Pinata.
 */
public struct PinataFile: Codable, Sendable, Identifiable {
    /// The unique identifier for the file.
    public let id: String

    /// The file name.
    public let name: String?

    /// The IPFS content identifier (CID).
    public let cid: String

    /// The file size in bytes.
    public let size: Int

    /// The number of times this file has been pinned.
    public let numberOfFiles: Int?

    /// The MIME type of the file.
    public let mimeType: String?

    /// The group ID this file belongs to.
    public let groupId: String?

    /// Custom key-value metadata.
    public let keyvalues: [String: String]?

    /// When the file was created.
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cid
        case size
        case numberOfFiles = "number_of_files"
        case mimeType = "mime_type"
        case groupId = "group_id"
        case keyvalues
        case createdAt = "created_at"
    }
}

// MARK: - Swap Types

/**
 Represents a CID swap mapping.
 */
public struct PinataSwap: Codable, Sendable {
    /// The CID that is being pointed to.
    public let mappedCid: String

    /// When this swap was created.
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case mappedCid = "mapped_cid"
        case createdAt = "created_at"
    }
}

// MARK: - Response Types

/**
 Response wrapper for file operations.
 */
struct PinataFileResponse: Codable, Sendable {
    /// The file data.
    let data: PinataFile
}

/**
 Response wrapper for listing files.
 */
struct PinataFilesResponse: Codable, Sendable {
    /// The files data.
    let data: PinataFilesData
}

/**
 Container for file list data.
 */
public struct PinataFilesData: Codable, Sendable {
    /// The files in this response.
    public let files: [PinataFile]

    /// Token for fetching the next page.
    public let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case files
        case nextPageToken = "next_page_token"
    }
}

/**
 Response wrapper for swap operations.
 */
struct PinataSwapResponse: Codable, Sendable {
    /// The swap data.
    let data: PinataSwap
}

/**
 Response wrapper for swap history.
 */
struct PinataSwapHistoryResponse: Codable, Sendable {
    /// The swap history data.
    let data: [PinataSwap]
}
