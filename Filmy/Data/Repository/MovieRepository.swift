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
    /// ISO 3166-1 country used to pick watch providers.
    var region = Locale.current.region?.identifier ?? "US"

    func movies(in list: MovieList, page: Int) async throws -> Page<Movie> {
        MovieMapper.page(from: try await client.send(TMDBEndpoints.list(list, page: page)))
    }

    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        MovieMapper.page(from: try await client.send(TMDBEndpoints.search(query, page: page)))
    }

    func movieDetail(id: Int) async throws -> MovieDetail {
        MovieMapper.detail(from: try await client.send(TMDBEndpoints.detail(id: id)), region: region)
    }
}

/// DTO → model conversion. Pure functions, covered by `MovieMapperTests`.
nonisolated enum MovieMapper {
    static let maxCast = 15
    static let maxVideos = 10
    static let maxRecommendations = 20

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

    static func detail(from dto: MovieDetailDTO, region: String) -> MovieDetail {
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
            cast: Array(cast),
            videos: videos(from: dto.videos?.results ?? []),
            recommendations: Array((dto.recommendations?.results ?? []).lazy.filter { $0.id != dto.id }.map(movie(from:)).prefix(maxRecommendations)),
            watchOptions: watchOptions(from: dto.watchProviders, region: region)
        )
    }

    /// YouTube only (the app opens them there), ordered trailers first, official first, newest first.
    static func videos(from dtos: [VideoDTO]) -> [Video] {
        let sorted = dtos
            .filter { $0.site == "YouTube" && !$0.key.isEmpty }
            .map { (dto: $0, kind: Video.Kind(tmdbType: $0.type)) }
            .sorted { a, b in
                if a.kind != b.kind { return a.kind < b.kind }
                let aOfficial = a.dto.official ?? false
                let bOfficial = b.dto.official ?? false
                if aOfficial != bOfficial { return aOfficial }
                // ISO 8601 strings sort chronologically.
                return (a.dto.publishedAt ?? "") > (b.dto.publishedAt ?? "")
            }
        return sorted.prefix(maxVideos).map {
            Video(id: $0.dto.key, name: $0.dto.name, kind: $0.kind, isOfficial: $0.dto.official ?? false)
        }
    }

    static func watchOptions(from dto: WatchProvidersDTO?, region: String) -> WatchOptions? {
        guard let entry = dto?.results[region.uppercased()] else { return nil }
        let options = WatchOptions(
            region: region.uppercased(),
            link: entry.link.flatMap(URL.init(string:)),
            stream: providers(from: (entry.flatrate ?? []) + (entry.free ?? []) + (entry.ads ?? [])),
            rent: providers(from: entry.rent ?? []),
            buy: providers(from: entry.buy ?? [])
        )
        return options.isEmpty ? nil : options
    }

    /// Ordered by TMDB's display priority, each service once.
    private static func providers(from dtos: [ProviderDTO]) -> [WatchProvider] {
        var seen = Set<Int>()
        return dtos
            .sorted { ($0.displayPriority ?? .max) < ($1.displayPriority ?? .max) }
            .filter { seen.insert($0.providerId).inserted }
            .map { WatchProvider(id: $0.providerId, name: $0.providerName, logoPath: $0.logoPath) }
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
