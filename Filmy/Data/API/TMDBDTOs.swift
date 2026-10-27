import Foundation

// Wire formats for the TMDB v3 API. Keys are snake_case on the wire; the decoder converts them.
// Kept separate from the app's models so API quirks (empty date strings, missing fields) stay here.

nonisolated struct MoviePageDTO: Decodable, Sendable {
    let page: Int
    let results: [MovieDTO]
    let totalPages: Int
    let totalResults: Int
}

nonisolated struct MovieDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    /// "2024-03-01", "" for unknown, or absent.
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
}

nonisolated struct MovieDetailDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let overview: String?
    let tagline: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let voteCount: Int?
    let genres: [GenreDTO]
    // The rest arrive through `append_to_response`.
    let credits: CreditsDTO?
    let videos: VideoListDTO?
    let recommendations: MoviePageDTO?
    let watchProviders: WatchProvidersDTO?

    /// Listed by hand only because "watch/providers" isn't a snake_case key. The decoder still
    /// converts the others, so their raw values are the camelCase names.
    enum CodingKeys: String, CodingKey {
        case id, title, overview, tagline, posterPath, backdropPath, releaseDate, runtime
        case voteAverage, voteCount, genres, credits, videos, recommendations
        case watchProviders = "watch/providers"
    }
}

nonisolated struct VideoListDTO: Decodable, Sendable {
    let results: [VideoDTO]
}

nonisolated struct VideoDTO: Decodable, Sendable {
    let key: String
    let name: String
    /// "YouTube" or "Vimeo".
    let site: String
    /// "Trailer", "Teaser", "Clip", "Featurette", "Behind the Scenes", "Bloopers"...
    let type: String
    let official: Bool?
    let publishedAt: String?
}

nonisolated struct WatchProvidersDTO: Decodable, Sendable {
    /// Keyed by ISO 3166-1 country code.
    let results: [String: RegionProvidersDTO]
}

nonisolated struct RegionProvidersDTO: Decodable, Sendable {
    /// TMDB's watch page for the region, which links out to each service.
    let link: String?
    let flatrate: [ProviderDTO]?
    let free: [ProviderDTO]?
    let ads: [ProviderDTO]?
    let rent: [ProviderDTO]?
    let buy: [ProviderDTO]?
}

nonisolated struct ProviderDTO: Decodable, Sendable {
    let providerId: Int
    let providerName: String
    let logoPath: String?
    let displayPriority: Int?
}

nonisolated struct GenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

nonisolated struct CreditsDTO: Decodable, Sendable {
    let cast: [CastDTO]
}

nonisolated struct CastDTO: Decodable, Sendable {
    let id: Int
    let creditId: String
    let name: String
    let character: String?
    let profilePath: String?
    let order: Int?
}
