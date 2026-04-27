import SwiftUI

struct IdentifiedID: Identifiable, Equatable { let id: UUID }

struct RecordingView: View {
    @Environment(\.appEnv) private var appEnv
    @State private var vm: RecordingViewModel?
    @State private var showStats = false
    @State private var showSettings = false
    @State private var editingTransactionID: UUID?
    @State private var canLoadOlder = false

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            } else {
                ProgressView().tint(Theme.primary)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("PocketHeart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showStats = true } label: {
                    Image(systemName: "chart.bar")
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .navigationDestination(isPresented: $showStats) { StatsView() }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .onAppear {
            if vm == nil, let env = appEnv {
                canLoadOlder = false
                vm = RecordingViewModel(env: env, repository: env.repository, stats: env.stats)
                vm?.load()
            }
        }
    }

    @ViewBuilder
    private func content(vm: RecordingViewModel) -> some View {
        @Bindable var bindable = vm
        VStack(spacing: 0) {
            TodayChip(summary: vm.summary, onStats: { showStats = true })
                .padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if vm.hasMoreHistory {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    if canLoadOlder {
                                        vm.loadOlder()
                                    }
                                }
                        }
                        if vm.isLoadingOlder {
                            ProgressView()
                                .tint(Theme.primary)
                                .padding(.vertical, 10)
                        }
                        ForEach(vm.messages) { m in
                            switch m.kind {
                            case .dayDivider(let label): DayDivider(label: label)
                            case .userBubble(let text, let source, let time):
                                UserBubbleView(text: text, source: source, time: time)
                            case .group(let card):
                                GroupCardView(model: card) { id in editingTransactionID = id }
                            }
                        }
                        if vm.isSubmitting { ProgressView().padding() }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 14)
                }
                .onAppear {
                    applyScrollRequest(vm.scrollRequest, proxy: proxy)
                }
                .onChange(of: vm.scrollRequest) { _, request in
                    applyScrollRequest(request, proxy: proxy)
                }
            }

            if let err = vm.errorMessage {
                Text(err).font(.system(size: 12)).foregroundStyle(Theme.warning)
                    .padding(.horizontal, 16).padding(.vertical, 6)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            InputBar(
                text: $bindable.inputText,
                isRecording: vm.isRecording,
                isRecordingReady: vm.isRecordingReady,
                recordingStartSignal: vm.recordingStartSignal,
                liveTranscript: vm.liveTranscript,
                onSend: { Task { await vm.submitText(vm.inputText) } },
                onMicPressDown: { Task { await vm.startRecording() } },
                onMicCommit: { Task { await vm.stopRecordingAndSubmit() } },
                onMicCancel: { vm.cancelRecording() }
            )
        }
        .sheet(item: Binding(get: { editingTransactionID.map { IdentifiedID(id: $0) } }, set: { editingTransactionID = $0?.id })) { wrapper in
            EditTransactionView(transactionID: wrapper.id) {
                editingTransactionID = nil
                vm.load()
            }
        }
    }

    private func applyScrollRequest(_ request: RecordingScrollRequest?, proxy: ScrollViewProxy) {
        guard let request else { return }
        Task { @MainActor in
            let scroll: () -> Void = {
                switch request.target {
                case .bottom:
                    proxy.scrollTo("bottom", anchor: .bottom)
                    canLoadOlder = true
                case .message(let id):
                    proxy.scrollTo(id, anchor: .top)
                }
            }
            if request.animated {
                withAnimation { scroll() }
            } else {
                scroll()
            }
        }
    }
}
