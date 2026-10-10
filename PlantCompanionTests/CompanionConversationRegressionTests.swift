import XCTest
@testable import PlantCompanion

@MainActor
final class CompanionConversationRegressionTests: XCTestCase {
    func testAnEarlierReplyAnimationCannotUnlockANewerPendingRequest() async {
        let service = ControlledCompanionService(questions: ["first", "second"])
        let pause = ControlledSpeakingPause()
        let conversation = CompanionConversation(speakingPause: { try await pause.wait() })

        let first = Task { await ask("first", conversation: conversation, service: service) }
        await service.waitForRequest("first")
        await service.complete("first", with: .success("First answer"))
        await pause.waitForEntry(1)
        XCTAssertEqual(conversation.state, .speaking)
        XCTAssertFalse(conversation.isBusy, "A follow-up remains available during the reply animation")

        let second = Task { await ask("second", conversation: conversation, service: service) }
        await service.waitForRequest("second")
        await pause.complete(1)
        await first.value

        XCTAssertEqual(conversation.state, .thinking)
        XCTAssertTrue(conversation.isBusy)
        await ask("third", conversation: conversation, service: service)
        let questions = await service.prompts.map(\.question)
        XCTAssertEqual(questions, ["first", "second"], "A third request must not overlap the pending reply")

        await service.complete("second", with: .success("Second answer"))
        await pause.waitForEntry(2)
        await pause.complete(2)
        await second.value

        XCTAssertEqual(conversation.state, .idle)
        XCTAssertEqual(conversation.messages.dropFirst().map(\.text), ["first", "First answer", "second", "Second answer"])
    }

    func testCancellingAnEarlierAnimationCannotResetANewerRequest() async {
        let service = ControlledCompanionService(questions: ["first", "second"])
        let pause = ControlledSpeakingPause()
        let conversation = CompanionConversation(speakingPause: { try await pause.wait() })

        let first = Task { await ask("first", conversation: conversation, service: service) }
        await service.waitForRequest("first")
        await service.complete("first", with: .success("First answer"))
        await pause.waitForEntry(1)
        let second = Task { await ask("second", conversation: conversation, service: service) }
        await service.waitForRequest("second")

        first.cancel()
        await pause.complete(1, with: .failure(CancellationError()))
        await first.value
        XCTAssertEqual(conversation.state, .thinking)
        XCTAssertTrue(conversation.isBusy)

        await service.complete("second", with: .success("Second answer"))
        await pause.waitForEntry(2)
        await pause.complete(2)
        await second.value
        XCTAssertEqual(conversation.state, .idle)
        XCTAssertFalse(conversation.messages.contains(.failure))
    }

    func testCancelledRequestDiscardsALateServiceReplyAndReleasesBusyState() async {
        let service = ControlledCompanionService(questions: ["first"])
        let conversation = CompanionConversation(speakingPause: {})
        let request = Task { await ask("first", conversation: conversation, service: service) }
        await service.waitForRequest("first")

        request.cancel()
        // A service need not cooperate with cancellation; the conversation still discards its reply.
        await service.complete("first", with: .success("A late answer"))
        await request.value

        XCTAssertEqual(conversation.state, .idle)
        XCTAssertFalse(conversation.isBusy)
        XCTAssertEqual(conversation.messages.dropFirst().map(\.text), ["first"])
    }

    func testServiceCancellationDoesNotDisplayAFailure() async {
        let service = ControlledCompanionService(questions: ["first"])
        let conversation = CompanionConversation(speakingPause: {})
        let request = Task { await ask("first", conversation: conversation, service: service) }
        await service.waitForRequest("first")
        await service.complete("first", with: .failure(CancellationError()))
        await request.value

        XCTAssertEqual(conversation.state, .idle)
        XCTAssertEqual(conversation.messages.dropFirst().map(\.text), ["first"])
    }

    func testFailureReleasesBusyStateAndAllowsARetry() async {
        let service = ControlledCompanionService(questions: ["first", "retry"])
        let conversation = CompanionConversation(speakingPause: {})
        let first = Task { await ask("first", conversation: conversation, service: service) }
        await service.waitForRequest("first")
        await service.complete("first", with: .failure(ControlledCompanionService.Failure.unavailable))
        await first.value
        XCTAssertEqual(conversation.state, .idle)
        XCTAssertEqual(conversation.messages.last, .failure)

        let retry = Task { await ask("retry", conversation: conversation, service: service) }
        await service.waitForRequest("retry")
        await service.complete("retry", with: .success("Recovered"))
        await retry.value
        XCTAssertEqual(conversation.state, .idle)
        XCTAssertEqual(conversation.messages.last?.text, "Recovered")
    }

    func testBlankQuestionsAreIgnoredWithoutCallingTheService() async {
        let service = ControlledCompanionService(questions: [])
        let conversation = CompanionConversation(speakingPause: {})

        await ask(" \n ", conversation: conversation, service: service)

        let prompts = await service.prompts
        XCTAssertTrue(prompts.isEmpty)
        XCTAssertEqual(conversation.messages, [.welcome])
        XCTAssertEqual(conversation.state, .idle)
    }

    private func ask(_ question: String, conversation: CompanionConversation, service: ControlledCompanionService) async {
        await conversation.ask(question, plantName: nil, facts: [], using: service)
    }
}

/// Responses and animation completion are released explicitly, with no wall-clock sleeps or
/// scheduler polling. Unexpected concurrent questions fail immediately instead of hanging tests.
private actor ControlledCompanionService: CompanionService {
    enum Failure: Error { case unavailable }

    private let questions: Set<String>
    private(set) var prompts: [CompanionPrompt] = []
    private var responses: [String: CheckedContinuation<String, any Error>] = [:]
    private var arrivals: [String: CheckedContinuation<Void, Never>] = [:]

    init(questions: Set<String>) {
        self.questions = questions
    }

    func respond(to prompt: CompanionPrompt) async throws -> String {
        prompts.append(prompt)
        guard questions.contains(prompt.question) else { throw Failure.unavailable }
        return try await withCheckedThrowingContinuation { continuation in
            responses[prompt.question] = continuation
            arrivals.removeValue(forKey: prompt.question)?.resume()
        }
    }

    func waitForRequest(_ question: String) async {
        guard responses[question] == nil else { return }
        await withCheckedContinuation { arrivals[question] = $0 }
    }

    func complete(_ question: String, with result: Result<String, any Error>) {
        responses.removeValue(forKey: question)?.resume(with: result)
    }
}

private actor ControlledSpeakingPause {
    private var entryCount = 0
    private var pauses: [Int: CheckedContinuation<Void, any Error>] = [:]
    private var arrivals: [Int: CheckedContinuation<Void, Never>] = [:]

    func wait() async throws {
        entryCount += 1
        let entry = entryCount
        try await withCheckedThrowingContinuation { continuation in
            pauses[entry] = continuation
            arrivals.removeValue(forKey: entry)?.resume()
        }
    }

    func waitForEntry(_ entry: Int) async {
        guard pauses[entry] == nil else { return }
        await withCheckedContinuation { arrivals[entry] = $0 }
    }

    func complete(_ entry: Int, with result: Result<Void, any Error> = .success(())) {
        pauses.removeValue(forKey: entry)?.resume(with: result)
    }
}
