import SwiftUI
import SwiftData

struct ProviderEditView: View {
    let providerID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnv) private var env
    @State private var vm: ProviderEditViewModel?

    var body: some View {
        Group {
            if let vm { form(vm: vm) } else { ProgressView() }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(providerID == nil ? "Add provider" : "Edit provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveAndClose() }.bold()
            }
        }
        .onAppear {
            if vm == nil, let env { vm = ProviderEditViewModel(editingID: providerID, context: env.container.mainContext); vm?.load() }
        }
    }

    @ViewBuilder
    private func form(vm: ProviderEditViewModel) -> some View {
        @Bindable var b = vm
        Form {
            Section("Template") {
                Picker("Template", selection: $b.template) {
                    ForEach(ProviderTemplate.allCases, id: \.self) { t in Text(t.rawValue.capitalized).tag(t) }
                }
                .onChange(of: b.template) { _, new in vm.applyTemplate(new) }
            }
            Section("Provider") {
                TextField("Display name", text: $b.displayName)
                TextField("Base URL", text: $b.baseURL).keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                TextField("Model", text: $b.modelName).autocorrectionDisabled().textInputAutocapitalization(.never)
                Picker("Interface", selection: $b.interface) {
                    Text("OpenAI-compatible").tag(InterfaceFormat.openAICompatible)
                    Text("Anthropic Messages").tag(InterfaceFormat.anthropicMessages)
                    Text("Gemini generateContent").tag(InterfaceFormat.geminiGenerateContent)
                }
            }
            Section("API key") {
                SecureField("Stored in iOS Keychain", text: $b.apiKey)
            }
            Section {
                Toggle("Default provider", isOn: $b.isDefault)
            }
            if providerID != nil {
                Section { Button(role: .destructive) { deleteAndClose() } label: { Text("Delete provider") } }
            }
            if let err = vm.error {
                Section { Text(err).foregroundStyle(Theme.warning) }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func saveAndClose() {
        do { try vm?.save(); dismiss() } catch { vm?.error = error.localizedDescription }
    }
    private func deleteAndClose() {
        do { try vm?.delete(); dismiss() } catch { vm?.error = error.localizedDescription }
    }
}
