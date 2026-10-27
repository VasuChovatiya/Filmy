import Foundation
import NetworkingKit
import Testing
@testable import Filmy

@MainActor
struct ErrorUserMessageTests {
    @Test func cancellationHasNoMessage() {
        #expect(CancellationError().userMessage == nil)
        #expect(NetworkError.cancelled.userMessage == nil)
    }

    @Test func networkErrorsUseTheirDescription() {
        let offline = NetworkError.transport(.notConnectedToInternet)
        #expect(offline.userMessage == offline.errorDescription)
        #expect(offline.userMessage != nil)

        let notFound = NetworkError.httpStatus(code: 404, body: Data())
        #expect(notFound.userMessage == notFound.errorDescription)
    }

    @Test func otherErrorsUseTheLocalizedDescription() {
        let error = URLError(.badServerResponse)
        #expect(error.userMessage == error.localizedDescription)
    }
}
