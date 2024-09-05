import AVFoundation
import Foundation

extension ChannelDetailView {
    @MainActor @Observable
    final class ViewModel: Sendable {
        init(channel: SRService.Channel) {
            self.channel = channel
        }

        let channel: SRService.Channel

        var audioModel: AudioService.AudioModel? {
            AudioService.AudioModel.create(from: channel)
        }
    }
}
