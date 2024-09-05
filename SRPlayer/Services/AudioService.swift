import AVFoundation
import AVKit
import Combine
import Foundation
import MediaPlayer
import NiceToHave
import SwiftUI

// MARK: AudioService

@MainActor @Observable final class AudioService: Sendable {
    init(
        session: AVAudioSessionProvider = AVAudioSession.sharedInstance(),
        notificationCenter: NotificationCenterProvider = NotificationCenter.default,
        remoteCommandCenter: MPRemoteCommandCenterProvider = MPRemoteCommandCenter.shared(),
        nowPlayingInfoCenter: MPNowPlayingInfoCenterProvider = MPNowPlayingInfoCenter.default(),
        client: APIClientProvider = APIClient()
    ) {
        self.session = session
        self.client = client
        self.notificationCenter = notificationCenter
        self.remoteCommandCenter = remoteCommandCenter
        self.nowPlayingInfoCenter = nowPlayingInfoCenter
    }

    private(set) var currentModel: AudioModel?
    private(set) var state: PlayerState = .idle

    private let session: AVAudioSessionProvider
    private let notificationCenter: NotificationCenterProvider
    private let remoteCommandCenter: MPRemoteCommandCenterProvider
    private var nowPlayingInfoCenter: MPNowPlayingInfoCenterProvider
    private var player: AVPlayer?
    private let client: APIClientProvider
    private var notificationCenterSubscribers = Set<AnyCancellable>()

    func activate() throws {
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try setSessionIsActive(to: true)
            setupRemoteControls()

            Task { [weak self] in
                await self?.updateNowPlayingInfo()
            }

            updateState()
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    func play(withModel model: AudioModel) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let playerItem = AVPlayerItem(url: model.url)

        if let player {
            player.replaceCurrentItem(with: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
        }

        currentModel = model

        Task { [weak self] in
            await self?.resume()
        }
    }

    func pause() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        player?.pause()
        updateState()
    }

    func isPlaying(_ model: AudioModel) -> Bool {
        currentModel == model && state == .playing
    }
}

// MARK: Private methods

private extension AudioService {
    private func resume() async {
        player?.play()
        updateState()
        await updateNowPlayingInfo()
    }

    func updateState() {
        self.state = player?.isPlaying == true ? .playing : .idle
    }

    func fetchArtworkImage() async -> UIImage? {
        guard
            let imageURL = currentModel?.imageURL,
            let data = try? await client.fetch(.init(url: imageURL)),
            let image = UIImage(data: data)
        else {
            return nil
        }

        return image
    }

    func updateNowPlayingInfo() async {
        guard let player, let currentModel else { 
            return
        }
        let image: UIImage? = await fetchArtworkImage()
        let info: [String: Any] = Dictionary {
            [MPMediaItemPropertyTitle: currentModel.title]
            if let artist = currentModel.artist {
                [MPMediaItemPropertyArtist: artist]
            }
            [MPNowPlayingInfoPropertyIsLiveStream: true]
            [MPNowPlayingInfoPropertyPlaybackRate: player.rate]
            [MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue]
            if let image {
                [MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
                    image
                }]
            }
        }
        nowPlayingInfoCenter.nowPlayingInfo = info
    }

    func setupRemoteControls() {
        remoteCommandCenter.customPauseCommand.addTarget { [weak self] _ in
            self?.pause()

            return .success
        }

        remoteCommandCenter.customPlayCommand.addTarget { _ in
            Task { [weak self] in
                await self?.resume()
            }
            return .success
        }
    }

    func setSessionIsActive(to newValue: Bool) throws {
        try session.setActive(newValue, options: .notifyOthersOnDeactivation)
    }

    func listenForPlayerEvents() {
        notificationCenter.publisher(for: .AVPlayerItemDidPlayToEndTime, object: nil).sink { _ in
            Task { [weak self] in
                try? self?.setSessionIsActive(to: false)
                self?.currentModel = nil
                self?.updateState()
            }
        }.store(in: &notificationCenterSubscribers)
    }
}

// MARK: Nested Models

extension AudioService {
    enum PlayerState: Sendable, Equatable {
        case idle
        case loading
        case playing
        case error(String)
    }

    struct AudioModel: Equatable {
        let url: URL
        let title: String
        let artist: String?
        let imageURL: URL?
        let color: Color?

        static func create(from channel: SRService.Channel) -> AudioService.AudioModel? {
            guard
                let liveAudioURL = channel.liveAudio?.url,
                let title = channel.name

            else { return nil }

            return .init(url: liveAudioURL, title: title, artist: nil, imageURL: channel.image?.asURL, color: channel.color?.asColor)
        }
    }
}

// MARK: Dependencies and external extensions

protocol AVAudioSessionProvider: Sendable {
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws

    func setActive(_ isActive: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: AVAudioSessionProvider, @unchecked Sendable {}

private extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

protocol MPNowPlayingInfoCenterProvider {
    var nowPlayingInfo: [String: Any]? { get set }
}
extension MPNowPlayingInfoCenter: MPNowPlayingInfoCenterProvider {}

protocol MPRemoteCommandCenterProvider {
    var customPauseCommand: any MPRemoteCommandProvider { get }
    var customPlayCommand: any MPRemoteCommandProvider { get }
}

protocol MPRemoteCommandProvider {
    @discardableResult func addTarget(handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) -> Any
}

extension MPRemoteCommand: MPRemoteCommandProvider {}

// Since playCommand and pauseCommand cannot be mocked we need to extend MPRemoteCommand to conform to MPRemoteCommandProvider and wrap a computer value around it
extension MPRemoteCommandCenter: MPRemoteCommandCenterProvider {
    var customPlayCommand: any MPRemoteCommandProvider {
        playCommand
    }

    var customPauseCommand: MPRemoteCommandProvider {
        pauseCommand
    }
}

protocol NotificationCenterProvider {
    func publisher(for name: Notification.Name, object: AnyObject?) -> NotificationCenter.Publisher
}
extension NotificationCenter: NotificationCenterProvider {}
