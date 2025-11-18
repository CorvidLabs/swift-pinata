# Pinata

A Swift package for interacting with the [Pinata](https://pinata.cloud) API for IPFS file storage.

## Requirements

- Swift 6.0+
- iOS 15+ / macOS 12+ / watchOS 8+ / tvOS 15+ / visionOS 1+ / Linux

## Installation

### Swift Package Manager

Add Pinata to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/Pinata", from: "0.1.0")
]
```

## Usage

### Configuration

Create a Pinata client with your credentials:

```swift
import Pinata

// Using JWT (recommended)
let pinata = Pinata(
    jwt: "your-jwt-token",
    gatewayDomain: "your-gateway.mypinata.cloud"
)

// Using API key
let pinata = Pinata(
    apiKey: "your-api-key",
    apiSecret: "your-api-secret",
    gatewayDomain: "your-gateway.mypinata.cloud"
)
```

### Uploading Files

```swift
// Upload data
let file = try await pinata.upload(
    data: imageData,
    name: "photo.jpg"
)

// Upload from file URL
let file = try await pinata.upload(
    fileURL: localFileURL,
    name: "document.pdf"
)

// Upload to a group
let file = try await pinata.upload(
    data: data,
    name: "file.txt",
    groupId: "group-id"
)
```

### Retrieving Files

```swift
// List files
let files = try await pinata.listFiles(limit: 10)

// Get a specific file
let file = try await pinata.getFile(id: "file-id")

// Get gateway URL for a CID
if let url = await pinata.gatewayURL(for: file.cid) {
    // Use URL to fetch content
}

// Delete a file
try await pinata.deleteFile(id: "file-id")
```

### Managing Groups

```swift
// Create a group
let group = try await pinata.createGroup(name: "My Group")

// List groups
let groups = try await pinata.listGroups()

// Get a specific group
let group = try await pinata.getGroup(id: "group-id")

// Delete a group
try await pinata.deleteGroup(id: "group-id")
```

## License

Pinata is available under the MIT license. See the LICENSE file for more info.
