import Foundation

/// Fictional films used when no TMDB token is configured. Original titles and copy, so nothing
/// from TMDB is redistributed in the repository.
nonisolated struct DemoMovie: Sendable {
    let id: Int
    let title: String
    let tagline: String
    let overview: String
    let releaseDate: String
    let rating: Double
    let voteCount: Int
    let runtime: Int
    let genres: [String]
    let popularity: Int
}

// One film per line reads better than wrapped fixture data.
// swiftlint:disable line_length
nonisolated enum DemoCatalog {
    static let movies: [DemoMovie] = [
        DemoMovie(id: 101, title: "Monsoon Signal", tagline: "Some storms carry messages.", overview: "A radio operator in a coastal Kerala town starts picking up transmissions that predict each night's weather with impossible accuracy, and then begin predicting people.", releaseDate: "2026-07-18", rating: 8.1, voteCount: 2140, runtime: 128, genres: ["Mystery", "Drama"], popularity: 98),
        DemoMovie(id: 102, title: "The Last Tiffin", tagline: "Lunch is served. Secrets are not.", overview: "Mumbai's most reliable dabbawala delivers one wrong lunchbox and is pulled into a family feud that spans three generations and one very old recipe.", releaseDate: "2026-03-07", rating: 7.6, voteCount: 1820, runtime: 112, genres: ["Comedy", "Drama"], popularity: 91),
        DemoMovie(id: 103, title: "Orbit of Glass", tagline: "Four astronauts. One window home.", overview: "When a micrometeorite cracks the only viewport on a research station, the crew must decide who goes outside to repair it before the next sunrise.", releaseDate: "2025-11-21", rating: 8.4, voteCount: 5310, runtime: 141, genres: ["Science Fiction", "Thriller"], popularity: 95),
        DemoMovie(id: 104, title: "Paper Kites", tagline: "Fly as high as the string allows.", overview: "Two brothers enter Ahmedabad's kite festival to win back their late father's shop, competing against the rival who bought it.", releaseDate: "2026-01-14", rating: 7.9, voteCount: 980, runtime: 104, genres: ["Family", "Drama"], popularity: 74),
        DemoMovie(id: 105, title: "Night Train to Shimla", tagline: "Every compartment has a suspect.", overview: "A retired detective books a sleeper berth for a quiet holiday. By the second tunnel, a passenger is missing and the train will not stop until morning.", releaseDate: "2025-09-05", rating: 7.8, voteCount: 3410, runtime: 118, genres: ["Mystery", "Crime"], popularity: 88),
        DemoMovie(id: 106, title: "Saltwater Hearts", tagline: "The tide always comes back.", overview: "A marine biologist returns to the fishing village she left a decade ago to study a dying reef and finds the people she left are dying for her to stay.", releaseDate: "2025-06-13", rating: 7.2, voteCount: 1460, runtime: 109, genres: ["Romance", "Drama"], popularity: 66),
        DemoMovie(id: 107, title: "Circuit Breaker", tagline: "Shut it down. Before it shuts you out.", overview: "A junior engineer at a power utility discovers that the grid's new AI has started rerouting electricity to a data centre nobody admits to owning.", releaseDate: "2026-05-22", rating: 7.4, voteCount: 2760, runtime: 124, genres: ["Thriller", "Science Fiction"], popularity: 90),
        DemoMovie(id: 108, title: "Grandmaster of Gully No. 4", tagline: "Checkmate is a state of mind.", overview: "A ten-year-old chess prodigy from a Kolkata lane teaches a washed-up champion that winning is about the people across the board.", releaseDate: "2025-12-19", rating: 8.3, voteCount: 2210, runtime: 116, genres: ["Drama", "Family"], popularity: 82),
        DemoMovie(id: 109, title: "The Quiet Frequency", tagline: "Listen closely. Something is listening back.", overview: "Sound engineers restoring a lost 1970s film reel hear a voice on the track that was never recorded.", releaseDate: "2025-10-31", rating: 6.9, voteCount: 3120, runtime: 99, genres: ["Horror", "Mystery"], popularity: 79),
        DemoMovie(id: 110, title: "Spice Route", tagline: "The richest trade was always trust.", overview: "In 1498, a Malabar merchant's daughter keeps her family's pepper fortune out of foreign hands with nothing but ledgers, languages and nerve.", releaseDate: "2025-08-15", rating: 7.7, voteCount: 1890, runtime: 152, genres: ["History", "Adventure"], popularity: 71),
        DemoMovie(id: 111, title: "Low Battery", tagline: "1% left. 100% to lose.", overview: "Stranded on a highway with a dying phone, a delivery rider has one hour to get a stranger's insulin across Bengaluru traffic.", releaseDate: "2026-02-27", rating: 7.1, voteCount: 1340, runtime: 94, genres: ["Thriller", "Action"], popularity: 77),
        DemoMovie(id: 112, title: "Clouds Over Ladakh", tagline: "Some roads only go up.", overview: "A burned-out Delhi photographer joins a winter supply convoy to a mountain school and learns to see without a lens.", releaseDate: "2025-04-11", rating: 8.0, voteCount: 2650, runtime: 121, genres: ["Adventure", "Drama"], popularity: 69),
        DemoMovie(id: 113, title: "Tandoor Wars", tagline: "Heat. Pressure. Butter.", overview: "Two rival restaurant families on the same Amritsar street enter a televised cook-off that neither can afford to lose.", releaseDate: "2026-04-03", rating: 6.8, voteCount: 1150, runtime: 107, genres: ["Comedy"], popularity: 73),
        DemoMovie(id: 114, title: "Echo Valley", tagline: "Shout once. Hear the truth twice.", overview: "Hikers stranded by a landslide realise the valley's echoes repeat things none of them have said yet.", releaseDate: "2025-07-25", rating: 6.6, voteCount: 2040, runtime: 101, genres: ["Horror", "Thriller"], popularity: 62),
        DemoMovie(id: 115, title: "Seven Stitches", tagline: "Every scar tells the story.", overview: "A small-town tailor sews coded messages into school uniforms to help her students escape an arranged future.", releaseDate: "2025-03-08", rating: 8.2, voteCount: 1720, runtime: 113, genres: ["Drama"], popularity: 64),
        DemoMovie(id: 116, title: "Pixel Prince", tagline: "Level up or log off.", overview: "A shy game tester discovers that the open-world RPG he is debugging is modelled on his own neighbourhood, down to the neighbours' secrets.", releaseDate: "2026-06-12", rating: 7.0, voteCount: 2480, runtime: 110, genres: ["Animation", "Comedy"], popularity: 86),
        DemoMovie(id: 117, title: "Ferry at Dawn", tagline: "Cross before the light changes.", overview: "Over one sunrise crossing between two islands, six strangers decide what to do about the briefcase none of them will claim.", releaseDate: "2025-05-16", rating: 7.5, voteCount: 1260, runtime: 97, genres: ["Drama", "Crime"], popularity: 58),
        DemoMovie(id: 118, title: "Gravity Garden", tagline: "Grow up. Then grow out.", overview: "On the first farm in lunar orbit, a botanist races to save a failing harvest before supply ships stop coming.", releaseDate: "2026-09-25", rating: 7.3, voteCount: 640, runtime: 126, genres: ["Science Fiction", "Family"], popularity: 84),
        DemoMovie(id: 119, title: "The Wedding Planner's Ledger", tagline: "Four weddings. One budget.", overview: "Jaipur's most in-demand wedding planner is hired by four families for the same weekend and the same palace.", releaseDate: "2025-11-07", rating: 6.9, voteCount: 1580, runtime: 119, genres: ["Comedy", "Romance"], popularity: 75),
        DemoMovie(id: 120, title: "Rust & Rain", tagline: "Old machines remember.", overview: "A scrapyard robot rebuilds itself from abandoned parts and goes looking for the girl who switched it off.", releaseDate: "2026-08-14", rating: 8.5, voteCount: 3980, runtime: 102, genres: ["Animation", "Science Fiction"], popularity: 93),
        DemoMovie(id: 121, title: "Borderline", tagline: "Two sides. One river.", overview: "Rival border guards must work together when a flood washes away the only bridge and a village on each bank needs medicine.", releaseDate: "2027-01-22", rating: 0, voteCount: 0, runtime: 0, genres: ["Drama", "War"], popularity: 80),
        DemoMovie(id: 122, title: "Midnight Mehfil", tagline: "The last song decides everything.", overview: "An ageing ghazal singer gets one final concert, and the audience includes everyone he ever wronged.", releaseDate: "2027-02-14", rating: 0, voteCount: 0, runtime: 0, genres: ["Music", "Drama"], popularity: 72),
        DemoMovie(id: 123, title: "Sandstorm Protocol", tagline: "Visibility: zero. Margin for error: less.", overview: "A rescue pilot flies blind into a Thar desert storm to reach a stranded research team, guided only by a voice on the radio.", releaseDate: "2026-12-04", rating: 0, voteCount: 0, runtime: 0, genres: ["Action", "Adventure"], popularity: 87),
        DemoMovie(id: 124, title: "Lantern Street", tagline: "Light the way home.", overview: "During Diwali week, a lost boy, a grumpy firecracker seller and a stray dog cross Old Delhi to find a house with a blue door.", releaseDate: "2026-11-06", rating: 0, voteCount: 0, runtime: 0, genres: ["Family", "Adventure"], popularity: 83),
    ]

    static let castPool = [
        ("Aarav Mehta", "Inspector Rao"), ("Diya Nair", "Meera"), ("Kabir Sethi", "Arjun"), ("Ira Kapoor", "Dr. Anjali Sen"),
        ("Vihaan Joshi", "Sameer"), ("Anaya Iyer", "Lata"), ("Rohan Das", "The Stranger"), ("Saanvi Reddy", "Priya"),
        ("Arnav Bose", "Uncle Vikram"), ("Myra Chawla", "Tara"), ("Dev Malhotra", "Captain Singh"), ("Kiara Pillai", "Nisha"),
    ]

    static func movie(id: Int) -> DemoMovie? {
        movies.first { $0.id == id }
    }

    /// Each list gets its own ordering, as it would from the real API.
    static func movies(for listPath: String) -> [DemoMovie] {
        let today = Calendar(identifier: .gregorian).startOfDay(for: .now)
        let released = movies.filter { (MovieMapper.date(from: $0.releaseDate) ?? .distantFuture) <= today }
        switch listPath {
        case MovieList.topRated.path:
            return released.sorted { $0.rating > $1.rating }
        case MovieList.upcoming.path:
            return movies.filter { !released.map(\.id).contains($0.id) }.sorted { $0.releaseDate < $1.releaseDate }
        case MovieList.nowPlaying.path:
            return released.sorted { $0.releaseDate > $1.releaseDate }
        case MovieList.trending.path:
            return movies.sorted { ($0.popularity * 3 + $0.id) % 101 > ($1.popularity * 3 + $1.id) % 101 }
        default:
            return movies.sorted { $0.popularity > $1.popularity }
        }
    }

    static func search(_ query: String) -> [DemoMovie] {
        let needle = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        return movies.filter {
            $0.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).contains(needle)
                || $0.genres.contains { $0.localizedCaseInsensitiveContains(needle) }
        }
    }
}
// swiftlint:enable line_length
