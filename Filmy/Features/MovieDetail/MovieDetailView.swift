import SwiftData
import SwiftUI

struct MovieDetailView: View {
    /// Includes the status and navigation bar area, since the banner runs behind them.
    private static let backdropHeight: CGFloat = 340

    @State private var viewModel: MovieDetailViewModel
    @State private var isFavorite = false
    /// The bar stays transparent over the banner and fills in once the banner scrolls under it.
    @State private var isPastBanner = false
    @Environment(\.modelContext) private var modelContext

    init(movie: Movie, repository: any MovieRepository) {
        _viewModel = State(initialValue: MovieDetailViewModel(movie: movie, repository: repository))
    }

    var body: some View {
        let movie = viewModel.displayedMovie
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                header(movie)
                details(movie)
                    .padding(.horizontal, Spacing.m)
            }
            .padding(.bottom, Spacing.xl)
        }
        .ignoresSafeArea(edges: .top)
        .hidesTopScrollEdgeEffect(!isPastBanner)
        .background(Color.filmyBackground)
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(isPastBanner ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .opacity(isPastBanner ? 1 : 0)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? Color.filmyAccent : Color.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(isFavorite ? Text("Remove from Favorites") : Text("Add to Favorites"))
            }
        }
        .sensoryFeedback(.selection, trigger: isFavorite)
        .task {
            isFavorite = FavoritesStore.isFavorite(viewModel.movie.id, in: modelContext)
            await viewModel.load()
        }
    }

    private func header(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            StretchyBackdrop(movie: movie, height: Self.backdropHeight) { collapsed in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPastBanner = collapsed
                }
            }

            HStack(alignment: .bottom, spacing: Spacing.m) {
                PosterImage(movie: movie)
                    .frame(width: 110)
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 6)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(movie.title)
                        .font(.filmyTitle)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                    if let metadata = metadata(movie) {
                        Text(metadata)
                            .font(.subheadline)
                            .foregroundStyle(Color.filmySecondaryText)
                    }
                    if movie.hasRating {
                        RatingBadge(rating: movie.rating)
                    }
                }
                .padding(.bottom, Spacing.xxs)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, -72)
        }
    }

    @ViewBuilder
    private func details(_ movie: Movie) -> some View {
        if let detail = viewModel.detail {
            if let tagline = detail.tagline, !tagline.isEmpty {
                Text(tagline)
                    .font(.callout.italic())
                    .foregroundStyle(Color.filmySecondaryText)
            }
            if !detail.genres.isEmpty {
                GenreChips(genres: detail.genres)
            }
        }

        if !movie.overview.isEmpty {
            DetailSection("Overview") {
                Text(movie.overview)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        switch viewModel.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.m)
        case .failed(let message):
            VStack(spacing: Spacing.xs) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.filmySecondaryText)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
        case .loaded(let detail):
            if !detail.cast.isEmpty {
                DetailSection("Cast") {
                    CastStrip(cast: detail.cast)
                        .padding(.horizontal, -Spacing.m)
                }
                .transition(.opacity)
            }
        }
    }

    /// "2024 · 2h 15m"
    private func metadata(_ movie: Movie) -> String? {
        let parts = [movie.releaseYear, viewModel.detail?.formattedRuntime].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func toggleFavorite() {
        guard let nowFavorite = try? FavoritesStore.toggle(viewModel.displayedMovie, in: modelContext) else { return }
        isFavorite = nowFavorite
    }
}

/// Full-bleed banner that stretches on pull-down and reports when it has scrolled under the nav bar.
private struct StretchyBackdrop: View {
    let movie: Movie
    let height: CGFloat
    let onCollapsedChange: (Bool) -> Void

    /// Roughly the status bar plus navigation bar.
    private let barHeight: CGFloat = 120

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView).minY
            let pull = max(0, minY)

            BackdropImage(movie: movie)
                .frame(width: proxy.size.width, height: height + pull)
                .clipped()
                .overlay {
                    // Top scrim keeps the status bar and bar buttons legible over bright artwork.
                    LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4))
                }
                .overlay {
                    LinearGradient(colors: [.clear, .filmyBackground], startPoint: UnitPoint(x: 0.5, y: 0.45), endPoint: .bottom)
                }
                .offset(y: -pull)
                .onChange(of: minY < -(height - barHeight), initial: true) { _, collapsed in
                    onCollapsedChange(collapsed)
                }
        }
        .frame(height: height)
    }
}

private struct DetailSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.filmySectionTitle)
                .foregroundStyle(.white)
            content
        }
    }
}

private struct GenreChips: View {
    let genres: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.filmyCaption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.filmySurfaceRaised, in: Capsule())
                }
            }
        }
        .scrollClipDisabled()
    }
}

private struct CastStrip: View {
    let cast: [CastMember]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: Spacing.s) {
                ForEach(cast) { member in
                    VStack(spacing: Spacing.xxs) {
                        RemoteImage(url: member.profileURL) {
                            ZStack {
                                Color.filmySurfaceRaised
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.filmyTertiaryText)
                            }
                        }
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .padding(.bottom, Spacing.xxs)

                        Text(member.name)
                            .font(.filmyCardTitle)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        if let character = member.character, !character.isEmpty {
                            Text(character)
                                .font(.filmyCaption)
                                .foregroundStyle(Color.filmySecondaryText)
                                .lineLimit(1)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: 84)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
    }
}

/// Pushes `MovieDetailView` for any `Movie` value in the stack, zooming out of the poster marked
/// with `heroSource` in the same namespace. Each tab's stack applies it once.
private struct MovieDestinationModifier: ViewModifier {
    let hero: Namespace.ID
    @Environment(\.dependencies) private var dependencies

    func body(content: Content) -> some View {
        content.navigationDestination(for: Movie.self) { movie in
            MovieDetailView(movie: movie, repository: dependencies.repository)
                .heroDestination(id: movie.id, in: hero)
        }
    }
}

extension View {
    func movieDestination(hero: Namespace.ID) -> some View {
        modifier(MovieDestinationModifier(hero: hero))
    }

    /// iOS 26 dims content under the nav bar even when its background is hidden, which would
    /// put a hard-edged band across the banner.
    @ViewBuilder
    fileprivate func hidesTopScrollEdgeEffect(_ hidden: Bool) -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(hidden, for: .top)
        } else {
            self
        }
    }
}
