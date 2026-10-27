import Foundation
import NetworkingKit

/// One paginated movie list (Trending, Popular...). Loads page 1 on first appearance and the next
/// page when the user scrolls near the end.
@Observable
final class MovieListViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    /// Start loading the next page when this many items are left to scroll.
    static let prefetchThreshold = 6

    let list: MovieList
    private(set) var phase: Phase = .idle
    private(set) var movies: [Movie] = []
    private(set) var hasMore = false
    private(set) var isLoadingMore = false
    private(set) var loadMoreError: String?

    @ObservationIgnored private let paginator: Paginator<Movie>

    init(list: MovieList, repository: any MovieRepository) {
        self.list = list
        paginator = Paginator { page in
            try await repository.movies(in: list, page: page)
        }
    }

    func loadIfNeeded() async {
        guard phase == .idle else { return }
        await reload()
    }

    /// First load and pull-to-refresh. Keeps the current movies on screen until the new page arrives.
    func reload() async {
        if movies.isEmpty {
            phase = .loading
        }
        loadMoreError = nil
        await paginator.reset()
        do {
            apply(try await paginator.loadNextPage())
            phase = .loaded
        } catch {
            guard let message = error.userMessage else { return }
            if movies.isEmpty {
                phase = .failed(message)
            } else {
                loadMoreError = message
            }
        }
    }

    func loadMoreIfNeeded(after movie: Movie) async {
        guard hasMore, !isLoadingMore, loadMoreError == nil,
              let index = movies.firstIndex(where: { $0.id == movie.id }),
              index >= movies.count - Self.prefetchThreshold else { return }
        await loadMore()
    }

    func loadMore() async {
        isLoadingMore = true
        loadMoreError = nil
        defer { isLoadingMore = false }
        do {
            apply(try await paginator.loadNextPage())
        } catch {
            loadMoreError = error.userMessage
        }
    }

    private func apply(_ snapshot: PaginationSnapshot<Movie>) {
        movies = snapshot.items
        hasMore = snapshot.hasMore
    }
}
