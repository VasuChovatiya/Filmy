import Foundation
import NetworkingKit
@testable import Filmy

/// A `MovieRepository` whose answers each test scripts. Records every call so tests can assert
/// what was (and wasn't) requested.
actor StubMovieRepository: MovieRepository {
    typealias PageHandler = @Sendable (_ page: Int) async throws -> Page<Movie>
    typealias SearchHandler = @Sendable (_ query: String, _ page: Int) async throws -> Page<Movie>
    typealias DetailHandler = @Sendable (_ id: Int) async throws -> MovieDetail

    private let list: PageHandler
    private let search: SearchHandler
    private let detail: DetailHandler

    private(set) var listRequests: [Int] = []
    private(set) var searchRequests: [SearchRequest] = []
    private(set) var detailRequests: [Int] = []

    struct SearchRequest: Equatable {
        let query: String
        let page: Int
    }

    init(
        list: @escaping PageHandler = { _ in Page(items: [], number: 1, totalPages: 1) },
        search: @escaping SearchHandler = { _, _ in Page(items: [], number: 1, totalPages: 1) },
        detail: @escaping DetailHandler = { _ in throw NetworkError.httpStatus(code: 404, body: Data()) }
    ) {
        self.list = list
        self.search = search
        self.detail = detail
    }

    func movies(in list: MovieList, page: Int) async throws -> Page<Movie> {
        listRequests.append(page)
        return try await self.list(page)
    }

    func searchMovies(matching query: String, page: Int) async throws -> Page<Movie> {
        searchRequests.append(SearchRequest(query: query, page: page))
        return try await search(query, page)
    }

    func movieDetail(id: Int) async throws -> MovieDetail {
        detailRequests.append(id)
        return try await detail(id)
    }
}

/// A switch tests can flip between calls, e.g. to fail one page and succeed on retry.
final class FailureSwitch: @unchecked Sendable {
    private let lock = NSLock()
    private var _isOn: Bool

    init(_ isOn: Bool = false) {
        _isOn = isOn
    }

    var isOn: Bool {
        get { lock.withLock { _isOn } }
        set { lock.withLock { _isOn = newValue } }
    }
}
