import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: \LedgerCategory.name) private var categories: [LedgerCategory]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""
    @State private var newParentID: UUID?

    private var activeRoots: [LedgerCategory] {
        categories.filter { !$0.isArchived && $0.parentID == nil }
    }
    private func children(of parentID: UUID) -> [LedgerCategory] {
        categories.filter { !$0.isArchived && $0.parentID == parentID }
    }

    var body: some View {
        List {
            Section("Active") {
                ForEach(activeRoots, id: \.id) { root in
                    rootRow(root)
                    ForEach(children(of: root.id), id: \.id) { child in
                        childRow(child)
                    }
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
                Picker("Parent", selection: $newParentID) {
                    Text("(Top level)").tag(UUID?.none)
                    ForEach(activeRoots, id: \.id) { r in
                        Text(r.name).tag(Optional(r.id))
                    }
                }
                .listRowBackground(Theme.surface)
                HStack {
                    TextField("New category", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        ctx.insert(LedgerCategory(name: trimmed, parentID: newParentID))
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

    private func rootRow(_ c: LedgerCategory) -> some View {
        HStack {
            CategoryIcon(key: c.iconKey, size: 26)
            Text(c.name).foregroundStyle(Theme.textPrimary)
            Spacer()
            if c.isAICreated { Text("AI").font(.system(size: 9.5)).foregroundStyle(Theme.primary) }
        }
        .swipeActions {
            Button("Archive") { c.isArchived = true; try? ctx.save() }
                .tint(.orange)
        }
        .listRowBackground(Theme.surface)
    }

    private func childRow(_ c: LedgerCategory) -> some View {
        HStack(spacing: 8) {
            Spacer().frame(width: 18)
            CategoryIcon(key: c.iconKey, size: 22)
            Text(c.name).foregroundStyle(Theme.textSecondary)
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
