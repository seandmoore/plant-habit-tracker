import SwiftUI

struct CompanionSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            companionHeader
                            ForEach(appModel.companionMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if appModel.companionState == .thinking {
                                HStack {
                                    ProgressView()
                                    Text("Thinking with your plant records…")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: appModel.companionMessages.count) { _, _ in
                        if let last = appModel.companionMessages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                Divider()
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Ask about care", text: $question, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .onSubmit { send() }
                    Button("Send", systemImage: "arrow.up.circle.fill") { send() }
                        .labelStyle(.iconOnly)
                        .font(.title)
                        .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.companionState == .thinking)
                        .accessibilityLabel("Send question")
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle(appModel.companionPlant.map { "Ask about \($0.nickname)" } ?? "Plant Companion")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 480, minHeight: 520)
    }

    private var companionHeader: some View {
        VStack(spacing: 10) {
            CompanionRing(state: appModel.companionState) {}
                .allowsHitTesting(false)
            Text(appModel.companionPlant == nil
                 ? "I use your saved care information and clearly say when I don’t know."
                 : "My answers are grounded in \(appModel.companionPlant?.nickname ?? "this plant")’s saved details.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
    }

    private func send() {
        let message = question
        question = ""
        Task { await appModel.askCompanion(message) }
    }
}

private struct MessageBubble: View {
    let message: CompanionMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 56) }
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(message.role == .user ? .white : .primary)
            if message.role == .companion { Spacer(minLength: 56) }
        }
        .accessibilityLabel(message.role == .user ? "You: \(message.text)" : "Companion: \(message.text)")
    }

    private var background: Color {
        message.role == .user ? PlantTheme.accent : PlantTheme.mint.opacity(0.5)
    }
}
