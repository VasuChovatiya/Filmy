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
    /// YouTube trailers, teasers and clips, best first.
    var videos: [Video] = []
    var recommendations: [Movie] = []
    /// Nil when no service offers the movie in the user's region.
    var watchOptions: WatchOptions?

    /// The video the "Play Trailer" button opens.
    var trailer: Video? {
        videos.first { $0.kind == .trailer || $0.kind == .teaser }
    }

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

nonisolated struct Video: Identifiable, Hashable, Sendable {
    enum Kind: Int, Comparable, Sendable {
        // Raw values order the strip: trailers first.
        case trailer, teaser, clip, featurette, behindTheScenes, other

        init(tmdbType: String) {
            switch tmdbType {
            case "Trailer": self = .trailer
            case "Teaser": self = .teaser
            case "Clip": self = .clip
            case "Featurette": self = .featurette
            case "Behind the Scenes": self = .behindTheScenes
            default: self = .other
            }
        }

        static func < (lhs: Kind, rhs: Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var title: LocalizedStringResource {
            switch self {
            case .trailer: "Trailer"
            case .teaser: "Teaser"
            case .clip: "Clip"
            case .featurette: "Featurette"
            case .behindTheScenes: "Behind the Scenes"
            case .other: "Video"
            }
        }
    }

    /// The YouTube video id.
    let id: String
    let name: String
    let kind: Kind
    let isOfficial: Bool

    /// YouTube ids use only letters, digits, "-" and "_". The mapper drops any other key, which keeps
    /// the URLs below valid.
    static func isValidKey(_ key: String) -> Bool {
        !key.isEmpty && key.unicodeScalars.allSatisfy { $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_") }
    }

    var watchURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://www.youtube.com/watch?v=\(id)")!
    }

    var thumbnailURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")!
    }
}

/// Where the movie can be watched in one region, from TMDB's JustWatch data.
nonisolated struct WatchOptions: Hashable, Sendable {
    let region: String
    /// TMDB's watch page, which links out to each service. TMDB has no per-service deep links.
    let link: URL?
    /// Subscription, free and ad-supported services.
    let stream: [WatchProvider]
    let rent: [WatchProvider]
    let buy: [WatchProvider]

    var isEmpty: Bool {
        stream.isEmpty && rent.isEmpty && buy.isEmpty
    }
}

nonisolated struct WatchProvider: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let logoPath: String?

    var logoURL: URL? {
        TMDBConfiguration.imageURL(path: logoPath, size: .logo)
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
