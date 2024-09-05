import Foundation
import NiceToHave
@testable import SRPlayer
import XCTest

final class ChannelListViewModelTests: XCTestCase {
    func testLoad() async throws {
        let mock = SRServiceMock()
        let viewModel = await ChannelListView.ViewModel(srService: mock)

        await mock.setResponse(to: [.init(id: 1, name: "some name")])

        await viewModel.load()

        await wait(for: \.state, in: viewModel, toBeTrue: { $0.channels != nil })

        let amountOfChannels = await viewModel.state.channels?.count
        XCTAssertEqual(try unwrap(amountOfChannels), 1)
    }
}
