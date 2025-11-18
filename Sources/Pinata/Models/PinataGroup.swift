import Foundation

/// Represents a group for organizing files on Pinata.
public struct PinataGroup: Codable, Sendable, Identifiable {
    /// The unique identifier for the group.
    public let id: String

    /// The group name.
    public let name: String

    /// When the group was created.
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}

/// Response wrapper for group operations.
struct PinataGroupResponse: Codable, Sendable {
    /// The group data.
    let data: PinataGroup
}

/// Response wrapper for listing groups.
struct PinataGroupsResponse: Codable, Sendable {
    /// The groups data.
    let data: PinataGroupsData
}

/// Container for group list data.
public struct PinataGroupsData: Codable, Sendable {
    /// The groups in this response.
    public let groups: [PinataGroup]

    /// Token for fetching the next page.
    public let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case groups
        case nextPageToken = "next_page_token"
    }
}
