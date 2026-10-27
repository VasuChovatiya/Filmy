import Foundation
import SwiftData

/// A saved movie. Stores enough to render the Favorites grid offline, without hitting the API.
@Model
final class FavoriteMovie {
    @Attribute(.unique) var movieID: Int
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var releaseDate: Date?
    var rating: Double
    var voteCount: Int
    var addedAt: Date

    init(movie: Movie, addedAt: Date = .now) {
        movieID = movie.id
        title = movie.title
        overview = movie.overview
        posterPath = movie.posterPath
        backdropPath = movie.backdropPath
        releaseDate = movie.releaseDate
        rating = movie.rating
        voteCount = movie.voteCount
        self.addedAt = addedAt
    }

    var movie: Movie {
        Movie(
            id: movieID,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            rating: rating,
            voteCount: voteCount
        )
    }
}

enum FavoritesStore {
    static func isFavorite(_ movieID: Int, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteMovie>(predicate: #Predicate { $0.movieID == movieID })
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    /// Adds or removes the movie. Returns true when it is now a favourite.
    @discardableResult
    static func toggle(_ movie: Movie, in context: ModelContext) throws -> Bool {
        let movieID = movie.id
        let descriptor = FetchDescriptor<FavoriteMovie>(predicate: #Predicate { $0.movieID == movieID })
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            return false
        }
        context.insert(FavoriteMovie(movie: movie))
        try context.save()
        return true
    }
}
