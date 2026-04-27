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
        let lang = SeedLanguage.from(LocalizationManager.shared.resolvedLocale)
        for c in SeedData.categories {
            insertCategory(c, parentID: nil, into: ctx, lang: lang)
        }
        for t in SeedData.tags {
            ctx.insert(LedgerTag(name: t.name(for: lang), isBuiltIn: true))
        }
        for p in SeedData.paymentMethods {
            ctx.insert(PaymentMethod(name: p.name(for: lang), kind: p.kind, isBuiltIn: true))
        }
        try? ctx.save()
    }

    @MainActor
    private static func insertCategory(_ seed: SeedData.CategorySeed, parentID: UUID?, into ctx: ModelContext, lang: SeedLanguage) {
        let cat = LedgerCategory(name: seed.name(for: lang), parentID: parentID, applicable: seed.applicable, iconKey: seed.iconKey, isBuiltIn: true)
        ctx.insert(cat)
        for child in seed.children {
            insertCategory(child, parentID: cat.id, into: ctx, lang: lang)
        }
    }
}
