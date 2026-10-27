import SwiftData
import SwiftUI

@main
struct FilmyApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(\.dependencies, dependencies)
                .preferredColorScheme(.dark)
                .tint(.filmyAccent)
                .task(priority: .background) {
                    await dependencies.images.trimDiskCache()
                }
        }
        .modelContainer(for: FavoriteMovie.self)
    }
}
