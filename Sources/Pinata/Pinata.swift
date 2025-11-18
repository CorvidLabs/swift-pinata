import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 A client for interacting with the [Pinata](https://pinata.cloud) API.

 `Pinata` provides a type-safe interface for uploading, retrieving, and managing
 files on [IPFS](https://en.wikipedia.org/wiki/InterPlanetary_File_System) through Pinata's infrastructure.

 Example usage:

 ```swift
 let pinata = Pinata(jwt: "your-jwt-token", gatewayDomain: "your-gateway.mypinata.cloud")

 let file = try await pinata.upload(data: imageData, name: "photo.jpg")
 let url = pinata.gatewayURL(for: file.cid)
 ```
 */
public actor Pinata {
    /// The configuration for this client.
    public let configuration: PinataConfiguration

    /// The URL session used for requests.
    private let session: URLSession

    /// JSON decoder configured for Pinata API responses.
    private let decoder: JSONDecoder

    /// JSON encoder for request bodies.
    private let encoder: JSONEncoder

    /// Creates a new Pinata client.
    ///
    /// - Parameters:
    ///   - configuration: The configuration containing credentials and settings.
    ///   - session: Optional custom URL session. Defaults to `.shared`.
    public init(
        configuration: PinataConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Fall back to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    /// Creates a new Pinata client with JWT authentication.
    ///
    /// - Parameters:
    ///   - jwt: The JWT token.
    ///   - gatewayDomain: Optional custom gateway domain.
    ///   - session: Optional custom URL session. Defaults to `.shared`.
    public init(
        jwt: String,
        gatewayDomain: String? = nil,
        session: URLSession = .shared
    ) {
        self.init(
            configuration: .jwt(jwt, gatewayDomain: gatewayDomain),
            session: session
        )
    }

    /// Creates a new Pinata client with API key authentication.
    ///
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - apiSecret: The API secret.
    ///   - gatewayDomain: Optional custom gateway domain.
    ///   - session: Optional custom URL session. Defaults to `.shared`.
    public init(
        apiKey: String,
        apiSecret: String,
        gatewayDomain: String? = nil,
        session: URLSession = .shared
    ) {
        self.init(
            configuration: .apiKey(key: apiKey, secret: apiSecret, gatewayDomain: gatewayDomain),
            session: session
        )
    }
}

// MARK: - File Operations

public extension Pinata {
    /**
     Uploads data to Pinata.

     This method uploads raw data to Pinata's IPFS infrastructure and returns metadata
     about the uploaded file including its CID (Content Identifier).

     - Parameters:
        - data: The data to upload.
        - name: The file name.
        - groupId: Optional group ID to add the file to.
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: The uploaded file metadata including the CID.

     - Throws: `PinataError` if the upload fails.
     */
    func upload(
        data: Data,
        name: String,
        groupId: String? = nil,
        network: PinataNetwork = .private
    ) async throws -> PinataFile {
        let url = PinataConfiguration.uploadBaseURL.appendingPathComponent("v3/files")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        applyAuthentication(to: &request)

        var body = Data()

        // Add file data
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(name)\"\r\n".utf8))
        body.append(Data("Content-Type: application/octet-stream\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n".utf8))

        // Add name
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"name\"\r\n\r\n".utf8))
        body.append(Data("\(name)\r\n".utf8))

        // Add group ID if provided
        if let groupId {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"group_id\"\r\n\r\n".utf8))
            body.append(Data("\(groupId)\r\n".utf8))
        }

        // Add network
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"network\"\r\n\r\n".utf8))
        body.append(Data("\(network.rawValue)\r\n".utf8))

        body.append(Data("--\(boundary)--\r\n".utf8))
        request.httpBody = body

        let response: PinataFileResponse = try await perform(request)
        return response.data
    }

    /**
     Uploads a file from a URL.

     This is a convenience method that reads the file from disk and uploads it to Pinata.

     - Parameters:
        - fileURL: The local file URL.
        - name: Optional custom name (defaults to the file name).
        - groupId: Optional group ID.
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: The uploaded file metadata including the CID.

     - Throws: `PinataError` if the upload fails or the file cannot be read.
     */
    func upload(
        fileURL: URL,
        name: String? = nil,
        groupId: String? = nil,
        network: PinataNetwork = .private
    ) async throws -> PinataFile {
        let data = try Data(contentsOf: fileURL)
        let fileName = name ?? fileURL.lastPathComponent
        return try await upload(data: data, name: fileName, groupId: groupId, network: network)
    }

    /**
     Lists files with optional filtering.

     Retrieves a paginated list of files from your Pinata account with optional filters.

     - Parameters:
        - limit: Maximum number of files to return.
        - pageToken: Token for pagination.
        - groupId: Filter by group ID.
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: The files response containing file data and pagination info.

     - Throws: `PinataError` if the request fails.
     */
    func listFiles(
        limit: Int? = nil,
        pageToken: String? = nil,
        groupId: String? = nil,
        network: PinataNetwork = .private
    ) async throws -> PinataFilesData {
        let path = "v3/files/\(network.rawValue)"
        guard var components = URLComponents(
            url: PinataConfiguration.apiBaseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw PinataError.invalidURL(path)
        }

        var queryItems: [URLQueryItem] = []
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        if let groupId {
            queryItems.append(URLQueryItem(name: "group", value: groupId))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw PinataError.invalidURL(path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthentication(to: &request)

        let response: PinataFilesResponse = try await perform(request)
        return response.data
    }

    /**
     Gets a file by its ID.

     - Parameters:
        - id: The file ID.
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: The file metadata.

     - Throws: `PinataError.notFound` if the file does not exist.
     */
    func getFile(
        id: String,
        network: PinataNetwork = .private
    ) async throws -> PinataFile {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files")
            .appendingPathComponent(network.rawValue)
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthentication(to: &request)

        let response: PinataFileResponse = try await perform(request)
        return response.data
    }

    /**
     Deletes a file by its ID.

     - Parameters:
        - id: The file ID.
        - network: Network type (public or private). Defaults to `.private`.

     - Throws: `PinataError.notFound` if the file does not exist.
     */
    func deleteFile(
        id: String,
        network: PinataNetwork = .private
    ) async throws {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files")
            .appendingPathComponent(network.rawValue)
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyAuthentication(to: &request)

        _ = try await performRaw(request)
    }

    /**
     Returns the gateway URL for a CID.

     - Parameter cid: The IPFS content identifier.

     - Returns: The URL to access the content, or `nil` if no gateway is configured.
     */
    func gatewayURL(for cid: String) -> URL? {
        guard let domain = configuration.gatewayDomain else { return nil }
        return URL(string: "https://\(domain)/ipfs/\(cid)")
    }

    /**
     Updates a file's metadata.

     You can update the file's name and/or custom key-value metadata. The file content
     (and therefore CID) cannot be changed as IPFS content is immutable.

     - Parameters:
        - id: The file ID.
        - name: New name for the file (optional).
        - keyvalues: New key-value metadata (optional).
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: The updated file metadata.

     - Throws: `PinataError.notFound` if the file does not exist.
     */
    func updateFile(
        id: String,
        name: String? = nil,
        keyvalues: [String: String]? = nil,
        network: PinataNetwork = .private
    ) async throws -> PinataFile {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files")
            .appendingPathComponent(network.rawValue)
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthentication(to: &request)

        var body: [String: Any] = [:]
        if let name {
            body["name"] = name
        }
        if let keyvalues {
            body["keyvalues"] = keyvalues
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let response: PinataFileResponse = try await perform(request)
        return response.data
    }
}

// MARK: - Swap Operations

public extension Pinata {
    /**
     Creates a hot swap to redirect one CID to another.

     Hot swaps allow you to update content at a gateway level while maintaining the same
     original CID reference. This is useful for updating NFT metadata or other mutable content
     scenarios while preserving backward compatibility.

     - Parameters:
        - cid: The original CID to swap from.
        - swapCid: The new CID to redirect to.
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: The swap mapping details.

     - Throws: `PinataError` if the swap creation fails.

     - Note: Hot swaps only affect gateways with the Hot Swaps plugin installed.
     */
    func addSwap(
        cid: String,
        swapCid: String,
        network: PinataNetwork = .private
    ) async throws -> PinataSwap {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files")
            .appendingPathComponent(network.rawValue)
            .appendingPathComponent("swap")
            .appendingPathComponent(cid)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthentication(to: &request)

        let body = ["swapCid": swapCid]
        request.httpBody = try encoder.encode(body)

        let response: PinataSwapResponse = try await perform(request)
        return response.data
    }

    /**
     Gets the swap history for a CID.

     - Parameters:
        - cid: The original CID to get history for.
        - domain: The gateway domain with Hot Swaps plugin installed.
        - network: Network type (public or private). Defaults to `.private`.

     - Returns: Array of swap records showing the history of CID mappings.

     - Throws: `PinataError` if the request fails.
     */
    func getSwapHistory(
        cid: String,
        domain: String,
        network: PinataNetwork = .private
    ) async throws -> [PinataSwap] {
        let swapPath = "v3/files/\(network.rawValue)/swap/\(cid)"
        guard var components = URLComponents(
            url: PinataConfiguration.apiBaseURL
                .appendingPathComponent("v3/files")
                .appendingPathComponent(network.rawValue)
                .appendingPathComponent("swap")
                .appendingPathComponent(cid),
            resolvingAgainstBaseURL: false
        ) else {
            throw PinataError.invalidURL(swapPath)
        }

        components.queryItems = [URLQueryItem(name: "domain", value: domain)]

        guard let url = components.url else {
            throw PinataError.invalidURL(swapPath)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthentication(to: &request)

        let response: PinataSwapHistoryResponse = try await perform(request)
        return response.data
    }

    /**
     Removes a swap for a CID.

     After removal, the original CID will serve its original content again through the gateway.

     - Parameters:
        - cid: The original CID to remove the swap for.
        - network: Network type (public or private). Defaults to `.private`.

     - Throws: `PinataError` if the removal fails.
     */
    func removeSwap(
        cid: String,
        network: PinataNetwork = .private
    ) async throws {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files")
            .appendingPathComponent(network.rawValue)
            .appendingPathComponent("swap")
            .appendingPathComponent(cid)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyAuthentication(to: &request)

        _ = try await performRaw(request)
    }
}

// MARK: - Group Operations

public extension Pinata {
    /**
     Creates a new group.

     Groups allow you to organize your files into collections.

     - Parameter name: The group name.

     - Returns: The created group.

     - Throws: `PinataError` if the creation fails.
     */
    func createGroup(name: String) async throws -> PinataGroup {
        let url = PinataConfiguration.apiBaseURL.appendingPathComponent("v3/files/groups")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthentication(to: &request)

        let body = ["name": name]
        request.httpBody = try encoder.encode(body)

        let response: PinataGroupResponse = try await perform(request)
        return response.data
    }

    /**
     Lists all groups.

     - Parameters:
        - limit: Maximum number of groups to return.
        - pageToken: Token for pagination.

     - Returns: The groups response containing group data and pagination info.

     - Throws: `PinataError` if the request fails.
     */
    func listGroups(
        limit: Int? = nil,
        pageToken: String? = nil
    ) async throws -> PinataGroupsData {
        let groupsPath = "v3/files/groups"
        guard var components = URLComponents(
            url: PinataConfiguration.apiBaseURL.appendingPathComponent(groupsPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw PinataError.invalidURL(groupsPath)
        }

        var queryItems: [URLQueryItem] = []
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw PinataError.invalidURL(groupsPath)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthentication(to: &request)

        let response: PinataGroupsResponse = try await perform(request)
        return response.data
    }

    /**
     Gets a group by its ID.

     - Parameter id: The group ID.

     - Returns: The group metadata.

     - Throws: `PinataError.notFound` if the group does not exist.
     */
    func getGroup(id: String) async throws -> PinataGroup {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files/groups")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthentication(to: &request)

        let response: PinataGroupResponse = try await perform(request)
        return response.data
    }

    /**
     Deletes a group by its ID.

     - Parameter id: The group ID.

     - Throws: `PinataError.notFound` if the group does not exist.
     */
    func deleteGroup(id: String) async throws {
        let url = PinataConfiguration.apiBaseURL
            .appendingPathComponent("v3/files/groups")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyAuthentication(to: &request)

        _ = try await performRaw(request)
    }
}

// MARK: - Private Helpers

extension Pinata {
    /// Maximum number of retry attempts for transient failures.
    private static let maxRetries = 3

    /// Base delay between retries in nanoseconds (500ms).
    private static let baseRetryDelay: UInt64 = 500_000_000

    private func applyAuthentication(to request: inout URLRequest) {
        request.setValue(
            configuration.credentials.authorizationHeader,
            forHTTPHeaderField: "Authorization"
        )
        for (key, value) in configuration.credentials.additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, _) = try await performRaw(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PinataError.decodingFailed(error)
        }
    }

    private func performRaw(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<Self.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PinataError.unknown("Invalid response type")
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return (data, response)
                case 400:
                    let message = String(data: data, encoding: .utf8) ?? "Bad request"
                    throw PinataError.badRequest(message)
                case 401:
                    throw PinataError.unauthorized
                case 404:
                    throw PinataError.notFound
                case 429, 500, 502, 503, 504:
                    // Retryable errors
                    lastError = PinataError.serverError(httpResponse.statusCode)
                    if attempt < Self.maxRetries - 1 {
                        let delay = Self.baseRetryDelay * UInt64(attempt + 1)
                        try await Task.sleep(nanoseconds: delay)
                        continue
                    }
                    throw PinataError.serverError(httpResponse.statusCode)
                default:
                    throw PinataError.serverError(httpResponse.statusCode)
                }
            } catch let error as PinataError {
                // Don't retry client errors
                switch error {
                case .badRequest, .unauthorized, .notFound, .decodingFailed, .encodingFailed, .invalidURL:
                    throw error
                case .networkError, .serverError, .unknown:
                    lastError = error
                    if attempt < Self.maxRetries - 1 {
                        let delay = Self.baseRetryDelay * UInt64(attempt + 1)
                        try await Task.sleep(nanoseconds: delay)
                        continue
                    }
                    throw error
                }
            } catch {
                // Network errors are retryable
                lastError = PinataError.networkError(error)
                if attempt < Self.maxRetries - 1 {
                    let delay = Self.baseRetryDelay * UInt64(attempt + 1)
                    try await Task.sleep(nanoseconds: delay)
                    continue
                }
                throw PinataError.networkError(error)
            }
        }

        throw lastError ?? PinataError.unknown("Request failed after retries")
    }
}
