import Foundation

@MainActor
@Observable
final class StatsViewModel {
    var summary: StatsSummary?
    var error: String?
    let stats: StatsService

    init(stats: StatsService) { self.stats = stats }

    func load() {
        do { summary = try stats.summary() }
        catch let e { error = e.localizedDescription }
    }
}
