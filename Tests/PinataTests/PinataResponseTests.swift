import Foundation
import Testing
@testable import Pinata

@Suite("Pinata Response Parsing Tests")
struct PinataResponseTests {
    let decoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }

            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        self.decoder = decoder
    }

    @Test("Decode PinataFile from JSON")
    func decodePinataFile() throws {
        let json = """
        {
            "id": "file-123",
            "name": "test.txt",
            "cid": "QmTest123456789",
            "size": 1024,
            "number_of_files": 1,
            "mime_type": "text/plain",
            "group_id": "group-456",
            "keyvalues": {"key1": "value1"},
            "created_at": "2024-01-15T10:30:00.000Z"
        }
        """.data(using: .utf8)!

        let file = try decoder.decode(PinataFile.self, from: json)

        #expect(file.id == "file-123")
        #expect(file.name == "test.txt")
        #expect(file.cid == "QmTest123456789")
        #expect(file.size == 1024)
        #expect(file.numberOfFiles == 1)
        #expect(file.mimeType == "text/plain")
        #expect(file.groupId == "group-456")
        #expect(file.keyvalues?["key1"] == "value1")
    }

    @Test("Decode PinataFile with minimal fields")
    func decodePinataFileMinimal() throws {
        let json = """
        {
            "id": "file-123",
            "name": null,
            "cid": "QmTest123456789",
            "size": 512,
            "number_of_files": null,
            "mime_type": null,
            "group_id": null,
            "keyvalues": null,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let file = try decoder.decode(PinataFile.self, from: json)

        #expect(file.id == "file-123")
        #expect(file.name == nil)
        #expect(file.cid == "QmTest123456789")
        #expect(file.size == 512)
        #expect(file.numberOfFiles == nil)
        #expect(file.mimeType == nil)
        #expect(file.groupId == nil)
        #expect(file.keyvalues == nil)
    }

    @Test("Decode PinataGroup from JSON")
    func decodePinataGroup() throws {
        let json = """
        {
            "id": "group-123",
            "name": "My Group",
            "created_at": "2024-01-15T10:30:00.000Z"
        }
        """.data(using: .utf8)!

        let group = try decoder.decode(PinataGroup.self, from: json)

        #expect(group.id == "group-123")
        #expect(group.name == "My Group")
    }

    @Test("Decode PinataSwap from JSON")
    func decodePinataSwap() throws {
        let json = """
        {
            "mapped_cid": "QmSwappedCID123",
            "created_at": "2024-01-15T10:30:00.000Z"
        }
        """.data(using: .utf8)!

        let swap = try decoder.decode(PinataSwap.self, from: json)

        #expect(swap.mappedCid == "QmSwappedCID123")
    }

    @Test("Decode PinataFilesData from JSON")
    func decodePinataFilesData() throws {
        let json = """
        {
            "files": [
                {
                    "id": "file-1",
                    "name": "file1.txt",
                    "cid": "Qm1",
                    "size": 100,
                    "number_of_files": null,
                    "mime_type": null,
                    "group_id": null,
                    "keyvalues": null,
                    "created_at": "2024-01-15T10:30:00Z"
                },
                {
                    "id": "file-2",
                    "name": "file2.txt",
                    "cid": "Qm2",
                    "size": 200,
                    "number_of_files": null,
                    "mime_type": null,
                    "group_id": null,
                    "keyvalues": null,
                    "created_at": "2024-01-15T11:30:00Z"
                }
            ],
            "next_page_token": "token123"
        }
        """.data(using: .utf8)!

        let data = try decoder.decode(PinataFilesData.self, from: json)

        #expect(data.files.count == 2)
        #expect(data.files[0].id == "file-1")
        #expect(data.files[1].id == "file-2")
        #expect(data.nextPageToken == "token123")
    }

    @Test("Decode PinataFilesData without next page token")
    func decodePinataFilesDataNoToken() throws {
        let json = """
        {
            "files": [],
            "next_page_token": null
        }
        """.data(using: .utf8)!

        let data = try decoder.decode(PinataFilesData.self, from: json)

        #expect(data.files.isEmpty)
        #expect(data.nextPageToken == nil)
    }

    @Test("Decode PinataGroupsData from JSON")
    func decodePinataGroupsData() throws {
        let json = """
        {
            "groups": [
                {
                    "id": "group-1",
                    "name": "Group 1",
                    "created_at": "2024-01-15T10:30:00Z"
                }
            ],
            "next_page_token": null
        }
        """.data(using: .utf8)!

        let data = try decoder.decode(PinataGroupsData.self, from: json)

        #expect(data.groups.count == 1)
        #expect(data.groups[0].name == "Group 1")
        #expect(data.nextPageToken == nil)
    }

    @Test("PinataError cases are Sendable")
    func errorIsSendable() {
        let error: PinataError = .unauthorized
        let _: any Sendable = error
    }

    @Test("PinataNetwork raw values are correct")
    func networkRawValues() {
        #expect(PinataNetwork.public.rawValue == "public")
        #expect(PinataNetwork.private.rawValue == "private")
    }

    @Test("Date decoding handles both ISO8601 formats")
    func dateDecodingFormats() throws {
        // With fractional seconds
        let json1 = """
        {
            "id": "1",
            "name": "test",
            "cid": "Qm",
            "size": 0,
            "number_of_files": null,
            "mime_type": null,
            "group_id": null,
            "keyvalues": null,
            "created_at": "2024-01-15T10:30:00.123Z"
        }
        """.data(using: .utf8)!

        let file1 = try decoder.decode(PinataFile.self, from: json1)
        #expect(file1.createdAt.timeIntervalSince1970 > 0)

        // Without fractional seconds
        let json2 = """
        {
            "id": "2",
            "name": "test",
            "cid": "Qm",
            "size": 0,
            "number_of_files": null,
            "mime_type": null,
            "group_id": null,
            "keyvalues": null,
            "created_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let file2 = try decoder.decode(PinataFile.self, from: json2)
        #expect(file2.createdAt.timeIntervalSince1970 > 0)
    }
}
