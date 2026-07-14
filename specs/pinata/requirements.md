---
spec: pinata.spec.md
---

## User Stories

- As a Swift caller, I can configure a Pinata actor with JWT or API-key credentials and an optional gateway.
- As a file owner, I can upload, list, retrieve, update metadata for, and delete Pinata files on an explicit network.
- As a gateway operator, I can construct content URLs and manage supported CID hot swaps.
- As an organizer, I can create, paginate, retrieve, and delete Pinata groups.
- As a maintainer, I can distinguish client, server, transport, decoding, and URL failures through typed errors.

## Acceptance Criteria

- All six implementation files are owned by this active companion at 100% file and LOC coverage.
- Every parser-visible public export is described in the canonical public API inventory.
- Requirements `REQ-pinata-001` through `REQ-pinata-008` trace source behavior to deterministic tests or the explicit live-service boundary.
- Strict SpecSync validation passes with an A/100 score and no unfinished scaffold markers or invented evidence.
- The governance migration changes no file under `Sources/` or `Tests/`.

## Constraints

- Swift 6 and the package's declared Apple/Linux platform boundaries remain unchanged.
- Credentials are caller-provided and must not be committed, logged, or embedded in specifications.
- Deterministic verification unsets `PINATA_JWT` and `PINATA_GATEWAY` and must not mutate external resources.
- Live integration evidence is valid only when its credentialed workflow actually runs; manually disabled destructive and persistent cases are not claimed as passing.
- Pinata service behavior beyond the implemented HTTP contract remains external to this package.

## Out of Scope

- Provisioning Pinata accounts, gateway domains, or the Hot Swaps plugin.
- Managing secrets or refreshing credentials.
- Changing product API behavior, retry policy, or package platform support in this documentation-only change.
- Executing destructive or persistent live-service tests as part of the migration.

### REQ-pinata-001

The package SHALL construct immutable configuration from JWT or API-key credentials, expose the optional gateway domain, use the documented Pinata API roots, apply bearer authentication to API requests, and add Pinata key headers for API-key credentials.

Acceptance Criteria
- Configuration factories preserve the supplied credential material and gateway domain.
- JWT credentials produce a bearer header; API-key credentials also produce both Pinata key headers.
- Client initialization accepts an injected session without changing the public configuration contract.

### REQ-pinata-002

The package SHALL decode file, group, swap, and paginated collection responses into Sendable public models, preserving optional metadata and mapping Pinata's snake-case JSON fields to Swift properties.

Acceptance Criteria
- Full and minimal file records decode, including nullable metadata.
- Group, swap, file-page, and group-page records map their declared fields and continuation tokens.
- Creation dates accept ISO-8601 timestamps with or without fractional seconds.

### REQ-pinata-003

The client SHALL upload in-memory or local-file data, list and retrieve files on an explicit public or private network, update only supplied name or key-value metadata, delete files, and decode returned file records. The default network SHALL be private.

Acceptance Criteria
- Upload requests include file data, name, optional group, and selected network.
- List requests include only supplied pagination and group filters.
- Metadata updates do not replace file content or its CID.
- Live mutation evidence remains isolated behind `PINATA_JWT` and is not claimed when skipped.

### REQ-pinata-004

The client SHALL return `nil` when no gateway domain is configured and otherwise build an HTTPS `/ipfs/{cid}` URL without issuing a network request.

Acceptance Criteria
- A configured gateway produces the expected content URL.
- An absent gateway produces `nil`.

### REQ-pinata-005

The client SHALL create, retrieve history for, and remove CID hot-swap mappings on an explicit network, including the required gateway-domain query for history.

Acceptance Criteria
- Create and remove operations address the selected network and original CID.
- History includes the supplied gateway domain as a query parameter.
- Plugin-dependent execution remains manually disabled unless its prerequisite exists.

### REQ-pinata-006

The client SHALL create, paginate, retrieve, and delete file groups and decode group responses with optional pagination tokens.

Acceptance Criteria
- Create encodes the supplied group name.
- List includes only supplied limit and page token values.
- Credential-gated live group operations are not represented as passing when the suite is skipped.

### REQ-pinata-007

The client SHALL map HTTP, decoding, transport, URL, and unknown failures to the documented `PinataError` cases. It SHALL retry HTTP 429, 500, 502, 503, 504 and transport failures within a three-attempt budget using increasing 500 ms delays, while client and codec errors SHALL not be retried.

Acceptance Criteria
- HTTP 400, 401, and 404 map to their specific cases without retry.
- Retryable status and transport failures remain within three total attempts.
- Localized descriptions identify every public error case.

### REQ-pinata-008

The public client SHALL remain an actor with async operations and immutable configuration. Deterministic verification SHALL unset live Pinata credentials, while credentialed, destructive, persistent, or plugin-dependent integration cases SHALL remain separately controlled.

Acceptance Criteria
- Credential-free build and test verification performs no external Pinata mutation.
- Live results are reported only when their environment-gated suite actually executes.
- Existing macOS, Ubuntu, documentation, and live-integration workflows remain independent.

