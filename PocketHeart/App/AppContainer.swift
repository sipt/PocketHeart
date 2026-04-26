import Foundation
import SwiftData

enum AppContainer {
    static let schema = Schema([
        Transaction.self,
        InputEntry.self,
        LedgerCategory.self,
        LedgerTag.self,
        PaymentMethod.self,
        AIProvider.self,
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        }
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seedIfNeeded(container: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    @MainActor
    private static func seedIfNeeded(container: ModelContainer) {
        let ctx = container.mainContext
        let categoryCount = (try? ctx.fetchCount(FetchDescriptor<LedgerCategory>())) ?? 0
        guard categoryCount == 0 else { return }
        for c in SeedData.categories {
            ctx.insert(LedgerCategory(name: c.name, applicable: c.applicable, iconKey: c.iconKey, isBuiltIn: true))
        }
        for t in SeedData.tags {
            ctx.insert(LedgerTag(name: t, isBuiltIn: true))
        }
        for p in SeedData.paymentMethods {
            ctx.insert(PaymentMethod(name: p.name, kind: p.kind, isBuiltIn: true))
        }
        try? ctx.save()
    }
}
