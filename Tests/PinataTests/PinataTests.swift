import Testing
@testable import Pinata

@Suite("Pinata Tests")
struct PinataTests {
    @Test("Configuration initializes with JWT")
    func configurationWithJWT() {
        let config = PinataConfiguration.jwt("test-token", gatewayDomain: "test.mypinata.cloud")

        #expect(config.gatewayDomain == "test.mypinata.cloud")

        if case .jwt(let token) = config.credentials {
            #expect(token == "test-token")
        } else {
            Issue.record("Expected JWT credentials")
        }
    }

    @Test("Configuration initializes with API key")
    func configurationWithAPIKey() {
        let config = PinataConfiguration.apiKey(
            key: "test-key",
            secret: "test-secret"
        )

        if case .apiKey(let key, let secret) = config.credentials {
            #expect(key == "test-key")
            #expect(secret == "test-secret")
        } else {
            Issue.record("Expected API key credentials")
        }
    }

    @Test("JWT credentials produce correct authorization header")
    func jwtAuthorizationHeader() {
        let credentials = PinataCredentials.jwt("my-token")

        #expect(credentials.authorizationHeader == "Bearer my-token")
        #expect(credentials.additionalHeaders.isEmpty)
    }

    @Test("API key credentials produce correct headers")
    func apiKeyHeaders() {
        let credentials = PinataCredentials.apiKey(key: "my-key", secret: "my-secret")

        #expect(credentials.additionalHeaders["pinata_api_key"] == "my-key")
        #expect(credentials.additionalHeaders["pinata_secret_api_key"] == "my-secret")
    }

    @Test("Client initializes with configuration")
    func clientInitialization() async {
        let pinata = Pinata(jwt: "test-token", gatewayDomain: "test.mypinata.cloud")

        let config = await pinata.configuration
        #expect(config.gatewayDomain == "test.mypinata.cloud")
    }

    @Test("Gateway URL is constructed correctly")
    func gatewayURL() async {
        let pinata = Pinata(jwt: "test-token", gatewayDomain: "test.mypinata.cloud")

        let url = await pinata.gatewayURL(for: "QmTest123")

        #expect(url?.absoluteString == "https://test.mypinata.cloud/ipfs/QmTest123")
    }

    @Test("Gateway URL returns nil without domain")
    func gatewayURLWithoutDomain() async {
        let pinata = Pinata(jwt: "test-token")

        let url = await pinata.gatewayURL(for: "QmTest123")

        #expect(url == nil)
    }
}
