import Foundation
import NetworkingKit
import Testing
@testable import Filmy

/// Runs the real repository, client, decoding and mapping against the offline demo transport.
struct DemoRepositoryTests {
    private let repository = TMDBMovieRepository(
        client: TMDBConfiguration.makeClient(token: nil, transport: DemoTransport(latency: .zero))
    )

    @Test func listsArePaginated() async throws {
        let first = try await repository.movies(in: .popular, page: 1)
        let second = try await repository.movies(in: .popular, page: 2)

        #expect(first.items.count == 8)
        #expect(first.hasMore)
        #expect(Set(first.items.map(\.id)).isDisjoint(with: second.items.map(\.id)))
    }

    @Test func searchMatchesTitles() async throws {
        let page = try await repository.searchMovies(matching: "orbit", page: 1)

        #expect(page.items.map(\.title) == ["Orbit of Glass"])
    }

    @Test func detailIncludesCastAndRuntime() async throws {
        let detail = try await repository.movieDetail(id: 103)

        #expect(detail.movie.title == "Orbit of Glass")
        #expect(detail.formattedRuntime == "2h 21m")
        #expect(!detail.cast.isEmpty)
        #expect(detail.genres.contains("Science Fiction"))
    }

    @Test func detailRecommendsMoviesThatShareAGenre() async throws {
        let detail = try await repository.movieDetail(id: 103)

        #expect(!detail.recommendations.isEmpty)
        #expect(!detail.recommendations.contains { $0.id == 103 })
        for recommended in detail.recommendations {
            let genres = try #require(DemoCatalog.movie(id: recommended.id)).genres
            #expect(!Set(genres).isDisjoint(with: detail.genres))
        }
    }

    @Test func detailRequestAsksForEveryExtraInOneCall() {
        let query = TMDBEndpoints.detail(id: 1).queryItems.first { $0.name == "append_to_response" }?.value

        #expect(query == "credits,videos,recommendations,watch/providers")
    }

    @Test func unknownMovieIsNotFound() async {
        await #expect(throws: NetworkError.self) {
            try await repository.movieDetail(id: 999_999)
        }
    }
}
