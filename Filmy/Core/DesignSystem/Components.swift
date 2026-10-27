import SwiftUI

struct RatingBadge: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .foregroundStyle(color)
            Text(rating, format: .number.precision(.fractionLength(1)))
                .foregroundStyle(.white)
        }
        .font(.filmyBadge)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.black.opacity(0.55), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rated \(rating, format: .number.precision(.fractionLength(1))) out of 10"))
    }

    private var color: Color {
        switch rating {
        case 7.5...: .ratingHigh
        case 6..<7.5: .ratingMid
        default: .ratingLow
        }
    }
}

extension Movie {
    /// "Dune: Part Two, 2024, rated 8.2 out of 10": what VoiceOver reads for a card or row.
    var accessibilitySummary: Text {
        let year = releaseYear ?? String(localized: "release date to be announced")
        if hasRating {
            return Text("\(title), \(year), rated \(rating, format: .number.precision(.fractionLength(1))) out of 10")
        }
        return Text("\(title), \(year)")
    }
}

/// Grid cell: poster, rating, title and year.
struct PosterCard: View {
    let movie: Movie
    /// Set to zoom the detail screen out of this poster.
    var heroNamespace: Namespace.ID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            PosterImage(movie: movie)
                .heroSource(id: movie.id, in: heroNamespace)
                .overlay(alignment: .topTrailing) {
                    if movie.hasRating {
                        RatingBadge(rating: movie.rating)
                            .padding(6)
                            // It sits on the artwork, so it stops growing before it covers it.
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                }
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title)
                    .font(.filmyCardTitle)
                    .foregroundStyle(.white)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                Text(movie.releaseYear ?? String(localized: "TBA"))
                    .font(.filmyCaption)
                    .foregroundStyle(Color.filmySecondaryText)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(movie.accessibilitySummary)
    }
}

/// List row used by Search: thumbnail, title, year, rating and a two-line overview.
struct MovieRow: View {
    let movie: Movie
    var heroNamespace: Namespace.ID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // The text column is narrow, so at accessibility sizes year and rating stack instead.
        let metadataLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(spacing: Spacing.xs))

        HStack(alignment: .top, spacing: Spacing.s) {
            PosterImage(movie: movie, size: .thumbnail, cornerRadius: Radius.s)
                .frame(width: 64)
                .heroSource(id: movie.id, in: heroNamespace, cornerRadius: Radius.s)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                metadataLayout {
                    Text(movie.releaseYear ?? String(localized: "TBA"))
                    if movie.hasRating {
                        Label {
                            Text(movie.rating, format: .number.precision(.fractionLength(1)))
                        } icon: {
                            Image(systemName: "star.fill").foregroundStyle(Color.ratingMid)
                        }
                        .labelStyle(.titleAndIcon)
                        .fixedSize()
                    }
                }
                .font(.filmyCaption)
                .foregroundStyle(Color.filmySecondaryText)

                if !movie.overview.isEmpty {
                    Text(movie.overview)
                        .font(.footnote)
                        .foregroundStyle(Color.filmyTertiaryText)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(movie.accessibilitySummary)
        // Read on request (VoiceOver "More Content" rotor) rather than on every row.
        .accessibilityCustomContent("Overview", movie.overview)
    }
}

/// Shown under a paginated list: spinner while loading the next page, retry button after a failure.
struct PaginationFooter: View {
    let isLoading: Bool
    let error: String?
    let retry: () -> Void

    var body: some View {
        Group {
            if let error {
                VStack(spacing: Spacing.xs) {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.filmySecondaryText)
                        .multilineTextAlignment(.center)
                    Button("Try Again", action: retry)
                        .buttonStyle(.bordered)
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.vertical, Spacing.s)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(colors: [.clear, .white.opacity(0.12), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Grey poster cards with a shimmer, laid out like the real grid while page 1 loads.
struct SkeletonPosterGrid: View {
    let columns: [GridItem]
    var count = 12

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.l) {
            ForEach(0..<count, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .fill(Color.filmySurfaceRaised)
                        .aspectRatio(2 / 3, contentMode: .fit)
                    RoundedRectangle(cornerRadius: 3).fill(Color.filmySurfaceRaised).frame(height: 10)
                    RoundedRectangle(cornerRadius: 3).fill(Color.filmySurfaceRaised).frame(width: 40, height: 8)
                }
            }
        }
        .shimmering()
        .accessibilityLabel(Text("Loading"))
    }
}
