import SwiftUI
import SwiftData

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<LedgerCategory> { $0.isArchived == false }) private var categories: [LedgerCategory]
    @Binding var selection: UUID?

    private var roots: [LedgerCategory] { categories.filter { $0.parentID == nil } }
    private func children(of parentID: UUID) -> [LedgerCategory] {
        categories.filter { $0.parentID == parentID }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(roots, id: \.id) { root in
                    let kids = children(of: root.id)
                    if kids.isEmpty {
                        rowButton(for: root, indent: 0)
                    } else {
                        Section {
                            rowButton(for: root, indent: 0)
                            ForEach(kids, id: \.id) { child in
                                rowButton(for: child, indent: 1)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func rowButton(for c: LedgerCategory, indent: Int) -> some View {
        Button {
            selection = c.id; dismiss()
        } label: {
            HStack(spacing: 8) {
                if indent > 0 { Spacer().frame(width: CGFloat(indent) * 18) }
                CategoryIcon(key: c.iconKey, size: 24)
                Text(c.name).foregroundStyle(.white)
                Spacer()
                if selection == c.id { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
            }
        }
        .listRowBackground(Theme.surface)
    }
}

struct PaymentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<PaymentMethod> { $0.isArchived == false }) private var methods: [PaymentMethod]
    @Binding var selection: UUID?

    var body: some View {
        NavigationStack {
            List(methods, id: \.id) { m in
                Button { selection = m.id; dismiss() } label: {
                    HStack {
                        Text(m.name).foregroundStyle(.white)
                        Spacer()
                        if selection == m.id { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Payment method")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TagsPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<LedgerTag> { $0.isArchived == false }) private var tags: [LedgerTag]
    @Binding var selection: [UUID]

    var body: some View {
        NavigationStack {
            List(tags, id: \.id) { t in
                Button {
                    if let i = selection.firstIndex(of: t.id) { selection.remove(at: i) } else { selection.append(t.id) }
                } label: {
                    HStack {
                        Text("#" + t.name).foregroundStyle(.white)
                        Spacer()
                        if selection.contains(t.id) { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
