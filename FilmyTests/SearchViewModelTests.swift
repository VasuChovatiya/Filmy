import Foundation
import NetworkingKit
import Testing
@testable import Filmy

@MainActor
struct SearchViewModelTests {
    private static let debounce: Duration = .milliseconds(30)

    private func makeViewModel(_ repository: StubMovieRepository) -> SearchViewModel {
        SearchViewModel(repository: repository, debounce: Self.debounce)
    }

    nonisolated private static func results(for query: String, page: Int) -> Page<Movie> {
        Page(items: [Movie.fixture(id: page * 100 + query.count, title: query)], number: page, totalPages: 3)
    }

    @Test func typingQuicklySendsOneRequestForTheFinalTerm() async {
        let repository = StubMovieRepository(search: { Self.results(for: $0, page: $1) })
        let viewModel = makeViewModel(repository)

        viewModel.query = "du"
        viewModel.query = "dun"
        viewModel.query = "dune"
        await viewModel.searchTask?.value

        #expect(await repository.searchRequests == [.init(query: "dune", page: 1)])
        #expect(viewModel.phase == .results)
        #expect(viewModel.results.map(\.title) == ["dune"])
    }

    @Test func shortQueriesDoNotSearch() async {
        let repository = StubMovieRepository(search: { Self.results(for: $0, page: $1) })
        let viewModel = makeViewModel(repository)

        viewModel.query = "d"
        try? await Task.sleep(for: Self.debounce * 3)

        #expect(viewModel.phase == .prompt)
        #expect(await repository.searchRequests.isEmpty)
    }

    @Test func clearingTheQueryClearsResults() async {
        let repository = StubMovieRepository(search: { Self.results(for: $0, page: $1) })
        let viewModel = makeViewModel(repository)
        viewModel.query = "dune"
        await viewModel.searchTask?.value

        viewModel.query = ""

        #expect(viewModel.phase == .prompt)
        #expect(viewModel.results.isEmpty)
        #expect(!viewModel.hasMore)
    }

    @Test func trailingWhitespaceDoesNotRefetch() async {
        let repository = StubMovieRepository(search: { Self.results(for: $0, page: $1) })
        let viewModel = makeViewModel(repository)
        viewModel.query = "dune"
        await viewModel.searchTask?.value

        viewModel.query = "dune "
        await viewModel.searchTask?.value

        #expect(await repository.searchRequests.count == 1)
    }

    @Test func newQueryKeepsOldResultsVisibleWhileLoading() async {
        let repository = StubMovieRepository(search: { Self.results(for: $0, page: $1) })
        let viewModel = makeViewModel(repository)
        viewModel.query = "dune"
        await viewModel.searchTask?.value

        viewModel.query = "alien"
        #expect(viewModel.isSearching)
        #expect(viewModel.results.map(\.title) == ["dune"])

        await viewModel.searchTask?.value
        #expect(!viewModel.isSearching)
        #expect(viewModel.results.map(\.title) == ["alien"])
    }

    @Test func noMatchesShowsTheEmptyState() async {
        let repository = StubMovieRepository()
        let viewModel = makeViewModel(repository)

        viewModel.query = "zzzz"
        await viewModel.searchTask?.value

        #expect(viewModel.phase == .empty("zzzz"))
    }

    @Test func failureThenRetry() async {
        let failing = FailureSwitch(true)
        let repository = StubMovieRepository(search: { query, page in
            if failing.isOn { throw Fixtures.serverError }
            return Self.results(for: query, page: page)
        })
        let viewModel = makeViewModel(repository)

        viewModel.query = "dune"
        await viewModel.searchTask?.value
        guard case .failed = viewModel.phase else {
            Issue.record("Expected .failed, got \(viewModel.phase)")
            return
        }

        failing.isOn = false
        viewModel.retry()
        await viewModel.searchTask?.value

        #expect(viewModel.phase == .results)
        #expect(await repository.searchRequests.count == 2)
    }

    @Test func loadMoreRequestsTheNextPageOfTheSameTerm() async {
        let repository = StubMovieRepository(search: { Self.results(for: $0, page: $1) })
        let viewModel = makeViewModel(repository)
        viewModel.query = "dune"
        await viewModel.searchTask?.value

        await viewModel.loadMore()

        #expect(await repository.searchRequests == [.init(query: "dune", page: 1), .init(query: "dune", page: 2)])
        #expect(viewModel.results.count == 2)
        #expect(viewModel.hasMore)
    }
}
