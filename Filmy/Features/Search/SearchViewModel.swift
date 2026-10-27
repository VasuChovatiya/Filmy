import Foundation
import NetworkingKit

/// Debounced, paginated movie search.
///
/// Each keystroke cancels the pending search and starts a new debounce timer, so typing "dune"
/// sends one request, not four. A newer query also cancels the older request in flight.
@Observable
final class SearchViewModel {
    enum Phase: Equatable {
        /// Nothing typed yet (or fewer than `minimumQueryLength` characters).
        case prompt
        case loading
        case results
        case empty(String)
        case failed(String)
    }

    static let minimumQueryLength = 2

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            scheduleSearch()
        }
    }

    private(set) var phase: Phase = .prompt
    private(set) var results: [Movie] = []
    private(set) var hasMore = false
    /// True while a newer query is loading but older results are still on screen.
    private(set) var isSearching = false
    private(set) var isLoadingMore = false
    private(set) var loadMoreError: String?

    /// Exposed so tests can await the debounced search instead of sleeping.
    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?
    @ObservationIgnored private var paginator: Paginator<Movie>?
    @ObservationIgnored private var searchedTerm: String?
    @ObservationIgnored private let repository: any MovieRepository
    @ObservationIgnored private let debounce: Duration

    init(repository: any MovieRepository, debounce: Duration = .milliseconds(400)) {
        self.repository = repository
        self.debounce = debounce
    }

    private var term: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func retry() {
        searchedTerm = nil
        scheduleSearch(debounced: false)
    }

    func loadMoreIfNeeded(after movie: Movie) async {
        guard hasMore, !isLoadingMore, loadMoreError == nil, let paginator,
              let index = results.firstIndex(where: { $0.id == movie.id }),
              index >= results.count - MovieListViewModel.prefetchThreshold else { return }
        await loadMore(using: paginator)
    }

    func loadMore() async {
        guard let paginator else { return }
        await loadMore(using: paginator)
    }

    // MARK: - Private

    private func scheduleSearch(debounced: Bool = true) {
        searchTask?.cancel()
        let term = self.term

        guard term.count >= Self.minimumQueryLength else {
            cancelInFlightSearch()
            searchedTerm = nil
            results = []
            hasMore = false
            isSearching = false
            phase = .prompt
            return
        }
        // "dune" → "dune " shouldn't refetch.
        guard term != searchedTerm else { return }
        // Once another term is pending, the current results no longer match the field.
        searchedTerm = nil

        if results.isEmpty {
            phase = .loading
        } else {
            isSearching = true
        }

        let delay = debounced ? debounce : .zero
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.runSearch(term)
        }
    }

    private func runSearch(_ term: String) async {
        cancelInFlightSearch()
        let repository = self.repository
        let paginator = Paginator<Movie> { page in
            try await repository.searchMovies(matching: term, page: page)
        }
        self.paginator = paginator
        searchedTerm = term
        loadMoreError = nil

        do {
            let snapshot = try await paginator.loadNextPage()
            guard self.paginator === paginator else { return }
            results = snapshot.items
            hasMore = snapshot.hasMore
            phase = snapshot.items.isEmpty ? .empty(term) : .results
        } catch {
            guard self.paginator === paginator, let message = error.userMessage else { return }
            searchedTerm = nil
            results = []
            phase = .failed(message)
        }
        isSearching = false
    }

    private func loadMore(using paginator: Paginator<Movie>) async {
        isLoadingMore = true
        loadMoreError = nil
        defer { isLoadingMore = false }
        do {
            let snapshot = try await paginator.loadNextPage()
            guard self.paginator === paginator else { return }
            results = snapshot.items
            hasMore = snapshot.hasMore
        } catch {
            guard self.paginator === paginator else { return }
            loadMoreError = error.userMessage
        }
    }

    /// Resetting the old paginator cancels its URLSession task, so stale responses never arrive.
    private func cancelInFlightSearch() {
        guard let old = paginator else { return }
        paginator = nil
        Task { await old.reset() }
    }
}
