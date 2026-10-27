import SwiftUI

struct DiscoverView: View {
    let isDemoMode: Bool
    @State private var viewModel: DiscoverViewModel
    @Namespace private var hero

    init(repository: any MovieRepository, isDemoMode: Bool) {
        self.isDemoMode = isDemoMode
        _viewModel = State(initialValue: DiscoverViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    if isDemoMode {
                        DemoModeBanner()
                            .padding(.horizontal, Spacing.m)
                    }
                    listPicker
                    MovieListGrid(viewModel: viewModel.current, hero: hero)
                        .id(viewModel.selectedList)
                        .transition(.opacity)
                }
                .padding(.bottom, Spacing.l)
            }
            .background(Color.filmyBackground)
            .refreshable {
                await viewModel.current.reload()
            }
            .navigationTitle("Filmy")
            .movieDestination(hero: hero)
        }
    }

    private var listPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(MovieList.allCases) { list in
                    let isSelected = list == viewModel.selectedList
                    Button {
                        withAnimation(.snappy) {
                            viewModel.selectedList = list
                        }
                    } label: {
                        Text(list.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.black : Color.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, Spacing.xs)
                            .background(isSelected ? Color.filmyAccent : Color.filmySurfaceRaised, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedList)
    }
}

enum PosterGridLayout {
    /// Larger cells on iPad, and fewer, wider ones at accessibility text sizes so titles fit.
    static func columns(sizeClass: UserInterfaceSizeClass?, dynamicTypeSize: DynamicTypeSize) -> [GridItem] {
        let minimum: CGFloat = dynamicTypeSize.isAccessibilitySize ? 150 : (sizeClass == .regular ? 150 : 104)
        return [GridItem(.adaptive(minimum: minimum, maximum: minimum * 1.6), spacing: Spacing.m, alignment: .top)]
    }
}

/// Reads the environment `PosterGridLayout` depends on.
struct AdaptivePosterColumns<Content: View>: View {
    @ViewBuilder var content: ([GridItem]) -> Content
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        content(PosterGridLayout.columns(sizeClass: sizeClass, dynamicTypeSize: dynamicTypeSize))
    }
}

/// One list's grid: skeleton while page 1 loads, an error with retry, or posters with a paging footer.
struct MovieListGrid: View {
    let viewModel: MovieListViewModel
    let hero: Namespace.ID
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        PosterGridLayout.columns(sizeClass: sizeClass, dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .loading:
                SkeletonPosterGrid(columns: columns)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't Load Movies", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.reload() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, Spacing.xxl)
            case .loaded:
                LazyVGrid(columns: columns, spacing: Spacing.l) {
                    ForEach(viewModel.movies) { movie in
                        NavigationLink(value: movie) {
                            PosterCard(movie: movie, heroNamespace: hero)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("movie-card")
                        // Not `.task`: scrolling the cell away would cancel the page request.
                        .onAppear {
                            Task { await viewModel.loadMoreIfNeeded(after: movie) }
                        }
                    }
                }
                PaginationFooter(isLoading: viewModel.isLoadingMore, error: viewModel.loadMoreError) {
                    Task { await viewModel.loadMore() }
                }
            }
        }
        .padding(.horizontal, Spacing.m)
        .task {
            await viewModel.loadIfNeeded()
        }
    }
}

private struct DemoModeBanner: View {
    var body: some View {
        Label("Demo mode. Add a TMDB token in Config/Secrets.xcconfig to load live movies.", systemImage: "info.circle.fill")
            .font(.footnote)
            .foregroundStyle(Color.filmySecondaryText)
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.filmySurface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }
}
