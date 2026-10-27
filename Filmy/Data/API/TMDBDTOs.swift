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
    /// Present because requests use `append_to_response=credits`.
    let credits: CreditsDTO?
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
