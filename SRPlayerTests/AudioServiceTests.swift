import AVFoundation
import AVKit
import Combine
import Foundation
import MediaPlayer
import NiceToHave
@testable import SRPlayer
import XCTest

final class AudioServiceTests: XCTestCase {
    func testActivate() async throws {
        let session = AVAudioSessionMock()
        let notificationCenter = NotificationCenterMock()
        let remoteCommandCenter = MPRemoteCommandCenterMock()
        let nowPlayingInfoCenter = MPNowPlayingInfoCenterMock()
        let apiClient = SRServiceAPIClientMock()

        let audioService = await AudioService(
            session: session,
            notificationCenter: notificationCenter,
            remoteCommandCenter: remoteCommandCenter,
            nowPlayingInfoCenter: nowPlayingInfoCenter,
            client: apiClient
        )

        try await audioService.activate()

        // Check that AVSession was correctly activated

        // Wait for AVSessionMock to receive expected events
        try await AsyncObserver().wait(for: session.$events, toBeTrue: { $0.count == 2 })

        let sessionEvents = await session.getEvents()

        guard case let AVAudioSessionMock.Event.setCategory(category, mode, options) = try unwrap(sessionEvents.first) else {
            return XCTFail("Expected session event did not occured")
        }

        XCTAssertEqual(category, .playback)
        XCTAssertEqual(mode, .default)
        XCTAssertEqual(options, [])

        guard case let AVAudioSessionMock.Event.setActive(isActive, options) = try unwrap(sessionEvents.last) else {
            return XCTFail("Expected session event did not occured sessionEvents.count: \(sessionEvents.count)")
        }

        XCTAssertTrue(isActive)
        XCTAssertEqual(options, [.notifyOthersOnDeactivation])

        // Check that nowPlayingInfo was not updated since we hav't given the service anything to play yet
        XCTAssertNil(nowPlayingInfoCenter.nowPlayingInfo)

        // The state should be idle
        let state = await audioService.state
        XCTAssertEqual(state, .idle)

        // test that remotecontrols was invoked
        var eventCount = await remoteCommandCenter.pause.eventCount()
        XCTAssertEqual(eventCount, 1)
        eventCount = await remoteCommandCenter.play.eventCount()
        XCTAssertEqual(eventCount, 1)
    }

    func testPlayPause() async throws {
        let session = AVAudioSessionMock()
        let notificationCenter = NotificationCenterMock()
        let remoteCommandCenter = MPRemoteCommandCenterMock()
        let nowPlayingInfoCenter = MPNowPlayingInfoCenterMock()
        let apiClient = SRServiceAPIClientMock()

        let audioService = await AudioService(
            session: session,
            notificationCenter: notificationCenter,
            remoteCommandCenter: remoteCommandCenter,
            nowPlayingInfoCenter: nowPlayingInfoCenter,
            client: apiClient
        )

        let model = try AudioService.AudioModel(url: unwrap("/scheduledepisodes?channelid=132".asURL), title: "123", artist: "the artist", imageURL: nil, color: .blue)

        await audioService.play(withModel: model)

        await wait(for: \.changeCount, in: nowPlayingInfoCenter, toBeTrue: { _ in
            nowPlayingInfoCenter.nowPlayingInfo != nil
        })

        XCTAssertEqual(try unwrap(nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String), model.title)

        var state = await audioService.state
        XCTAssertEqual(state, .playing)

        await audioService.pause()

        state = await audioService.state
        XCTAssertEqual(state, .idle)
    }
}
