import Foundation
import Testing
@testable import Filmy

@MainActor
struct MovieListViewModelTests {
    @Test func firstLoadShowsPageOne() async {
        let repository = StubMovieRepository(list: Fixtures.pages(count: 25, pageSize: 10))
        let viewModel = MovieListViewModel(list: .popular, repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.movies.map(\.id) == Array(1...10))
        #expect(viewModel.hasMore)
        #expect(await repository.listRequests == [1])
    }

    @Test func loadIfNeededOnlyLoadsOnce() async {
        let repository = StubMovieRepository(list: Fixtures.pages(count: 25, pageSize: 10))
        let viewModel = MovieListViewModel(list: .popular, repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(await repository.listRequests == [1])
    }

    @Test func loadMoreAppendsUntilTheLastPage() async {
        let repository = StubMovieRepository(list: Fixtures.pages(count: 25, pageSize: 10))
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()

        await viewModel.loadMore()
        await viewModel.loadMore()

        #expect(viewModel.movies.map(\.id) == Array(1...25))
        #expect(!viewModel.hasMore)
        #expect(await repository.listRequests == [1, 2, 3])
    }

    @Test func stopsRequestingAfterTheLastPage() async throws {
        let repository = StubMovieRepository(list: Fixtures.pages(count: 10, pageSize: 10))
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()

        let last = try #require(viewModel.movies.last)
        await viewModel.loadMoreIfNeeded(after: last)

        #expect(!viewModel.hasMore)
        #expect(await repository.listRequests == [1])
    }

    @Test func prefetchesOnlyNearTheEnd() async throws {
        let repository = StubMovieRepository(list: Fixtures.pages(count: 40, pageSize: 20))
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()

        await viewModel.loadMoreIfNeeded(after: viewModel.movies[0])
        #expect(await repository.listRequests == [1])

        let nearEnd = viewModel.movies[viewModel.movies.count - MovieListViewModel.prefetchThreshold]
        await viewModel.loadMoreIfNeeded(after: nearEnd)
        #expect(await repository.listRequests == [1, 2])
        #expect(viewModel.movies.count == 40)
    }

    @Test func loadMoreFailureKeepsMoviesAndRetrySucceeds() async {
        let failing = FailureSwitch()
        let pages = Fixtures.pages(count: 30, pageSize: 10)
        let repository = StubMovieRepository(list: { page in
            if failing.isOn { throw Fixtures.serverError }
            return pages(page)
        })
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()

        failing.isOn = true
        await viewModel.loadMore()

        #expect(viewModel.movies.count == 10)
        #expect(viewModel.loadMoreError != nil)
        #expect(viewModel.phase == .loaded)
        #expect(!viewModel.isLoadingMore)

        failing.isOn = false
        await viewModel.loadMore()

        #expect(viewModel.loadMoreError == nil)
        #expect(viewModel.movies.map(\.id) == Array(1...20))
    }

    @Test func pausesPrefetchAfterAFailure() async throws {
        let failing = FailureSwitch()
        let pages = Fixtures.pages(count: 30, pageSize: 10)
        let repository = StubMovieRepository(list: { page in
            if failing.isOn { throw Fixtures.serverError }
            return pages(page)
        })
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()
        failing.isOn = true
        await viewModel.loadMore()

        // Scrolling must not hammer a failing endpoint; only the footer's Try Again retries.
        let last = try #require(viewModel.movies.last)
        await viewModel.loadMoreIfNeeded(after: last)

        #expect(await repository.listRequests == [1, 2])
    }

    @Test func firstPageFailureShowsTheError() async {
        let repository = StubMovieRepository(list: { _ in throw Fixtures.serverError })
        let viewModel = MovieListViewModel(list: .popular, repository: repository)

        await viewModel.loadIfNeeded()

        guard case .failed(let message) = viewModel.phase else {
            Issue.record("Expected .failed, got \(viewModel.phase)")
            return
        }
        #expect(!message.isEmpty)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func cancellationIsNotShownAsAnError() async {
        let repository = StubMovieRepository(list: { _ in throw CancellationError() })
        let viewModel = MovieListViewModel(list: .popular, repository: repository)

        await viewModel.loadIfNeeded()

        #expect(viewModel.phase == .loading)
    }

    @Test func reloadStartsAgainFromPageOne() async {
        let repository = StubMovieRepository(list: Fixtures.pages(count: 30, pageSize: 10))
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()
        await viewModel.loadMore()

        await viewModel.reload()

        #expect(viewModel.movies.map(\.id) == Array(1...10))
        #expect(await repository.listRequests == [1, 2, 1])
    }

    @Test func refreshFailureKeepsTheCurrentMovies() async {
        let failing = FailureSwitch()
        let pages = Fixtures.pages(count: 30, pageSize: 10)
        let repository = StubMovieRepository(list: { page in
            if failing.isOn { throw Fixtures.serverError }
            return pages(page)
        })
        let viewModel = MovieListViewModel(list: .popular, repository: repository)
        await viewModel.loadIfNeeded()

        failing.isOn = true
        await viewModel.reload()

        #expect(viewModel.phase == .loaded)
        #expect(viewModel.movies.count == 10)
        #expect(viewModel.loadMoreError != nil)
    }
}
