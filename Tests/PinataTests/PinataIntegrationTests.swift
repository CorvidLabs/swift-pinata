import Foundation
import Testing
@testable import Pinata

/// Integration tests that require a valid Pinata JWT.
///
/// Set the `PINATA_JWT` environment variable to run these tests.
/// All tests clean up resources they create.
@Suite("Pinata Integration Tests", .enabled(if: ProcessInfo.processInfo.environment["PINATA_JWT"] != nil))
struct PinataIntegrationTests {
    let pinata: Pinata

    init() {
        let jwt = ProcessInfo.processInfo.environment["PINATA_JWT"] ?? ""
        let gateway = ProcessInfo.processInfo.environment["PINATA_GATEWAY"]
        self.pinata = Pinata(jwt: jwt, gatewayDomain: gateway)
    }

    @Test("Upload and delete file")
    func uploadAndDeleteFile() async throws {
        // Create test data
        let testData = "Hello, Pinata! \(UUID().uuidString)".data(using: .utf8)!
        let fileName = "test-\(UUID().uuidString).txt"

        // Upload
        let file = try await pinata.upload(data: testData, name: fileName)

        do {
            #expect(file.name == fileName)
            #expect(!file.cid.isEmpty)
            #expect(file.size == testData.count)

            // Verify we can retrieve it
            let retrieved = try await pinata.getFile(id: file.id)
            #expect(retrieved.id == file.id)
            #expect(retrieved.cid == file.cid)
        } catch {
            // Cleanup on error
            try? await pinata.deleteFile(id: file.id)
            throw error
        }

        // Cleanup on success
        try? await pinata.deleteFile(id: file.id)
    }

    @Test("List files with pagination")
    func listFilesWithPagination() async throws {
        let files = try await pinata.listFiles(limit: 5)

        #expect(files.files.count <= 5)
    }

    @Test("Create and delete group")
    func createAndDeleteGroup() async throws {
        let groupName = "test-group-\(UUID().uuidString)"

        // Create
        let group = try await pinata.createGroup(name: groupName)

        do {
            #expect(group.name == groupName)
            #expect(!group.id.isEmpty)

            // Verify we can retrieve it
            let retrieved = try await pinata.getGroup(id: group.id)
            #expect(retrieved.id == group.id)
            #expect(retrieved.name == groupName)
        } catch {
            try? await pinata.deleteGroup(id: group.id)
            throw error
        }

        try? await pinata.deleteGroup(id: group.id)
    }

    @Test("Upload file to group and clean up both")
    func uploadFileToGroup() async throws {
        // Create group first
        let groupName = "test-group-\(UUID().uuidString)"
        let group = try await pinata.createGroup(name: groupName)

        // Upload file to group (unique content to avoid duplicate detection)
        let testData = "Group file content \(UUID().uuidString)".data(using: .utf8)!
        let file = try await pinata.upload(
            data: testData,
            name: "grouped-file-\(UUID().uuidString).txt",
            groupId: group.id
        )

        #expect(file.groupId == group.id)

        // Cleanup
        try? await pinata.deleteFile(id: file.id)
        try? await pinata.deleteGroup(id: group.id)
    }

    @Test("List groups")
    func listGroups() async throws {
        let groups = try await pinata.listGroups(limit: 10)

        // Just verify the call succeeds and returns valid data
        #expect(groups.groups.count <= 10)
    }

    @Test("Get file returns not found for invalid ID")
    func getFileNotFound() async throws {
        do {
            _ = try await pinata.getFile(id: "invalid-file-id-\(UUID().uuidString)")
            Issue.record("Expected not found error")
        } catch PinataError.notFound {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Get group returns error for invalid ID")
    func getGroupNotFound() async throws {
        do {
            _ = try await pinata.getGroup(id: "invalid-group-id-\(UUID().uuidString)")
            Issue.record("Expected error")
        } catch PinataError.notFound {
            // Expected
        } catch PinataError.serverError {
            // API may return 500 for invalid group IDs
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Update file name and metadata")
    func updateFileNameAndMetadata() async throws {
        // Upload a file first
        let testData = "Update test \(UUID().uuidString)".data(using: .utf8)!
        let originalName = "original-\(UUID().uuidString).txt"
        let file = try await pinata.upload(data: testData, name: originalName)

        do {
            // Update the name
            let newName = "updated-\(UUID().uuidString).txt"
            let updated = try await pinata.updateFile(
                id: file.id,
                name: newName,
                keyvalues: ["version": "2", "author": "test"]
            )

            #expect(updated.name == newName)
            #expect(updated.keyvalues?["version"] == "2")
            #expect(updated.keyvalues?["author"] == "test")
            #expect(updated.id == file.id)
            #expect(updated.cid == file.cid) // CID doesn't change
        } catch {
            try? await pinata.deleteFile(id: file.id)
            throw error
        }

        try? await pinata.deleteFile(id: file.id)
    }

    @Test("Update file metadata only")
    func updateFileMetadataOnly() async throws {
        let testData = "Metadata test \(UUID().uuidString)".data(using: .utf8)!
        let fileName = "metadata-test-\(UUID().uuidString).txt"
        let file = try await pinata.upload(data: testData, name: fileName)

        do {
            // Update only metadata, keep the name
            let updated = try await pinata.updateFile(
                id: file.id,
                keyvalues: ["category": "test", "priority": "high"]
            )

            #expect(updated.name == fileName) // Name unchanged
            #expect(updated.keyvalues?["category"] == "test")
            #expect(updated.keyvalues?["priority"] == "high")
        } catch {
            try? await pinata.deleteFile(id: file.id)
            throw error
        }

        try? await pinata.deleteFile(id: file.id)
    }

    @Test("Hot swap CIDs", .disabled("Requires gateway with Hot Swaps plugin"))
    func hotSwapCIDs() async throws {
        // Upload two files
        let data1 = "Version 1 \(UUID().uuidString)".data(using: .utf8)!
        let data2 = "Version 2 \(UUID().uuidString)".data(using: .utf8)!

        let file1 = try await pinata.upload(data: data1, name: "v1-\(UUID().uuidString).txt")
        let file2 = try await pinata.upload(data: data2, name: "v2-\(UUID().uuidString).txt")

        do {
            // Create a swap so file1's CID points to file2's content
            let swap = try await pinata.addSwap(cid: file1.cid, swapCid: file2.cid)
            #expect(swap.mappedCid == file2.cid)

            // Remove the swap
            try await pinata.removeSwap(cid: file1.cid)
        } catch {
            try? await pinata.deleteFile(id: file1.id)
            try? await pinata.deleteFile(id: file2.id)
            throw error
        }

        try? await pinata.deleteFile(id: file1.id)
        try? await pinata.deleteFile(id: file2.id)
    }

    @Test("Upload persistent file to IPFS", .disabled("Enable manually to upload a persistent file"))
    func uploadPersistentFile() async throws {
        // This test uploads a PUBLIC file that remains on IPFS (not deleted)
        // Enable manually when you want to verify files appear on your gateway
        let testData = "Persistent file uploaded at \(Date()) - \(UUID().uuidString)".data(using: .utf8)!
        let fileName = "persistent-\(UUID().uuidString).txt"

        let file = try await pinata.upload(data: testData, name: fileName, network: .public)

        print("Uploaded persistent file:")
        print("  ID: \(file.id)")
        print("  CID: \(file.cid)")
        print("  Name: \(file.name ?? "unnamed")")

        if let gatewayURL = await pinata.gatewayURL(for: file.cid) {
            print("  Gateway URL: \(gatewayURL)")
        } else {
            print("  Public IPFS URL: https://ipfs.io/ipfs/\(file.cid)")
        }

        #expect(!file.cid.isEmpty)
        // File is NOT deleted - it will persist on your Pinata account
    }

    @Test("List all files", .disabled("Enable manually to list all files"))
    func listAllFiles() async throws {
        let files = try await pinata.listFiles(limit: 100)
        print("Files in account: \(files.files.count)")
        for file in files.files {
            print("  - \(file.id): \(file.name ?? "unnamed") (CID: \(file.cid))")
        }
    }

    @Test("Delete all files", .disabled("Enable manually to delete all files"))
    func deleteAllFiles() async throws {
        // Delete both private and public files
        var deletedCount = 0

        // Delete private files
        var pageToken: String? = nil
        repeat {
            let files = try await pinata.listFiles(limit: 100, pageToken: pageToken)

            for file in files.files {
                try await pinata.deleteFile(id: file.id)
                print("Deleted private: \(file.id) - \(file.name ?? "unnamed")")
                deletedCount += 1
            }

            pageToken = files.nextPageToken
        } while pageToken != nil

        // Delete public files
        pageToken = nil
        repeat {
            let files = try await pinata.listFiles(limit: 100, pageToken: pageToken, network: .public)

            for file in files.files {
                try await pinata.deleteFile(id: file.id, network: .public)
                print("Deleted public: \(file.id) - \(file.name ?? "unnamed")")
                deletedCount += 1
            }

            pageToken = files.nextPageToken
        } while pageToken != nil

        print("Total deleted: \(deletedCount) files")
    }
}
