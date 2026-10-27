import Foundation
import NetworkingKit

nonisolated enum TMDBConfiguration {
    static let apiBaseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!
    /// TMDB rejects `page` above 500 even when `total_pages` reports more.
    static let maxPage = 500

    /// The API Read Access Token injected from `Config/Secrets.xcconfig` via Info.plist.
    /// Returns nil when it is missing or still the unexpanded build-setting placeholder.
    static func accessToken(in bundle: Bundle = .main) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: "TMDBAccessToken") as? String else { return nil }
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty || token.hasPrefix("$(") ? nil : token
    }

    static func makeClient(token: String?, transport: any HTTPTransport) -> APIClient {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        var interceptors: [any RequestInterceptor] = [
            QueryItemInterceptor([URLQueryItem(name: "language", value: "en-US")]),
        ]
        if let token {
            interceptors.insert(BearerTokenInterceptor(token: token), at: 0)
        }

        #if DEBUG
        let logger = NetworkLogger()
        #else
        let logger = NetworkLogger.disabled
        #endif

        return APIClient(
            baseURL: apiBaseURL,
            transport: transport,
            interceptors: interceptors,
            decoder: decoder,
            logger: logger
        )
    }

    static func imageURL(path: String?, size: TMDBImageSize) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return imageBaseURL.appending(path: size.rawValue).appending(path: path)
    }
}

/// Image widths TMDB serves. Smaller sizes for grids keep scrolling and the disk cache light.
nonisolated enum TMDBImageSize: String, Sendable {
    case thumbnail = "w154"
    case poster = "w342"
    case posterLarge = "w500"
    case backdrop = "w780"
    case profile = "w185"
    case logo = "w92"
}
