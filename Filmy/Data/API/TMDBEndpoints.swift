import Foundation
import NetworkingKit

nonisolated enum TMDBEndpoints {
    static func list(_ list: MovieList, page: Int) -> Endpoint<MoviePageDTO> {
        .get(list.path, query: ["page": String(page)])
    }

    static func search(_ query: String, page: Int) -> Endpoint<MoviePageDTO> {
        .get("/search/movie", query: [
            "query": query,
            "page": String(page),
            "include_adult": "false",
        ])
    }

    static func detail(id: Int) -> Endpoint<MovieDetailDTO> {
        // One request for the whole detail screen.
        .get("/movie/\(id)", query: ["append_to_response": "credits,videos,recommendations,watch/providers"])
    }
}
