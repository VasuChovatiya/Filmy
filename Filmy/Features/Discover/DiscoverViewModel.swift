import Foundation

/// Owns one `MovieListViewModel` per list so switching tabs keeps each list's pages and scroll data.
@Observable
final class DiscoverViewModel {
    var selectedList: MovieList = .trending

    @ObservationIgnored private let repository: any MovieRepository
    @ObservationIgnored private var listViewModels: [MovieList: MovieListViewModel] = [:]

    init(repository: any MovieRepository) {
        self.repository = repository
    }

    var current: MovieListViewModel {
        viewModel(for: selectedList)
    }

    func viewModel(for list: MovieList) -> MovieListViewModel {
        if let existing = listViewModels[list] {
            return existing
        }
        let created = MovieListViewModel(list: list, repository: repository)
        listViewModels[list] = created
        return created
    }
}
