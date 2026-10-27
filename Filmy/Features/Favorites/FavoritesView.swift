import SwiftData
import SwiftUI

/// Saved movies, newest first. Rendered from SwiftData alone, so it works offline.
struct FavoritesView: View {
    @Query(sort: \FavoriteMovie.addedAt, order: .reverse) private var favorites: [FavoriteMovie]
    @Namespace private var hero

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on any movie to save it here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: PosterGridLayout.columns, spacing: Spacing.l) {
                            ForEach(favorites) { favorite in
                                NavigationLink(value: favorite.movie) {
                                    PosterCard(movie: favorite.movie, heroNamespace: hero)
                                }
                                .buttonStyle(.plain)
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                        .padding(.bottom, Spacing.l)
                        .animation(.snappy, value: favorites.map(\.movieID))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.filmyBackground)
            .navigationTitle("Favorites")
            .movieDestination(hero: hero)
        }
    }
}
