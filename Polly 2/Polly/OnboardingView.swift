//
//  OnboardingView.swift
//  Polly
//
//  Created by Gennaro Biagino on 03/03/26.
//

import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let mood: RobotMood
}

struct OnboardingView: View {
    @Binding var isOnboarded: Bool
    @State private var currentPage: Int = 0

    let slides: [OnboardingSlide] = [
        .init(title: "Hi, I'm Rob8.",              subtitle: "Your digital eco-companion.",        mood: .happy),
        .init(title: "Storing unused data\nconsumes real energy.", subtitle: "Every byte counts.", mood: .curious),
        .init(title: "Data centers run 24/7.",     subtitle: "Many still rely on non-renewable sources.", mood: .tired),
        .init(title: "This is called\nData Pollution.", subtitle: "An invisible environmental impact.", mood: .bored),
        .init(title: "Let's reduce it together.", subtitle: "Starting now.",                       mood: .happy),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Mascot
                Rob8View(mood: slides[currentPage].mood, size: 120)
                    .transition(.scale.combined(with: .opacity))
                    .id(currentPage)

                // Text
                VStack(spacing: 12) {
                    Text(slides[currentPage].title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .id("title-\(currentPage)")

                    Text(slides[currentPage].subtitle)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .id("sub-\(currentPage)")
                }
                .padding(.horizontal, 32)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.orange : Color.gray.opacity(0.4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                Spacer()

                // Button
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        if currentPage < slides.count - 1 {
                            currentPage += 1
                        } else {
                            isOnboarded = true
                        }
                    }
                } label: {
                    Text(currentPage < slides.count - 1 ? "NEXT →" : "LET'S GO →")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    OnboardingView(isOnboarded: .constant(false))
}
