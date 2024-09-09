import Foundation
import NiceToHave
@testable import SRPlayer
import XCTest

final class SRServiceTests: XCTestCase {
    func testFetchChannels() async throws {
        let mock = SRServiceAPIClientMock()

        let image = MockGenerator.imageURL()
        await mock.setModelResponse(to: .init(channels:
            .init(channel: [
                .init(id: 1, name: "Andys channel", image: image?.absoluteString, color: "ff0000", liveAudio: .init(url: URL(string: "https://sverigesradio.se/topsy/direkt/srapi/132.mp3"))),
            ])
        ))
        let service = SRService(client: mock)

        let channels = try await service.fetchChannels()

        XCTAssertEqual(channels.count, 1)

        XCTAssertEqual(try unwrap(channels.first?.name), "Andys channel")
        XCTAssertEqual(try unwrap(channels.first?.image), try unwrap(image?.absoluteString))
        XCTAssertEqual(try unwrap(channels.first?.liveAudio?.url?.absoluteString), "https://sverigesradio.se/topsy/direkt/srapi/132.mp3")
    }

    func testFetchChannelsFailed() async throws {
        let mock = SRServiceAPIClientMock()

        await mock.setModelErrorResponse(to: TestError.testError)

        let service = SRService(client: mock)
        do {
            _ = try await service.fetchChannels()
            XCTFail("Expected error of type MyError.someError but no error was thrown")
        } catch {
            XCTAssertEqual(error as? TestError, TestError.testError)
        }
    }

    enum TestError: Error {
        case testError
    }
}
