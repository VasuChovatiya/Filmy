import Foundation
import NetworkingKit
import Testing
@testable import Filmy

struct MovieMapperTests {
    private static func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: Data(json.utf8))
    }

    @Test func parsesReleaseDatesAsCalendarDays() throws {
        let date = try #require(MovieMapper.date(from: "2024-01-01"))
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        #expect(parts.year == 2024)
        #expect(parts.month == 1)
        #expect(parts.day == 1)
    }

    @Test(arguments: ["", "2024", "not-a-date", "2024-01"])
    func rejectsMalformedDates(_ string: String) {
        #expect(MovieMapper.date(from: string) == nil)
    }

    @Test func missingDateIsNil() {
        #expect(MovieMapper.date(from: nil) == nil)
    }

    @Test func capsTotalPagesAtTheAPILimit() throws {
        let dto = try Self.decode(MoviePageDTO.self, #"{"page": 1, "results": [], "total_pages": 900, "total_results": 18000}"#)

        let page = MovieMapper.page(from: dto)

        #expect(page.totalPages == TMDBConfiguration.maxPage)
    }

    @Test func fillsDefaultsForMissingFields() throws {
        let dto = try Self.decode(MovieDTO.self, #"{"id": 5, "title": "Untitled", "release_date": ""}"#)

        let movie = MovieMapper.movie(from: dto)

        #expect(movie.overview == "")
        #expect(movie.rating == 0)
        #expect(!movie.hasRating)
        #expect(movie.releaseDate == nil)
        #expect(movie.posterURL() == nil)
    }

    @Test func detailSortsAndCapsCastAndDropsBlankText() throws {
        let cast = (0..<20).reversed().map {
            #"{"id": \#($0), "credit_id": "c\#($0)", "name": "Actor \#($0)", "character": "\#($0 == 0 ? "" : "Role")", "order": \#($0)}"#
        }
        let json = """
        {"id": 1, "title": "T", "tagline": "   ", "runtime": 135, "genres": [{"id": 1, "name": "Drama"}],
         "credits": {"cast": [\(cast.joined(separator: ","))]}}
        """
        let dto = try Self.decode(MovieDetailDTO.self, json)

        let detail = MovieMapper.detail(from: dto)

        #expect(detail.cast.count == MovieMapper.maxCast)
        #expect(detail.cast.first?.name == "Actor 0")
        #expect(detail.cast.first?.character == nil)
        #expect(detail.cast.map(\.id) == (0..<MovieMapper.maxCast).map { "c\($0)" })
        #expect(detail.tagline == nil)
        #expect(detail.genres == ["Drama"])
    }

    @Test(arguments: [
        (135, "2h 15m"),
        (48, "48m"),
        (120, "2h"),
    ])
    func formatsRuntime(_ minutes: Int, _ expected: String) {
        #expect(Self.detail(runtime: minutes).formattedRuntime == expected)
    }

    @Test func unknownRuntimeIsNil() {
        #expect(Self.detail(runtime: nil).formattedRuntime == nil)
        #expect(Self.detail(runtime: 0).formattedRuntime == nil)
    }

    private static func detail(runtime: Int?) -> MovieDetail {
        MovieDetail(movie: .fixture(id: 1), tagline: nil, runtimeMinutes: runtime, genres: [], cast: [])
    }
}
