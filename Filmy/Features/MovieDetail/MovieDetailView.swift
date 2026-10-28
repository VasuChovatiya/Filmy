import SwiftData
import SwiftUI

struct MovieDetailView: View {
    /// Includes the status and navigation bar area, since the banner runs behind them.
    private static let backdropHeight: CGFloat = 340
    private static let regularBackdropHeight: CGFloat = 480
    /// Keeps text at a readable line length on iPad; the banner still runs edge to edge.
    private static let maxContentWidth: CGFloat = 720

    @State private var viewModel: MovieDetailViewModel
    @State private var isFavorite = false
    /// The bar stays transparent over the banner and fills in once the banner scrolls under it.
    @State private var isPastBanner = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(movie: Movie, repository: any MovieRepository) {
        _viewModel = State(initialValue: MovieDetailViewModel(movie: movie, repository: repository))
    }

    var body: some View {
        let movie = viewModel.displayedMovie
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                header(movie)
                VStack(alignment: .leading, spacing: Spacing.l) {
                    details(movie)
                }
                .padding(.horizontal, Spacing.m)
                .readableWidth(Self.maxContentWidth)
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
            let backdropHeight = horizontalSizeClass == .regular ? Self.regularBackdropHeight : Self.backdropHeight
            StretchyBackdrop(movie: movie, height: backdropHeight) { collapsed in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPastBanner = collapsed
                }
            }
            .accessibilityHidden(true)

            // At accessibility text sizes the title gets the full width under the poster.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.m))
                : AnyLayout(HStackLayout(alignment: .bottom, spacing: Spacing.m))
            layout {
                PosterImage(movie: movie)
                    .frame(width: horizontalSizeClass == .regular ? 150 : 110)
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(movie.title)
                        .font(.filmyTitle)
                        .foregroundStyle(.white)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                        .minimumScaleFactor(0.8)
                        .accessibilityAddTraits(.isHeader)
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
            .readableWidth(Self.maxContentWidth)
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
            if let trailer = detail.trailer {
                TrailerButton(trailer: trailer)
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
            if !detail.videos.isEmpty {
                DetailSection("Videos") {
                    VideoStrip(videos: detail.videos)
                        .padding(.horizontal, -Spacing.m)
                }
                .transition(.opacity)
            }
            if let options = detail.watchOptions {
                DetailSection("Where to Watch") {
                    WatchOptionsView(options: options)
                }
                .transition(.opacity)
            }
            if !detail.recommendations.isEmpty {
                DetailSection("More Like This") {
                    RecommendationStrip(movies: detail.recommendations)
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
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

private struct TrailerButton: View {
    let trailer: Video
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(trailer.watchURL)
        } label: {
            Label("Play Trailer", systemImage: "play.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xs)
                .background(Color.filmyAccent, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens \(trailer.name) on YouTube"))
    }
}

/// YouTube thumbnails; tapping one opens it in the YouTube app or Safari.
private struct VideoStrip: View {
    let videos: [Video]
    @ScaledMetric(relativeTo: .footnote) private var cardWidth: CGFloat = 220

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: Spacing.s) {
                ForEach(videos) { video in
                    Link(destination: video.watchURL) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Color.clear
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .overlay {
                                    RemoteImage(url: video.thumbnailURL) { Color.filmySurfaceRaised }
                                }
                                .overlay {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 40))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.45))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
                                .padding(.bottom, Spacing.xxs)

                            Text(video.name)
                                .font(.filmyCardTitle)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(video.kind.title)
                                .font(.filmyCaption)
                                .foregroundStyle(Color.filmySecondaryText)
                        }
                        .frame(width: cardWidth, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(video.name), \(video.kind.title)"))
                    .accessibilityHint(Text("Opens on YouTube"))
                    .accessibilityAddTraits(.isLink)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
    }
}

/// Streaming, rental and purchase services for the user's region. TMDB only offers a link to its
/// own watch page, so the whole section opens that.
private struct WatchOptionsView: View {
    let options: WatchOptions

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            group("Stream", options.stream)
            group("Rent", options.rent)
            group("Buy", options.buy)

            HStack(spacing: Spacing.xs) {
                if let link = options.link {
                    Link(destination: link) {
                        Label("All Options", systemImage: "arrow.up.right.square")
                            .font(.footnote.weight(.semibold))
                    }
                }
                Spacer(minLength: Spacing.s)
                // TMDB's terms require crediting JustWatch for this data.
                Text("Data from JustWatch · \(regionName)")
                    .font(.caption2)
                    .foregroundStyle(Color.filmyTertiaryText)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var regionName: String {
        Locale.current.localizedString(forRegionCode: options.region) ?? options.region
    }

    @ViewBuilder
    private func group(_ title: LocalizedStringKey, _ providers: [WatchProvider]) -> some View {
        if !providers.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.filmyCaption.weight(.semibold))
                    .foregroundStyle(Color.filmySecondaryText)
                    .textCase(.uppercase)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(providers) { provider in
                            RemoteImage(url: provider.logoURL) {
                                ZStack {
                                    Color.filmySurfaceRaised
                                    Text(provider.name.prefix(1))
                                        .font(.headline)
                                        .foregroundStyle(Color.filmySecondaryText)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.s, style: .continuous))
                            .accessibilityLabel(Text(provider.name))
                        }
                    }
                }
                .scrollClipDisabled()
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Wraps a recommended movie so pushing it uses a plain push: the zoom needs a source poster in the
/// tab's grid, and the recommendation strip isn't in that namespace.
nonisolated struct RelatedMovie: Hashable {
    let movie: Movie
}

private struct RecommendationStrip: View {
    let movies: [Movie]
    @ScaledMetric(relativeTo: .footnote) private var cardWidth: CGFloat = 110

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: Spacing.s) {
                ForEach(movies) { movie in
                    NavigationLink(value: RelatedMovie(movie: movie)) {
                        PosterCard(movie: movie)
                            .frame(width: cardWidth)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("related-card")
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xs)
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
    @ScaledMetric(relativeTo: .footnote) private var cardWidth: CGFloat = 84

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
                    .frame(width: cardWidth)
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
        content
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie, repository: dependencies.repository)
                    .heroDestination(id: movie.id, in: hero)
            }
            .navigationDestination(for: RelatedMovie.self) { related in
                MovieDetailView(movie: related.movie, repository: dependencies.repository)
            }
    }
}

extension View {
    func movieDestination(hero: Namespace.ID) -> some View {
        modifier(MovieDestinationModifier(hero: hero))
    }

    /// Caps the width and centres the view, for iPad and other wide windows.
    func readableWidth(_ maxWidth: CGFloat) -> some View {
        frame(maxWidth: maxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
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
