---
change: CHG-0002-document-the-existing-swift-pinata-api-at-complete-specsync-coverage
artifact: testing
---

# Testing

| Requirement | Evidence |
|-------------|----------|
| `REQ-pinata-001` | Seven deterministic configuration, credential, actor, and gateway tests. |
| `REQ-pinata-002` | Ten deterministic response, optional-field, date, network-value, and Sendable tests. |
| `REQ-pinata-003` | Source review plus credential-gated file integration cases. |
| `REQ-pinata-004` | Two deterministic gateway URL assertions. |
| `REQ-pinata-005` | Source review; plugin-dependent live case remains disabled. |
| `REQ-pinata-006` | Deterministic group decoding plus credential-gated group cases. |
| `REQ-pinata-007` | Source review of status mapping and retry control flow; no unsupported live claim. |
| `REQ-pinata-008` | Actor declaration and explicit environment/manual integration guards. |

Native verification runs `swift build` and `env -u PINATA_JWT -u PINATA_GATEWAY swift test`. It must report the credential-free tests as passing and the live suite as skipped.
