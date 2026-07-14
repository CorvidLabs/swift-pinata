---
module: pinata
version: 3
status: active
files:
  - Sources/Pinata/Pinata.swift
  - Sources/Pinata/Models/PinataGroup.swift
  - Sources/Pinata/Models/PinataFile.swift
  - Sources/Pinata/PinataError.swift
  - Sources/Pinata/PinataConfiguration.swift
  - Sources/Pinata/PinataCredentials.swift

db_tables: []
depends_on: []
---

# Pinata

## Purpose

The Pinata module is a Swift 6 client for Pinata's v3 file API. It owns credential and endpoint configuration, asynchronous file and group operations, gateway URL construction, CID hot-swap operations, response decoding, and transport error mapping. It does not own credential storage, gateway provisioning, or the lifecycle of caller data outside explicit API requests.

## Public API

| Export | Behavior |
|--------|----------|
| `Pinata` | Actor that executes authenticated API operations through an injected or shared `URLSession`. |
| `configuration` | Immutable actor configuration. |
| `init` | Public configuration, JWT, and API-key client initialization. |
| `upload` | Uploads in-memory data or a local file, optionally assigning a group. |
| `listFiles` | Lists filtered, paginated files for a selected network. |
| `getFile` | Retrieves one file record by identifier and network. |
| `deleteFile` | Deletes one file by identifier and network. |
| `gatewayURL` | Builds an HTTPS `/ipfs/{cid}` URL when a gateway domain exists. |
| `updateFile` | Updates supplied file name or key-value metadata without replacing content. |
| `addSwap` | Creates a CID hot-swap mapping. |
| `getSwapHistory` | Retrieves hot-swap history for a CID and gateway domain. |
| `removeSwap` | Removes a CID hot-swap mapping. |
| `createGroup` | Creates a named file group. |
| `listGroups` | Lists paginated groups. |
| `getGroup` | Retrieves one group record. |
| `deleteGroup` | Deletes one group. |
| `PinataNetwork` | Selects the public or private Pinata file network. |
| `PinataCredentials` | Stores JWT or API-key authentication material. |
| `jwt` | JWT credential case and configuration factory. |
| `apiKey` | API-key credential case and configuration factory. |
| `PinataConfiguration` | Immutable credentials and optional gateway domain. |
| `apiBaseURL` | `https://api.pinata.cloud` service root. |
| `uploadBaseURL` | `https://uploads.pinata.cloud` upload root. |
| `credentials` | Selected authentication material. |
| `gatewayDomain` | Optional custom content gateway domain. |
| `PinataError` | Typed request, authentication, server, codec, network, URL, and unknown failures. |
| `badRequest` | HTTP 400 error with response detail. |
| `unauthorized` | HTTP 401 authentication error. |
| `notFound` | HTTP 404 lookup error. |
| `serverError` | Non-success server status. |
| `encodingFailed` | Request encoding error case. |
| `decodingFailed` | Response decoding error case. |
| `networkError` | URLSession transport error case. |
| `unknown` | Fallback error detail. |
| `invalidURL` | URL-construction error with attempted path. |
| `errorDescription` | Localized description for each typed error. |
| `PinataFile` | Codable file metadata. |
| `id` | File or group identifier. |
| `name` | Optional file name or required group name. |
| `cid` | IPFS content identifier. |
| `size` | File size in bytes. |
| `numberOfFiles` | Optional decoded file-count field. |
| `mimeType` | Optional MIME type. |
| `groupId` | Optional associated group identifier. |
| `keyvalues` | Optional custom file metadata. |
| `createdAt` | Decoded creation time. |
| `PinataSwap` | Codable mapped CID and creation time. |
| `mappedCid` | CID currently serving for a hot swap. |
| `PinataFilesData` | File page and optional continuation token. |
| `files` | Decoded page of file records. |
| `nextPageToken` | Optional file or group continuation token. |
| `PinataGroup` | Codable group metadata. |
| `PinataGroupsData` | Group page and optional continuation token. |
| `groups` | Decoded page of group records. |

## Invariants

1. File operations default to the private Pinata network unless the caller explicitly selects the public network.
2. Every Pinata API request applies the selected credentials; JWT uses a bearer token, while API-key credentials also add the two Pinata key headers.
3. A file content CID is immutable through `updateFile`; that operation only sends optional name and key-value metadata.
4. Gateway URL construction returns `nil` without a configured domain and otherwise uses HTTPS with the `/ipfs/{cid}` path.
5. JSON snake-case fields such as `created_at`, `next_page_token`, `group_id`, and `mapped_cid` decode into the documented Swift properties.
6. HTTP 400, 401, and 404 failures are not retried. HTTP 429 and 500/502/503/504 failures and transport failures are retried up to three total attempts with increasing 500 ms delays.
7. The public client is an actor, and its configuration, session, decoder, and encoder are fixed at initialization.
8. Tests that call Pinata's live service require `PINATA_JWT`; destructive or persistent integration cases remain explicitly disabled even when credentials exist.

## Behavioral Examples

### Scenario: Configure and retrieve through a gateway

- **Given** JWT credentials and gateway domain `files.example.test`
- **When** a caller asks `gatewayURL(for: "bafy...")`
- **Then** the client returns `https://files.example.test/ipfs/bafy...` without making a network request.

### Scenario: Paginate private files

- **Given** the default private network, a limit, and an optional page token
- **When** `listFiles` executes
- **Then** it requests the private file endpoint, adds supported query parameters, authenticates the request, and decodes files plus `next_page_token`.

### Scenario: Update file metadata

- **Given** a file identifier and optional name or key-value metadata
- **When** `updateFile` executes
- **Then** it sends only supplied metadata as JSON and returns the decoded file record without replacing file content.

### Scenario: Transient server failure

- **Given** a response status eligible for retry
- **When** a request fails before the third attempt
- **Then** the client waits using the increasing delay and retries; the final retryable failure is surfaced as `PinataError.serverError` or `networkError`.

## Error Cases

| Condition | Behavior |
|-----------|----------|
| URL components cannot produce a URL | Throw `PinataError.invalidURL` with the attempted API path. |
| HTTP 400 | Throw `badRequest` using the response text or a fallback message. |
| HTTP 401 | Throw `unauthorized`. |
| HTTP 404 | Throw `notFound`. |
| HTTP 429 or retryable 5xx | Retry within the three-attempt budget, then throw `serverError`. |
| Other non-success HTTP status | Throw `serverError` without retry. |
| Response is not HTTP | Retry and ultimately throw `unknown`. |
| Response decoding fails | Throw `decodingFailed` without retry. |
| URLSession fails | Retry and ultimately throw `networkError`. |
| No gateway domain is configured | Return `nil`; this is not an error. |

## Dependencies

### Consumes

| Module | What is used |
|--------|-------------|
| Foundation | `Data`, `Date`, URLs, JSON codecs, and ISO-8601 date parsing. |
| FoundationNetworking | Linux networking compatibility when available. |
| URLSession | Asynchronous HTTP transport, injectable for client construction. |
| Pinata API and gateway | External file, swap, group, and content delivery services. |

### Consumed By

| Module | What is used |
|--------|-------------|
| Swift package clients | Typed asynchronous Pinata file and group operations. |

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-07-13 | `user:0xLeif` | Documented the existing Swift Pinata contract at complete SpecSync coverage without product-code changes. |
| 2026-07-14 | CHG-0002-document-the-existing-swift-pinata-api-at-complete-specsync-coverage: Document the existing Swift Pinata API at complete SpecSync coverage |
