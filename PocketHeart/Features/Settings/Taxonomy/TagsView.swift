import SwiftUI
import SwiftData

struct TagsView: View {
    @Query(sort: [SortDescriptor(\LedgerTag.usageCount, order: .reverse)]) private var tags: [LedgerTag]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""

    var body: some View {
        List {
            Section("Active") {
                ForEach(tags.filter { !$0.isArchived }, id: \.id) { t in
                    HStack {
                        Text("#" + t.name).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(t.usageCount)").foregroundStyle(Theme.textMuted)
                    }
                    .swipeActions { Button("Archive") { t.isArchived = true; try? ctx.save() }.tint(.orange) }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Add") {
                HStack {
                    TextField("New tag", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        ctx.insert(LedgerTag(name: trimmed))
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
        .navigationTitle("Tags")
    }
}
