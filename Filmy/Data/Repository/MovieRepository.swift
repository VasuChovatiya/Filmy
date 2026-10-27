import Foundation
import NetworkingKit

/// What the screens need from a movie source. View models depend on this, never on `APIClient`,
/// so tests can pass a spy and the app can run on demo data.
nonisolated protocol MovieRepository: Sendable {
    func movies(in list: MovieList, page: Int) async throws -> Page<Movie>
    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie>
    func movieDetail(id: Int) async throws -> MovieDetail
}

nonisolated struct TMDBMovieRepository: MovieRepository {
    let client: APIClient

    func movies(in list: MovieList, page: Int) async throws -> Page<Movie> {
        MovieMapper.page(from: try await client.send(TMDBEndpoints.list(list, page: page)))
    }

    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        MovieMapper.page(from: try await client.send(TMDBEndpoints.search(query, page: page)))
    }

    func movieDetail(id: Int) async throws -> MovieDetail {
        MovieMapper.detail(from: try await client.send(TMDBEndpoints.detail(id: id)))
    }
}

/// DTO → model conversion. Pure functions, covered by `MovieMapperTests`.
nonisolated enum MovieMapper {
    static let maxCast = 15

    static func page(from dto: MoviePageDTO) -> Page<Movie> {
        Page(
            items: dto.results.map(movie(from:)),
            number: dto.page,
            totalPages: min(dto.totalPages, TMDBConfiguration.maxPage)
        )
    }

    static func movie(from dto: MovieDTO) -> Movie {
        Movie(
            id: dto.id,
            title: dto.title,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            releaseDate: date(from: dto.releaseDate),
            rating: dto.voteAverage ?? 0,
            voteCount: dto.voteCount ?? 0
        )
    }

    static func detail(from dto: MovieDetailDTO) -> MovieDetail {
        let movie = Movie(
            id: dto.id,
            title: dto.title,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            releaseDate: date(from: dto.releaseDate),
            rating: dto.voteAverage ?? 0,
            voteCount: dto.voteCount ?? 0
        )
        let cast = (dto.credits?.cast ?? [])
            .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
            .prefix(maxCast)
            .map { CastMember(id: $0.creditId, name: $0.name, character: $0.character.nilIfEmpty, profilePath: $0.profilePath) }

        return MovieDetail(
            movie: movie,
            tagline: dto.tagline.nilIfEmpty,
            runtimeMinutes: dto.runtime,
            genres: dto.genres.map(\.name),
            cast: Array(cast)
        )
    }

    /// Parses TMDB's "yyyy-MM-dd" as a calendar day in the user's time zone, so a 1 January release
    /// never shows as the previous year (which a UTC-midnight `Date` would in the Americas).
    static func date(from string: String?) -> Date? {
        guard let parts = string?.split(separator: "-").compactMap({ Int($0) }), parts.count == 3 else { return nil }
        return Calendar(identifier: .gregorian).date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}

private extension Optional where Wrapped == String {
    nonisolated var nilIfEmpty: String? {
        guard let self, !self.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return self
    }
}
