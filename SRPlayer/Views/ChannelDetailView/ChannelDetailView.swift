import Foundation
import NiceToHave
import NukeUI
import SwiftUI

@MainActor struct ChannelDetailView: View {
    @State var viewModel: ChannelDetailView.ViewModel
    @State var size: CGSize = .zero

    let padding: CGFloat = 16

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: padding) {
                playerView
                if let url = viewModel.channel.image?.asURL {
                    imageView(url: url)
                        .frame(size.width)
                }
                if let text = viewModel.channel.tagline {
                    Text(text)
                        .font(.body)
                        .padding(padding)

                }

            }.frame(maxWidth: .infinity)
                .measureSize(onChange: { newSize in
                    size = newSize
                })
                .padding(.horizontal, padding)
        }
        .guard(viewModel.channel.color?.asColor.opacity(0.7)) { color, view in
            view.background(color)
        }
    }

    func imageView(url: URL?) -> some View {
        GeometryReader { geo in
            LazyImage(url: url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.frame(in: .local).width, height: geo.frame(in: .local).height)
                }
            }.mask {
                Rectangle().fill(.black).frame(width: geo.frame(in: .local).width, height: geo.frame(in: .local).height)
            }
        }
    }

    var imageRequest: ImageRequest? {
        guard let imageURL = viewModel.channel.image?.asURL else { return nil }
        let urlRequest = URLRequest(url: imageURL, timeoutInterval: 10)
        return ImageRequest(urlRequest: urlRequest)
    }

    @ViewBuilder var playerView: some View {
        if let audioModel = viewModel.audioModel {
            MediaPlayerView(
                model: audioModel
            )
        }
    }
}
