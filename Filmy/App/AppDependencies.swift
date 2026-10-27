import Foundation
import NetworkingKit
import SwiftUI

/// Everything the screens need from the outside world, built once at launch.
nonisolated struct AppDependencies: Sendable {
    let repository: any MovieRepository
    let images: ImagePipeline
    /// True when no TMDB token is configured and movies come from `DemoCatalog`.
    let isDemoMode: Bool

    static func live(bundle: Bundle = .main) -> AppDependencies {
        let token = TMDBConfiguration.accessToken(in: bundle)
        let transport: any HTTPTransport = token == nil ? DemoTransport() : URLSession.shared
        return AppDependencies(
            repository: TMDBMovieRepository(client: TMDBConfiguration.makeClient(token: token, transport: transport)),
            images: .shared,
            isDemoMode: token == nil
        )
    }

    /// Instant demo data for SwiftUI previews.
    static let preview = AppDependencies(
        repository: TMDBMovieRepository(client: TMDBConfiguration.makeClient(token: nil, transport: DemoTransport(latency: .zero))),
        images: .shared,
        isDemoMode: true
    )
}

extension EnvironmentValues {
    @Entry var dependencies: AppDependencies = .preview
}
