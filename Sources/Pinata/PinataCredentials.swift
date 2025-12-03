import Foundation

/**
 Network type for file uploads.
 */
public enum PinataNetwork: String, Sendable {
    /// Public IPFS network - files are accessible via any IPFS gateway.
    case `public` = "public"

    /// Private IPFS network - files are only accessible via your Pinata gateway.
    case `private` = "private"
}

/**
 Credentials for authenticating with the Pinata API.
 */
public enum PinataCredentials: Sendable {
    /// JWT-based authentication (recommended).
    case jwt(String)

    /// API key pair authentication.
    case apiKey(key: String, secret: String)

    /// Returns the authorization header value for this credential type.
    var authorizationHeader: String {
        switch self {
        case .jwt(let token):
            return "Bearer \(token)"
        case .apiKey(let key, _):
            return "Bearer \(key)"
        }
    }

    /// Returns additional headers required for API key authentication.
    var additionalHeaders: [String: String] {
        switch self {
        case .jwt:
            return [:]
        case .apiKey(let key, let secret):
            return [
                "pinata_api_key": key,
                "pinata_secret_api_key": secret
            ]
        }
    }
}
