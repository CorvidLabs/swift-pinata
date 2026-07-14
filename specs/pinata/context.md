---
spec: pinata.spec.md
---

## Key Decisions

- Keep the public client actor-based and async so request state does not cross concurrency boundaries unsafely.
- Preserve both supported authentication forms and apply authentication inside the transport boundary rather than at call sites.
- Treat Pinata's public/private network choice as an explicit API path input with private as the default.
- Keep live service mutation outside deterministic verification; environment-gated integration tests own that boundary.

## Files to Read First

- `Sources/Pinata/Pinata.swift` for public operations and transport behavior.
- `Sources/Pinata/PinataConfiguration.swift` and `PinataCredentials.swift` for endpoints and authentication.
- `Sources/Pinata/Models/` for response contracts.
- `Tests/PinataTests/PinataTests.swift` and `PinataResponseTests.swift` for credential-free evidence.
- `Tests/PinataTests/PinataIntegrationTests.swift` for the credentialed external-service boundary.

## Current Status

The existing pre-1.0 API is implemented and source-compatible with the package README. Deterministic tests validate configuration, authentication headers, gateway URLs, response decoding, date formats, network values, and Sendable error usage. Live file, swap, and group operations require credentials and are not represented as executed by this governance migration.

## Notes

The standalone macOS, Ubuntu, DocC Pages, and credentialed integration workflows remain independent. Trust delegates only the deterministic build and credential-free test lane.
