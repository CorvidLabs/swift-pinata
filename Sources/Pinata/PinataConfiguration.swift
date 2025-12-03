import Foundation

/**
 Configuration for the Pinata client.

 Example usage:

 ```swift
 let config = PinataConfiguration.jwt("your-token", gatewayDomain: "your-gateway.mypinata.cloud")
 let pinata = Pinata(configuration: config)
 ```
 */
public struct PinataConfiguration: Sendable {
    /// The base URL for the Pinata API.
    public static let apiBaseURL = URL(string: "https://api.pinata.cloud")!

    /// The base URL for file uploads.
    public static let uploadBaseURL = URL(string: "https://uploads.pinata.cloud")!

    /// The credentials used for authentication.
    public let credentials: PinataCredentials

    /// The gateway domain for retrieving files (e.g., "your-gateway.mypinata.cloud").
    public let gatewayDomain: String?

    /**
     Creates a new Pinata configuration.

     - Parameters:
       - credentials: The credentials for authenticating with the API.
       - gatewayDomain: Optional custom gateway domain for file retrieval.
     */
    public init(
        credentials: PinataCredentials,
        gatewayDomain: String? = nil
    ) {
        self.credentials = credentials
        self.gatewayDomain = gatewayDomain
    }

    /**
     Creates a configuration with JWT authentication.

     - Parameters:
       - jwt: The JWT token.
       - gatewayDomain: Optional custom gateway domain.

     - Returns: A configured `PinataConfiguration`.
     */
    public static func jwt(
        _ token: String,
        gatewayDomain: String? = nil
    ) -> PinataConfiguration {
        PinataConfiguration(
            credentials: .jwt(token),
            gatewayDomain: gatewayDomain
        )
    }

    /**
     Creates a configuration with API key authentication.

     - Parameters:
       - key: The API key.
       - secret: The API secret.
       - gatewayDomain: Optional custom gateway domain.

     - Returns: A configured `PinataConfiguration`.
     */
    public static func apiKey(
        key: String,
        secret: String,
        gatewayDomain: String? = nil
    ) -> PinataConfiguration {
        PinataConfiguration(
            credentials: .apiKey(key: key, secret: secret),
            gatewayDomain: gatewayDomain
        )
    }
}
