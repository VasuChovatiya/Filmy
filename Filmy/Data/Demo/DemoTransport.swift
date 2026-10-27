import Foundation
import NetworkingKit

/// An offline `HTTPTransport` that answers TMDB-shaped JSON from `DemoCatalog`.
///
/// Because it sits below `APIClient`, demo mode exercises the same request building, decoding,
/// mapping and pagination code as the live app; only the bytes come from memory.
nonisolated struct DemoTransport: HTTPTransport {
    var latency: Duration = .milliseconds(350)
    var pageSize = 8

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await Task.sleep(for: latency)

        guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        let query = Dictionary((components.queryItems ?? []).map { ($0.name, $0.value ?? "") }) { first, _ in first }
        let path = components.path.replacingOccurrences(of: "/3", with: "", options: .anchored)
        let page = max(1, Int(query["page"] ?? "1") ?? 1)

        let (status, body): (Int, Any)
        if path == "/search/movie" {
            (status, body) = (200, pageJSON(DemoCatalog.search(query["query"] ?? ""), page: page))
        } else if let id = Self.movieID(fromDetailPath: path) {
            if let movie = DemoCatalog.movie(id: id) {
                (status, body) = (200, detailJSON(movie))
            } else {
                (status, body) = (404, ["status_code": 34, "status_message": "The resource you requested could not be found."])
            }
        } else if MovieList.allCases.contains(where: { $0.path == path }) {
            (status, body) = (200, pageJSON(DemoCatalog.movies(for: path), page: page))
        } else {
            (status, body) = (404, ["status_code": 34, "status_message": "Unknown demo endpoint."])
        }

        let data = try JSONSerialization.data(withJSONObject: body)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])
        return (data, response ?? URLResponse())
    }

    private static func movieID(fromDetailPath path: String) -> Int? {
        let parts = path.split(separator: "/")
        guard parts.count == 2, parts[0] == "movie" else { return nil }
        return Int(parts[1])
    }

    private func pageJSON(_ movies: [DemoMovie], page: Int) -> [String: Any] {
        let totalPages = max(1, Int((Double(movies.count) / Double(pageSize)).rounded(.up)))
        let slice = movies.dropFirst((page - 1) * pageSize).prefix(pageSize)
        return [
            "page": page,
            "results": slice.map(summaryJSON),
            "total_pages": totalPages,
            "total_results": movies.count,
        ]
    }

    private func summaryJSON(_ movie: DemoMovie) -> [String: Any] {
        [
            "id": movie.id,
            "title": movie.title,
            "overview": movie.overview,
            "release_date": movie.releaseDate,
            "vote_average": movie.rating,
            "vote_count": movie.voteCount,
        ]
    }

    private func detailJSON(_ movie: DemoMovie) -> [String: Any] {
        let castCount = 6 + movie.id % 5
        let cast = (0..<castCount).map { index -> [String: Any] in
            let person = DemoCatalog.castPool[(movie.id + index * 5) % DemoCatalog.castPool.count]
            return [
                "id": 9000 + (movie.id + index * 5) % DemoCatalog.castPool.count,
                "credit_id": "demo-\(movie.id)-\(index)",
                "name": person.0,
                "character": person.1,
                "order": index,
            ]
        }
        return summaryJSON(movie).merging([
            "tagline": movie.tagline,
            "runtime": movie.runtime,
            "genres": movie.genres.enumerated().map { ["id": $0.offset, "name": $0.element] },
            "credits": ["cast": cast],
        ]) { _, new in new }
    }
}
