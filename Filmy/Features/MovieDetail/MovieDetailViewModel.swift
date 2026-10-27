import Foundation

@Observable
final class MovieDetailViewModel {
    enum Phase {
        case loading
        case loaded(MovieDetail)
        case failed(String)
    }

    /// The summary from the list, shown immediately while the full detail loads.
    let movie: Movie
    private(set) var phase: Phase = .loading

    @ObservationIgnored private let repository: any MovieRepository

    init(movie: Movie, repository: any MovieRepository) {
        self.movie = movie
        self.repository = repository
    }

    var detail: MovieDetail? {
        if case .loaded(let detail) = phase { detail } else { nil }
    }

    /// The freshest copy: detail data once loaded, otherwise the list summary.
    var displayedMovie: Movie {
        detail?.movie ?? movie
    }

    func load() async {
        if case .loaded = phase { return }
        phase = .loading
        do {
            phase = .loaded(try await repository.movieDetail(id: movie.id))
        } catch {
            guard let message = error.userMessage else { return }
            phase = .failed(message)
        }
    }
}
