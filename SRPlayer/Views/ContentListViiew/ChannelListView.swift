import NukeUI
import SwiftUI

@MainActor struct ChannelListView: View {
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    @Environment(AudioService.self) var audioService
    @State var viewModel: ChannelListView.ViewModel
    @State var size: CGSize = .zero
    let padding: CGFloat = 16

    var body: some View {
        NavigationView {
            stateView
                .navigationTitle("ChannelListView.Title")
                .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder var stateView: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case let .loaded(channels):
            VStack(spacing: padding) {
                playerView
                contentView(with: channels)
            }
        case let .error(message):
            Text(message)
        }
    }

    func contentView(with channels: [SRService.Channel]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [.init(.flexible(minimum: 100)), .init(.flexible(minimum: 100))], spacing: padding) {
                ForEach(channels) { channel in
                    if let name = channel.name {
                        NavigationLink {
                            ChannelDetailView(viewModel: .init(channel: channel))
                        } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                LazyImage(url: channel.image?.asURL) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    }
                                }
                                Text(name)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .mask(RoundedRectangle(cornerRadius: 4).fill(.black))
                            .padding(.horizontal, padding / 2)
                            .frame(maxHeight: .infinity, alignment: .topLeading)

                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }.padding(padding)
        }
    }

    @ViewBuilder var playerView: some View {
        if let currentModel = audioService.currentModel {
            MediaPlayerView(model: currentModel)
                .measureSize { newSize in
                    if newSize != size {
                        size = newSize
                    }
                }
                .frame(maxHeight: size.height)
                .padding(.horizontal, padding)
        }
    }
}
