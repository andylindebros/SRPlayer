import AVFoundation
import AVKit
import Combine
import Foundation
import MediaPlayer
import SwiftUI
import XCTest

@testable import SRPlayer

actor SRServiceAPIClientMock: APIClientProvider {
    func fetch<Model: Sendable>(_: URLRequest) async throws -> Model where Model: Decodable {
        if let modelErrorResponse {
            throw modelErrorResponse
        }

        guard let response = modelResponse as? Model else {
            throw MockError.unExpectedModel
        }
        return response
    }

    func fetch(_: URLRequest) async throws -> Data {
        if let dataErrorResponse {
            throw dataErrorResponse
        }
        guard let data = UIImage(systemName: "play")?.pngData() else {
            throw MockError.noImageFound
        }
        return data
    }

    // Helper functions
    private var modelResponse: SRService.SRResponse?
    func setModelResponse(to newValue: SRService.SRResponse?) {
        modelResponse = newValue
    }

    private var modelErrorResponse: Error?
    func setModelErrorResponse(to newValue: Error?) {
        modelErrorResponse = newValue
    }

    private var dataErrorResponse: Error?
    func setDataErrorResponse(to newValue: Error?) {
        dataErrorResponse = newValue
    }
}

// MARK: nested mock models

extension SRServiceAPIClientMock {
    enum MockError: Error {
        case unExpectedModel
        case noImageFound
    }
}

// MARK: SRServiceMock

actor SRServiceMock: SRServiceProvider {
    func fetchChannels() async throws -> [SRService.Channel] {
        if let error {
            throw error
        }
        return response
    }

    private var response: [SRService.Channel] = []
    func setResponse(to newValue: [SRService.Channel]) async {
        response = newValue
    }

    private var error: Error?
    func setError(to error: Error?) async {
        self.error = error
    }
}

@Observable
final class MPNowPlayingInfoCenterMock: MPNowPlayingInfoCenterProvider {
    var nowPlayingInfo: [String: Any]? {
        didSet {
            changeCount += 1
        }
    }

    private(set) var changeCount = 0
}

actor Observer<Model>: ObservableObject {
    init() {}
    @Published private(set) var value: Model?

    func setValue(to newValue: Model?) async {
        value = newValue
    }
}

actor MPRemoteCommandMock: MPRemoteCommandProvider {
    @discardableResult nonisolated func addTarget(handler _: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) -> Any {
        Task {
            await add()
        }
    }

    private var eventCount = 0

    func eventCount() async -> Int {
        eventCount
    }

    func add() async {
        eventCount += 1
    }

    func reset() async {
        eventCount = 0
    }
}

struct MPRemoteCommandCenterMock: MPRemoteCommandCenterProvider {
    let pause = MPRemoteCommandMock()
    let play = MPRemoteCommandMock()
    var customPauseCommand: MPRemoteCommandProvider {
        pause
    }

    var customPlayCommand: MPRemoteCommandProvider {
        play
    }
}

actor NotificationCenterMock: NotificationCenterProvider {
    nonisolated func publisher(for _: Notification.Name, object _: AnyObject?) -> NotificationCenter.Publisher {
        .init(center: .default, name: .AVPlayerItemDidPlayToEndTime)
    }
}

actor AVAudioSessionMock: AVAudioSessionProvider, ObservableObject {
    nonisolated func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
        Task {
            await addEvent(event: .setCategory(category: category, mode: mode, options: options))
        }
    }

    nonisolated func setActive(_ isActive: Bool, options: AVAudioSession.SetActiveOptions) throws {
        Task {
            await addEvent(event: .setActive(isActive: isActive, options: options))
        }
    }

    // Properties used by the tests to verify expected events

    @Published private(set) var events = [Event]()

    func addEvent(event: Event) async {
        events.append(event)
    }

    func getEvents() async -> [Event] {
        events
    }

    func reset() {
        events = []
    }

    enum Event {
        case setCategory(category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)
        case setActive(isActive: Bool, options: AVAudioSession.SetActiveOptions)
    }
}
