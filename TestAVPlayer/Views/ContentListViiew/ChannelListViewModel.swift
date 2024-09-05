import Foundation
import SwiftUI

extension ChannelListView {
    @MainActor @Observable
    class ViewModel {
        init(srService: SRServiceProvider) {
            self.srService = srService
        }

        private let srService: SRServiceProvider
        private(set) var state: ViewState = .loading

        func load() async {
            state = .loading

            do {
                state = try await .loaded(srService.fetchChannels())
            } catch {
                print("❌ failed to load with error", error)
                state = .error(message: error.localizedDescription)
            }
        }
    }
}

extension ChannelListView {
    enum ViewState: Equatable {
        case loading
        case loaded([SRService.Channel])
        case error(message: String)

        var channels: [SRService.Channel]? {
            if case let .loaded(array) = self {
                return array
            }
            return nil
        }
    }
}
