import SwiftUI

/// A 2:3 poster. Falls back to a generated gradient poster when TMDB has no artwork (or in demo mode).
struct PosterImage: View {
    let movie: Movie
    var size: TMDBImageSize = .poster
    var cornerRadius: CGFloat = Radius.m

    var body: some View {
        Color.clear
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay {
                RemoteImage(url: movie.posterURL(size)) {
                    PosterPlaceholder(id: movie.id, title: movie.title)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

struct PosterPlaceholder: View {
    let id: Int
    let title: String
    var showsTitle = true

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: PosterPalette.colors(for: id), startPoint: .topLeading, endPoint: .bottomTrailing)

                Image(systemName: PosterPalette.symbol(for: id))
                    .font(.system(size: width * 0.42, weight: .light))
                    .foregroundStyle(.white.opacity(0.18))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: width * 0.12, y: -width * 0.18)

                if showsTitle && width > 60 {
                    Text(title)
                        .font(.system(size: max(10, width * 0.11), weight: .heavy, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                        .padding(width * 0.08)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Wide 16:9-ish artwork for the detail header; falls back to a blurred gradient.
struct BackdropImage: View {
    let movie: Movie

    var body: some View {
        RemoteImage(url: movie.backdropURL()) {
            ZStack {
                LinearGradient(colors: PosterPalette.colors(for: movie.id), startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: PosterPalette.symbol(for: movie.id))
                    .font(.system(size: 140, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.15))
                    .offset(x: 90, y: -10)
            }
        }
    }
}
