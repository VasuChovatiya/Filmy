import Foundation
import SwiftData
import Testing
@testable import Filmy

@MainActor
struct FavoritesStoreTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(for: FavoriteMovie.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func toggleAddsThenRemoves() throws {
        let movie = Movie.fixture(id: 42)
        #expect(!FavoritesStore.isFavorite(42, in: context))

        #expect(try FavoritesStore.toggle(movie, in: context))
        #expect(FavoritesStore.isFavorite(42, in: context))

        #expect(try !FavoritesStore.toggle(movie, in: context))
        #expect(!FavoritesStore.isFavorite(42, in: context))
        #expect(try context.fetchCount(FetchDescriptor<FavoriteMovie>()) == 0)
    }

    @Test func togglingOneMovieLeavesOthersAlone() throws {
        try FavoritesStore.toggle(.fixture(id: 1), in: context)
        try FavoritesStore.toggle(.fixture(id: 2), in: context)

        try FavoritesStore.toggle(.fixture(id: 1), in: context)

        #expect(!FavoritesStore.isFavorite(1, in: context))
        #expect(FavoritesStore.isFavorite(2, in: context))
    }

    @Test func savedMovieReadsBackUnchanged() throws {
        let movie = Movie(
            id: 7,
            title: "Orbit of Glass",
            overview: "Four astronauts.",
            posterPath: "/p.jpg",
            backdropPath: "/b.jpg",
            releaseDate: MovieMapper.date(from: "2025-11-21"),
            rating: 8.4,
            voteCount: 5310
        )
        try FavoritesStore.toggle(movie, in: context)

        let saved = try #require(try context.fetch(FetchDescriptor<FavoriteMovie>()).first)

        #expect(saved.movie == movie)
    }
}
