import SwiftUI
import SwiftData

struct EditTransactionView: View {
    let transactionID: UUID
    let onClose: () -> Void

    @Environment(\.appEnv) private var env
    @State private var vm: EditTransactionViewModel?
    @State private var showCategory = false
    @State private var showPayment = false
    @State private var showTags = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm { form(vm: vm) } else { ProgressView() }
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onClose() }.tint(Theme.primary) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndClose() }.tint(Theme.primary).bold()
                }
            }
            .navigationTitle("Edit transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if vm == nil, let env {
                vm = EditTransactionViewModel(txnID: transactionID, repository: env.repository, context: env.container.mainContext)
                vm?.load()
            }
        }
    }

    @ViewBuilder
    private func form(vm: EditTransactionViewModel) -> some View {
        @Bindable var bindable = vm
        ScrollView {
            VStack(spacing: 14) {
                amountHero(vm: bindable)
                Form {
                    Section {
                        DatePicker("Time", selection: $bindable.occurredAt)
                        TextField("Currency", text: $bindable.currency)
                    }
                    Section("Category") {
                        Button { showCategory = true } label: {
                            HStack { Text("Category"); Spacer(); Text(currentCategoryName(vm: vm)).foregroundStyle(.secondary) }
                        }
                    }
                    Section("Payment") {
                        Button { showPayment = true } label: {
                            HStack { Text("Payment"); Spacer(); Text(currentPaymentName(vm: vm)).foregroundStyle(.secondary) }
                        }
                        Button { showTags = true } label: {
                            HStack { Text("Tags"); Spacer(); Text("\(vm.tagIDs.count) selected").foregroundStyle(.secondary) }
                        }
                    }
                    Section("Notes") {
                        TextField("Notes", text: $bindable.notes, axis: .vertical).lineLimit(2...5)
                    }
                    Section {
                        Button(role: .destructive) { deleteAndClose() } label: {
                            HStack { Spacer(); Text("Delete transaction"); Spacer() }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .frame(minHeight: 600)
            }
        }
        .sheet(isPresented: $showCategory) { CategoryPickerSheet(selection: $bindable.categoryID) }
        .sheet(isPresented: $showPayment) { PaymentPickerSheet(selection: $bindable.paymentMethodID) }
        .sheet(isPresented: $showTags) { TagsPickerSheet(selection: $bindable.tagIDs) }
    }

    private func amountHero(vm: EditTransactionViewModel) -> some View {
        @Bindable var b = vm
        return VStack(spacing: 8) {
            HStack {
                Button { b.type = .expense } label: { TypePill(type: .expense, active: b.type == .expense) }
                Button { b.type = .income } label: { TypePill(type: .income, active: b.type == .income) }
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(b.currency) ¥").font(.system(size: 18, weight: .medium)).foregroundStyle(.secondary)
                TextField("0.00", text: $b.amountString)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func currentCategoryName(vm: EditTransactionViewModel) -> String {
        guard let id = vm.categoryID else { return "—" }
        guard let env = env else { return "—" }
        guard let cat = (try? env.repository.category(id: id)) ?? nil else { return "—" }
        if let parentID = cat.parentID, let parent = (try? env.repository.category(id: parentID)) ?? nil {
            return "\(parent.name) · \(cat.name)"
        }
        return cat.name
    }
    private func currentPaymentName(vm: EditTransactionViewModel) -> String {
        guard let id = vm.paymentMethodID else { return "—" }
        guard let env = env else { return "—" }
        return (try? env.repository.paymentMethod(id: id))??.name ?? "—"
    }
    private func saveAndClose() {
        do { try vm?.save(); onClose() } catch { vm?.error = error.localizedDescription }
    }
    private func deleteAndClose() {
        do { try vm?.delete(); onClose() } catch { vm?.error = error.localizedDescription }
    }
}
