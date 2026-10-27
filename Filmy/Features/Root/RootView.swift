import SwiftData
import SwiftUI

/// The three tabs. Each tab owns its own `NavigationStack`, so switching tabs keeps each one's path.
struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            DiscoverView(repository: dependencies.repository, isDemoMode: dependencies.isDemoMode)
                .tabItem { Label("Discover", systemImage: "film.stack") }

            SearchView(repository: dependencies.repository)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
        }
    }
}

#Preview {
    RootView(dependencies: .preview)
        .modelContainer(for: FavoriteMovie.self, inMemory: true)
        .preferredColorScheme(.dark)
        .tint(.filmyAccent)
}
