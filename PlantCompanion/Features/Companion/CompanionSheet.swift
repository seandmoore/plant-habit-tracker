import SwiftData
import SwiftUI

struct CompanionSheet: View {
    let plantID: UUID?

    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(PlantStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Query private var plants: [UserPlant]

    @State private var conversation = CompanionConversation()
    @State private var question = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                transcript
                Divider()
                composer
            }
            .navigationTitle(plant.map { "Ask about \($0.nickname)" } ?? "Plant Companion")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 480, minHeight: 520)
    }

    private var plant: UserPlant? {
        guard let plantID else { return nil }
        return plants.first { $0.id == plantID }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    header

                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if conversation.state == .thinking {
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
            .onChange(of: conversation.messages.count) { _, _ in
                guard let last = conversation.messages.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            CompanionRing(state: conversation.state)
            Text(groundingDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
    }

    private var groundingDescription: String {
        guard let plant else {
            return "I use your saved care information and clearly say when I don’t know."
        }
        return "My answers are grounded in \(plant.nickname)’s saved details."
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask about care", text: $question, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit { send() }

            Button("Send", systemImage: "arrow.up.circle.fill") { send() }
                .labelStyle(.iconOnly)
                .font(.title)
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || conversation.isBusy)
                .accessibilityLabel("Send question")
        }
        .padding()
        .background(.bar)
    }

    private func send() {
        let outgoing = question
        question = ""

        let facts: [String]
        if let plant {
            facts = CompanionConversation.facts(for: plant, recommendation: store.recommendation(for: plant))
        } else {
            facts = []
        }

        Task {
            await conversation.ask(
                outgoing,
                plantName: plant?.nickname,
                facts: facts,
                using: appEnvironment.companion
            )
        }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == .user ? "You: \(message.text)" : "Companion: \(message.text)")
    }

    private var background: Color {
        message.role == .user ? PlantTheme.accent : PlantTheme.mint.opacity(0.5)
    }
}
