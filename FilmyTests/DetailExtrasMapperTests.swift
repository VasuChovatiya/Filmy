import Foundation
import Testing
@testable import Filmy

/// Videos, recommendations and watch providers, which arrive with the detail through
/// `append_to_response`.
struct DetailExtrasMapperTests {
    private static func detail(_ extras: String, region: String = "IN") throws -> MovieDetail {
        let json = #"{"id": 1, "title": "T", "genres": [], "# + extras + "}"
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return MovieMapper.detail(from: try decoder.decode(MovieDetailDTO.self, from: Data(json.utf8)), region: region)
    }

    @Test func missingExtrasDecodeAsEmpty() throws {
        let detail = try Self.detail(#""runtime": 90"#)

        #expect(detail.videos.isEmpty)
        #expect(detail.recommendations.isEmpty)
        #expect(detail.watchOptions == nil)
        #expect(detail.trailer == nil)
    }

    @Test func videosAreYouTubeOnlyAndTrailersFirst() throws {
        let detail = try Self.detail(#"""
        "videos": {"results": [
            {"key": "clip", "name": "Clip", "site": "YouTube", "type": "Clip", "official": true, "published_at": "2024-03-01T00:00:00.000Z"},
            {"key": "vimeo", "name": "Vimeo trailer", "site": "Vimeo", "type": "Trailer", "official": true},
            {"key": "fan", "name": "Fan trailer", "site": "YouTube", "type": "Trailer", "official": false, "published_at": "2024-05-01T00:00:00.000Z"},
            {"key": "old", "name": "Trailer 1", "site": "YouTube", "type": "Trailer", "official": true, "published_at": "2023-01-01T00:00:00.000Z"},
            {"key": "new", "name": "Trailer 2", "site": "YouTube", "type": "Trailer", "official": true, "published_at": "2024-01-01T00:00:00.000Z"},
            {"key": "tease", "name": "Teaser", "site": "YouTube", "type": "Teaser", "official": true}
        ]}
        """#)

        #expect(detail.videos.map(\.id) == ["new", "old", "fan", "tease", "clip"])
        #expect(detail.trailer?.id == "new")
        #expect(detail.trailer?.watchURL.absoluteString == "https://www.youtube.com/watch?v=new")
    }

    @Test func videosWithKeysThatCannotFormAURLAreDropped() throws {
        let detail = try Self.detail(#"""
        "videos": {"results": [
            {"key": "bad key/../x", "name": "Broken", "site": "YouTube", "type": "Trailer"},
            {"key": "dQw4w9WgXcQ", "name": "Trailer", "site": "YouTube", "type": "Trailer"}
        ]}
        """#)

        #expect(detail.videos.map(\.id) == ["dQw4w9WgXcQ"])
    }

    @Test func teaserIsTheTrailerWhenThereIsNoTrailer() throws {
        let detail = try Self.detail(#"""
        "videos": {"results": [
            {"key": "clip", "name": "Clip", "site": "YouTube", "type": "Clip"},
            {"key": "tease", "name": "Teaser", "site": "YouTube", "type": "Teaser"}
        ]}
        """#)

        #expect(detail.trailer?.id == "tease")
    }

    @Test func clipsAloneGiveNoTrailerButStillShowInTheStrip() throws {
        let detail = try Self.detail(#""videos": {"results": [{"key": "clip", "name": "Clip", "site": "YouTube", "type": "Clip"}]}"#)

        #expect(detail.trailer == nil)
        #expect(detail.videos.count == 1)
    }

    @Test func videosAreCapped() throws {
        let videos = (0..<30).map { #"{"key": "v\#($0)", "name": "V", "site": "YouTube", "type": "Clip"}"# }
        let detail = try Self.detail(#""videos": {"results": ["# + videos.joined(separator: ",") + "]}")

        #expect(detail.videos.count == MovieMapper.maxVideos)
    }

    @Test func recommendationsExcludeTheMovieItself() throws {
        let detail = try Self.detail(#"""
        "recommendations": {"page": 1, "total_pages": 1, "total_results": 3, "results": [
            {"id": 2, "title": "Two"}, {"id": 1, "title": "Itself"}, {"id": 3, "title": "Three"}
        ]}
        """#)

        #expect(detail.recommendations.map(\.id) == [2, 3])
    }

    private static let providers = #"""
    "watch/providers": {"results": {
        "IN": {
            "link": "https://www.themoviedb.org/movie/1/watch?locale=IN",
            "flatrate": [{"provider_id": 8, "provider_name": "Netflix", "logo_path": "/n.png", "display_priority": 2}],
            "free": [{"provider_id": 99, "provider_name": "Free Service", "display_priority": 1}],
            "rent": [
                {"provider_id": 10, "provider_name": "Amazon Video", "logo_path": "/a.png", "display_priority": 37},
                {"provider_id": 2, "provider_name": "Apple TV Store", "logo_path": "/t.png", "display_priority": 4}
            ],
            "buy": [{"provider_id": 2, "provider_name": "Apple TV Store", "logo_path": "/t.png", "display_priority": 4}]
        },
        "US": {"link": "https://example.com", "buy": [{"provider_id": 3, "provider_name": "Google Play Movies", "display_priority": 1}]},
        "GB": {"link": "https://example.com"}
    }}
    """#

    @Test func watchOptionsUseTheUsersRegion() throws {
        let options = try #require(try Self.detail(Self.providers, region: "IN").watchOptions)

        #expect(options.region == "IN")
        #expect(options.link?.absoluteString == "https://www.themoviedb.org/movie/1/watch?locale=IN")
        #expect(options.stream.map(\.name) == ["Free Service", "Netflix"])
        #expect(options.rent.map(\.name) == ["Apple TV Store", "Amazon Video"])
        #expect(options.buy.map(\.id) == [2])
        #expect(options.rent.last?.logoURL?.absoluteString == "https://image.tmdb.org/t/p/w92/a.png")
    }

    @Test func regionCodeIsCaseInsensitive() throws {
        #expect(try Self.detail(Self.providers, region: "us").watchOptions?.buy.map(\.id) == [3])
    }

    @Test func noWatchOptionsOutsideCoveredRegions() throws {
        #expect(try Self.detail(Self.providers, region: "FR").watchOptions == nil)
        // A region with a link but no services shows nothing rather than an empty section.
        #expect(try Self.detail(Self.providers, region: "GB").watchOptions == nil)
    }
}
