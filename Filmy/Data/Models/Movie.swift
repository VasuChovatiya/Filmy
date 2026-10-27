import Foundation

nonisolated struct Movie: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: Date?
    /// TMDB vote average, 0...10.
    let rating: Double
    let voteCount: Int

    var releaseYear: String? {
        releaseDate?.formatted(.dateTime.year())
    }

    /// Unreleased or brand-new titles have no meaningful score yet.
    var hasRating: Bool {
        voteCount > 0
    }

    func posterURL(_ size: TMDBImageSize = .poster) -> URL? {
        TMDBConfiguration.imageURL(path: posterPath, size: size)
    }

    func backdropURL(_ size: TMDBImageSize = .backdrop) -> URL? {
        TMDBConfiguration.imageURL(path: backdropPath, size: size)
    }
}

nonisolated struct MovieDetail: Hashable, Sendable {
    let movie: Movie
    let tagline: String?
    let runtimeMinutes: Int?
    let genres: [String]
    let cast: [CastMember]

    /// "2h 15m", "48m", or nil when TMDB has no runtime yet.
    var formattedRuntime: String? {
        guard let runtimeMinutes, runtimeMinutes > 0 else { return nil }
        let hours = runtimeMinutes / 60
        let minutes = runtimeMinutes % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(minutes)m"
        }
    }
}

nonisolated struct CastMember: Identifiable, Hashable, Sendable {
    /// TMDB `credit_id`: unique per role, unlike the person id (one actor can play two roles).
    let id: String
    let name: String
    let character: String?
    let profilePath: String?

    var profileURL: URL? {
        TMDBConfiguration.imageURL(path: profilePath, size: .profile)
    }
}

nonisolated enum MovieList: String, CaseIterable, Identifiable, Sendable {
    case trending
    case popular
    case nowPlaying
    case topRated
    case upcoming

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .trending: "Trending"
        case .popular: "Popular"
        case .nowPlaying: "Now Playing"
        case .topRated: "Top Rated"
        case .upcoming: "Upcoming"
        }
    }

    var path: String {
        switch self {
        case .trending: "/trending/movie/week"
        case .popular: "/movie/popular"
        case .nowPlaying: "/movie/now_playing"
        case .topRated: "/movie/top_rated"
        case .upcoming: "/movie/upcoming"
        }
    }
}
