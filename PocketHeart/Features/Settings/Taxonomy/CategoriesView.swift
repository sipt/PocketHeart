import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: \LedgerCategory.name) private var categories: [LedgerCategory]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""

    var body: some View {
        List {
            Section("Active") {
                ForEach(categories.filter { !$0.isArchived && $0.parentID == nil }, id: \.id) { c in
                    HStack {
                        CategoryIcon(key: c.iconKey, size: 26)
                        Text(c.name).foregroundStyle(.white)
                        Spacer()
                        if c.isAICreated { Text("AI").font(.system(size: 9.5)).foregroundStyle(Theme.primary) }
                    }
                    .swipeActions {
                        Button("Archive") { c.isArchived = true; try? ctx.save() }
                            .tint(.orange)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Archived") {
                ForEach(categories.filter { $0.isArchived }, id: \.id) { c in
                    HStack {
                        Text(c.name).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Button("Restore") { c.isArchived = false; try? ctx.save() }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Add") {
                HStack {
                    TextField("New category", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        ctx.insert(LedgerCategory(name: trimmed))
                        try? ctx.save()
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Categories")
    }
}
