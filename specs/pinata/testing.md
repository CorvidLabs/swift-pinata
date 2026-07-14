---
spec: pinata.spec.md
---

## Automated Testing

| Test File | Type | What It Covers |
|-----------|------|----------------|
| `Tests/PinataTests/PinataTests.swift` | 7 deterministic tests | Configuration factories, credential headers, actor initialization, and gateway URL behavior. |
| `Tests/PinataTests/PinataResponseTests.swift` | 10 deterministic tests | File, group, swap, and page decoding; optional fields; date formats; network raw values; Sendable error usage. |
| `Tests/PinataTests/PinataIntegrationTests.swift` | 13 integration declarations | Credential-gated file and group operations; four persistent, destructive, or plugin-dependent cases remain manually disabled. |

## Manual Testing

- Review hosted macOS and Ubuntu build/test workflows after the migration commit.
- Treat live Pinata integration results separately from the deterministic Trust gate and require actual credentials before reporting them as executed.

## Edge Cases & Boundary Conditions

| Scenario | Expected Behavior |
|----------|-------------------|
| Optional response fields are null | Decode the file record with `nil` optional properties. |
| ISO-8601 date includes or omits fractional seconds | Decode either supported form. |
| Gateway domain is absent | Return `nil` instead of a malformed URL. |
| Pagination token is absent | Return `nil` while preserving the decoded collection. |
| Live credentials are absent | Skip the integration suite and perform no external mutation. |
| Destructive or persistent integration case is encountered | Remain disabled unless a maintainer explicitly enables it outside this migration. |
| Retryable response or transport failure occurs | Stay within the three-attempt retry budget and surface the terminal typed error. |
