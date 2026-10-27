import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @Namespace private var hero

    init(repository: any MovieRepository) {
        _viewModel = State(initialValue: SearchViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.filmyBackground)
                .navigationTitle("Search")
                .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Movie title")
                .autocorrectionDisabled()
                .movieDestination(hero: hero)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .prompt:
            ContentUnavailableView(
                "Search Movies",
                systemImage: "magnifyingglass",
                description: Text("Type at least \(SearchViewModel.minimumQueryLength) letters of a title.")
            )
        case .loading:
            ProgressView()
        case .empty(let term):
            ContentUnavailableView.search(text: term)
        case .failed(let message):
            ContentUnavailableView {
                Label("Search Failed", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again", action: viewModel.retry)
                    .buttonStyle(.borderedProminent)
            }
        case .results:
            results
        }
    }

    private var results: some View {
        List {
            ForEach(viewModel.results) { movie in
                NavigationLink(value: movie) {
                    MovieRow(movie: movie, heroNamespace: hero)
                }
                .accessibilityIdentifier("search-result")
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(.white.opacity(0.08))
                .onAppear {
                    Task { await viewModel.loadMoreIfNeeded(after: movie) }
                }
            }
            PaginationFooter(isLoading: viewModel.isLoadingMore, error: viewModel.loadMoreError) {
                Task { await viewModel.loadMore() }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        // Older results stay visible but dim while a newer query loads.
        .opacity(viewModel.isSearching ? 0.5 : 1)
        .animation(.easeOut(duration: 0.2), value: viewModel.isSearching)
    }
}
