import SwiftUI

@main
@MainActor struct TestAVPlayerApp: App {
    let audioService = AudioService()

    var body: some Scene {
        WindowGroup {
            ChannelListView(
                viewModel: ChannelListView.ViewModel(
                    srService: SRService(
                        client: APIClient()
                    )
                )
            )
            .onAppear {
                activateAudio()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                activateAudio()
            }
            .environment(audioService)
        }
    }

    func activateAudio() {
        do {
            try audioService.activate()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}
