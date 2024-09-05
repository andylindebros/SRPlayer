import Foundation
import NukeUI
import SwiftUI

@MainActor struct MediaPlayerView: View {
    @Environment(AudioService.self) var audioService
    let model: AudioService.AudioModel
    let padding: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: padding / 2) {
            HStack(spacing: padding) {
                playerButtonsView
                    .maxWidth(padding * 3)
                VStack(alignment: .leading) {
                    Text(model.title)
                        .font(.callout).bold()
                        .lineLimit(1)
                    playerStateView
                        .font(.callout)
                        .lineLimit(1)
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            }.frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(padding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(model.color ?? .black.opacity(0.9))
        )
        .onTapGesture {
            audioService.isPlaying(model) ? audioService.pause() : audioService.play(withModel: model)
        }
    }

    @ViewBuilder var playerStateView: some View {
        switch audioService.state {
        case .playing:
            if audioService.isPlaying(model) {
                Text("MediaPlayer.isPlaying")
            } else {
                Text("MediaPlayer.TapToStartPlay")
            }
        case let .error(message):
            Text(message)
        default:
            Text("MediaPlayer.TapToStartPlay")
        }
    }

    var playerButtonsView: some View {
        HStack(spacing: 16) {
            if audioService.isPlaying(model) {
                Button(action: {
                    audioService.pause()
                }) {
                    Image(systemName: "pause.circle").resizable().aspectRatio(contentMode: .fit)
                }
            } else {
                Button(action: {
                    audioService.play(withModel: model)
                }) {
                    Image(systemName: "play.circle").resizable().aspectRatio(contentMode: .fit)
                }
            }
        }
    }
}
