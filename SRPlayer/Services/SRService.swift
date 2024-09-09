import Foundation
import UIKit
import XMLCoder

// MARK: SRServiceProvider

protocol SRServiceProvider: Sendable {
    func fetchChannels() async throws -> [SRService.Channel]
}

// MARK: SRService

struct SRService: SRServiceProvider {
    let client: APIClientProvider
    func fetchChannels() async throws -> [SRService.Channel] {
        guard let url = URL(string: "https://api.sr.se/api/v2/channels") else {
            throw SRServiceError.invalidServiceURL
        }
        let request = URLRequest(url: url)
        let decoded: SRResponse = try await client.fetch(request)

        return decoded.channels.channel
    }
}

// MARK: Nested models

extension SRService {
    enum SRServiceError: Error {
        case invalidServiceURL
    }

    struct SRResponse: Decodable, Equatable {
        let channels: ChannelsWrapper

        enum CodingKeys: String, CodingKey {
            case channels
        }
    }

    // Due to XML Array limitation we need to wrap the array with a container. See  https://github.com/CoreOffice/XMLCoder/issues/139
    struct ChannelsWrapper: Decodable, Equatable {
        let channel: [Channel]
    }

    struct Channel: Codable, Equatable, Identifiable, DynamicNodeEncoding {
        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key {
            case Self.CodingKeys.id, Self.CodingKeys.name:
                .attribute

            default:
                .element
            }
        }

        var id: Int
        var name: String?
        var image: String?
        var color: String?
        var tagline: String?
        var siteUrl: String?
        var liveAudio: LiveAudio?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case image
            case color
            case tagline
            case siteUrl = "siteurl"
            case liveAudio = "liveaudio"
        }
    }

    struct LiveAudio: Codable, Equatable {
        let url: URL?
    }
}
