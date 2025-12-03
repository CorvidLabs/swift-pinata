import Foundation

/**
 Errors that can occur when interacting with the Pinata API.
 */
public enum PinataError: Error, Sendable {
    /// The request was invalid or malformed.
    case badRequest(String)

    /// Authentication failed due to invalid or missing credentials.
    case unauthorized

    /// The requested resource was not found.
    case notFound

    /// The server encountered an error.
    case serverError(Int)

    /// Failed to encode the request body.
    case encodingFailed(Error)

    /// Failed to decode the response.
    case decodingFailed(Error)

    /// A network error occurred.
    case networkError(Error)

    /// An unknown error occurred.
    case unknown(String)

    /// Failed to construct a valid URL.
    case invalidURL(String)
}

extension PinataError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized:
            return "Unauthorized: Invalid or missing credentials"
        case .notFound:
            return "Not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .invalidURL(let path):
            return "Invalid URL: \(path)"
        }
    }
}
