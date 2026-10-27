import SwiftUI

/// Loads an image through `ImagePipeline` (memory + disk cache) and fades it in.
/// Shows `placeholder` while loading, on failure, and when `url` is nil.
struct RemoteImage<Placeholder: View>: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    @ViewBuilder var placeholder: () -> Placeholder

    @Environment(\.dependencies) private var dependencies
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            placeholder()
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else {
            image = nil
            return
        }
        if let cached = dependencies.images.cachedImage(for: url) {
            image = cached
            return
        }
        image = nil
        guard let loaded = try? await dependencies.images.image(for: url) else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            image = loaded
        }
    }
}
