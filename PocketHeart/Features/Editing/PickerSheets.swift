import SwiftUI
import SwiftData

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<LedgerCategory> { $0.parentID == nil && $0.isArchived == false }) private var categories: [LedgerCategory]
    @Binding var selection: UUID?

    var body: some View {
        NavigationStack {
            List(categories, id: \.id) { c in
                Button {
                    selection = c.id; dismiss()
                } label: {
                    HStack {
                        CategoryIcon(key: c.iconKey, size: 26)
                        Text(c.name).foregroundStyle(.white)
                        Spacer()
                        if selection == c.id { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
        }
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
