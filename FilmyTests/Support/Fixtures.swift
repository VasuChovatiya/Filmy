import Foundation
import NetworkingKit
@testable import Filmy

extension Movie {
    static func fixture(id: Int, title: String? = nil, voteCount: Int = 100) -> Movie {
        Movie(
            id: id,
            title: title ?? "Movie \(id)",
            overview: "Overview \(id)",
            posterPath: "/poster\(id).jpg",
            backdropPath: "/backdrop\(id).jpg",
            releaseDate: nil,
            rating: 7.5,
            voteCount: voteCount
        )
    }
}

enum Fixtures {
    /// `count` movies split into pages of `pageSize`, served by page number like the API.
    static func pages(count: Int, pageSize: Int, startingAt firstID: Int = 1) -> @Sendable (Int) -> Page<Movie> {
        let movies = (0..<count).map { Movie.fixture(id: firstID + $0) }
        let totalPages = max(1, Int((Double(count) / Double(pageSize)).rounded(.up)))
        return { page in
            let slice = movies.dropFirst((page - 1) * pageSize).prefix(pageSize)
            return Page(items: Array(slice), number: page, totalPages: totalPages)
        }
    }

    static let serverError = NetworkError.httpStatus(code: 500, body: Data())
}
