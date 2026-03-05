//
//  SocialityView.swift
//  Polly
//

import SwiftUI
import FoundationModels

// MARK: - Data models

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let text: String
}

// MARK: - Chat View Model

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: "assistant",
                    text: "Hey! I'm Rob8 🤖 Ask me anything about your digital footprint, eco-tips, or just say hi! 🌱")
    ]
    @Published var isLoading = false
    @Published var streamingText = ""

    private let session: LanguageModelSession

    init() {
        let instructions = Instructions("""
            You are Rob8, an eco-conscious digital robot companion inside the Polly app. \
            Polly helps users reduce their digital carbon footprint by tracking screen time, \
            data storage, and digital habits. \
            You are friendly, a little nerdy, and passionate about sustainability. \
            You speak in short, punchy messages (2–4 sentences max). \
            You give practical eco-digital tips, answer questions about digital sustainability, \
            and cheer the user on when they make good choices. \
            Occasionally add a small robot emoji (🤖) or a leaf (🌱) to keep things fun.
            """)
        self.session = LanguageModelSession(instructions: instructions)
    }

    func send(userText: String, onSocialityIncrease: () -> Void) async {
        guard !userText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        messages.append(ChatMessage(role: "user", text: userText))
        isLoading = true
        streamingText = ""
        onSocialityIncrease()

        do {
            let stream = session.streamResponse(to: userText)
            for try await partial in stream {
                streamingText = partial.content
            }
            messages.append(ChatMessage(role: "assistant", text: streamingText))
        } catch {
            messages.append(ChatMessage(role: "assistant",
                                        text: "Oops, something went wrong on my circuits! 🤖 Try again."))
        }

        streamingText = ""
        isLoading = false
    }
}

// MARK: - SocialityView (directly opens chat)

struct SocialityView: View {
    @EnvironmentObject var game: GameManager
    @StateObject private var vm = ChatViewModel()

    @State private var inputText = ""
    @FocusState private var fieldFocused: Bool

    private let bg      = Color(red: 0.10, green: 0.10, blue: 0.09)
    private let inputBg = Color(red: 0.18, green: 0.18, blue: 0.17)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Divider().background(Color.white.opacity(0.08))

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.messages) { msg in
                                MessageBubble(message: msg).id(msg.id)
                            }
                            if vm.isLoading {
                                if vm.streamingText.isEmpty {
                                    TypingIndicator().id("typing")
                                } else {
                                    MessageBubble(message: ChatMessage(role: "assistant",
                                                                       text: vm.streamingText))
                                        .id("streaming")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: vm.messages.count) {
                        withAnimation { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: vm.streamingText) {
                        withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                    }
                    .onChange(of: vm.isLoading) { _, loading in
                        if loading { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                    }
                }

                Divider().background(Color.white.opacity(0.08))

                HStack(spacing: 10) {
                    TextField("Message Rob8…", text: $inputText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .tint(.orange)
                        .focused($fieldFocused)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(inputBg)
                        .cornerRadius(20)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading
                                ? Color.white.opacity(0.25) : .orange
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(bg)
            }
            .background(bg)
            .navigationTitle("Chat with Rob8")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !vm.isLoading else { return }
        inputText = ""
        fieldFocused = false
        Task {
            await vm.send(userText: trimmed) {
                game.increaseSociality(by: 5)
            }
        }
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }

            if !isUser {
                Image(systemName: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(width: 28, height: 28)
                    .background(Color(red: 0.20, green: 0.14, blue: 0.08))
                    .clipShape(Circle())
            }

            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(isUser ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.orange : Color(red: 0.18, green: 0.18, blue: 0.17))
                .cornerRadius(18)

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "cpu")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 28, height: 28)
                .background(Color(red: 0.20, green: 0.14, blue: 0.08))
                .clipShape(Circle())

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundColor(.orange.opacity(animating ? 1.0 : 0.25))
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.18),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(red: 0.18, green: 0.18, blue: 0.17))
            .cornerRadius(18)

            Spacer(minLength: 48)
        }
        .onAppear { animating = true }
    }
}

// MARK: - Preview

#Preview {
    SocialityView()
        .environmentObject(GameManager())
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
}
