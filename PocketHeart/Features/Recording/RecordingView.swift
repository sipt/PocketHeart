import SwiftUI

struct IdentifiedID: Identifiable, Equatable { let id: UUID }

struct RecordingView: View {
    @Environment(\.appEnv) private var appEnv
    @State private var vm: RecordingViewModel?
    @State private var showStats = false
    @State private var showSettings = false
    @State private var editingTransactionID: UUID?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            } else {
                ProgressView().tint(.white)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            if vm == nil, let env = appEnv {
                vm = RecordingViewModel(env: env, repository: env.repository, stats: env.stats)
                vm?.load()
            }
        }
    }

    @ViewBuilder
    private func content(vm: RecordingViewModel) -> some View {
        @Bindable var bindable = vm
        VStack(spacing: 0) {
            navBar
            TodayChip(summary: vm.summary, onStats: { showStats = true })
                .padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { m in
                            switch m.kind {
                            case .dayDivider(let label): DayDivider(label: label)
                            case .userBubble(let text, let source, let time):
                                UserBubbleView(text: text, source: source, time: time)
                            case .group(let card):
                                GroupCardView(model: card) { id in editingTransactionID = id }
                            }
                        }
                        if vm.isRecording { LiveRecordingBubble(elapsed: 0) }
                        if vm.isSubmitting { ProgressView().padding() }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 14)
                }
                .onChange(of: vm.messages.count) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            if let err = vm.errorMessage {
                Text(err).font(.system(size: 12)).foregroundStyle(Theme.warning)
                    .padding(.horizontal, 16).padding(.vertical, 6)
            }

            InputBar(
                text: $bindable.inputText,
                isRecording: vm.isRecording,
                liveTranscript: vm.liveTranscript,
                onSend: { Task { await vm.submitText(vm.inputText) } },
                onMicTap: { Task { vm.isRecording ? await vm.stopRecordingAndSubmit() : await vm.startRecording() } },
                onMicCancel: { vm.cancelRecording() }
            )
        }
        .navigationDestination(isPresented: $showStats) { StatsView() }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .sheet(item: Binding(get: { editingTransactionID.map { IdentifiedID(id: $0) } }, set: { editingTransactionID = $0?.id })) { wrapper in
            EditTransactionView(transactionID: wrapper.id) {
                editingTransactionID = nil
                vm.load()
            }
        }
    }

    private var navBar: some View {
        HStack {
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3").foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.white.opacity(0.07), in: Circle())
            }
            Spacer()
            VStack(spacing: 0) {
                Text(monthHeader).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 4) {
                    Text("Ledger").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    if let p = activeProviderName {
                        Text(p).font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Theme.primary.opacity(0.16), in: Capsule())
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            Spacer()
            Button { showStats = true } label: {
                Image(systemName: "chart.bar").foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.white.opacity(0.07), in: Circle())
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
    }

    private var monthHeader: String {
        let month = Date.now.formatted(.dateTime.month(.wide).locale(LocalizationManager.shared.resolvedLocale))
        return String(format: L("%@ · Today"), month)
    }
    private var activeProviderName: String? {
        guard let env = appEnv else { return nil }
        return (try? env.defaultProvider())??.displayName
    }
}
