import SwiftUI
import SwiftData

struct PaymentMethodsView: View {
    @Query(sort: \PaymentMethod.name) private var methods: [PaymentMethod]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""
    @State private var newKind: PaymentKind = .other

    var body: some View {
        List {
            Section("Active") {
                ForEach(methods.filter { !$0.isArchived }, id: \.id) { m in
                    HStack {
                        Text(m.name).foregroundStyle(.white)
                        Spacer()
                        Text(m.kind.rawValue).foregroundStyle(Theme.textMuted).font(.caption)
                    }
                    .swipeActions { Button("Archive") { m.isArchived = true; try? ctx.save() }.tint(.orange) }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Add") {
                TextField("Name", text: $newName).listRowBackground(Theme.surface)
                Picker("Kind", selection: $newKind) {
                    ForEach(PaymentKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .listRowBackground(Theme.surface)
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    ctx.insert(PaymentMethod(name: trimmed, kind: newKind))
                    try? ctx.save()
                    newName = ""
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Payment methods")
    }
}
