import SwiftUI
import SwiftData

struct ProviderListView: View {
    @Query(sort: \AIProvider.createdAt) private var providers: [AIProvider]
    @State private var newProvider = false
    @State private var editingID: UUID?

    var body: some View {
        List {
            ForEach(providers, id: \.id) { p in
                Button { editingID = p.id } label: {
                    HStack(spacing: 12) {
                        ProviderBadge(name: p.displayName)
                        VStack(alignment: .leading) {
                            HStack {
                                Text(p.displayName).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(.white)
                                if p.isDefault {
                                    Text("DEFAULT").font(.system(size: 9.5, weight: .bold))
                                        .padding(.horizontal, 6).padding(.vertical, 1)
                                        .background(Theme.primary.opacity(0.2), in: Capsule())
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                            Text(p.modelName).font(.system(size: 11.5, design: .monospaced)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.textMuted)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            Section {
                Text("You bring your own API key. Keys are stored in iOS Keychain and never leave the device.")
                    .font(.system(size: 11)).foregroundStyle(Theme.textMuted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("AI providers")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { newProvider = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $newProvider) { NavigationStack { ProviderEditView(providerID: nil) }.preferredColorScheme(.dark) }
        .sheet(item: Binding(get: { editingID.map { IdentifiedID(id: $0) } }, set: { editingID = $0?.id })) { wrapper in
            NavigationStack { ProviderEditView(providerID: wrapper.id) }.preferredColorScheme(.dark)
        }
    }
}

struct ProviderBadge: View {
    let name: String
    var body: some View {
        let initials = String(name.split(separator: " ").compactMap(\.first).prefix(2)).uppercased()
        RoundedRectangle(cornerRadius: 9).fill(LinearGradient(colors: [Theme.primary.opacity(0.3), Theme.primary.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Text(initials).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.primaryLight)
            }
            .frame(width: 34, height: 34)
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.primary.opacity(0.25), lineWidth: 1))
    }
}
