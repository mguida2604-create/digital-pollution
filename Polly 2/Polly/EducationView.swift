//
//   EducationView.swift
//  Polly
//
//  Created by Gennaro Biagino on 03/03/26.
//

import SwiftUI

struct Quiz: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct EducationView: View {
    @EnvironmentObject var game: GameManager
    @State private var quizIndex: Int = 0
    @State private var selected: Int? = nil
    @State private var score: Int = 0

    let quizzes: [Quiz] = [
        .init(question: "How much CO₂ does 3 hours of HD YouTube streaming produce?",
              options: ["5 g","7 g","35 g","150 g"], correctIndex: 2,
              explanation: "HD streaming emits ~35g CO₂ per 3 hours due to data center energy use."),
        .init(question: "What share of global electricity do data centers consume?",
              options: ["1%","3%","10%","25%"], correctIndex: 1,
              explanation: "Data centers use ~3% of global electricity — similar to the aviation industry."),
        .init(question: "How much CO₂ does sending one email with attachment produce?",
              options: ["0.3 g","4 g","12 g","50 g"], correctIndex: 1,
              explanation: "A typical email with an attachment generates about 4g of CO₂."),
        .init(question: "Which country hosts the most data centers?",
              options: ["China","Germany","USA","India"], correctIndex: 2,
              explanation: "The USA hosts the largest share of the world's data centers."),
    ]

    var currentQuiz: Quiz { quizzes[quizIndex % quizzes.count] }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Rob8View(mood: .curious, size: 48, animate: false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Pollution Quiz")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        Text("Q\((quizIndex % quizzes.count) + 1)/\(quizzes.count) · Score: \(score)")
                            .font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Question
                Text(currentQuiz.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color(red:0.14,green:0.14,blue:0.13))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
                    .padding(.horizontal, 20)

                // Options
                ForEach(Array(currentQuiz.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        guard selected == nil else { return }
                        selected = index
                        if index == currentQuiz.correctIndex {
                            score += 1
                            game.increaseEducation()
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(optionTextColor(index))
                            Spacer()
                            if let sel = selected {
                                if index == currentQuiz.correctIndex {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                } else if index == sel {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                }
                            }
                        }
                        .padding(16)
                        .background(optionBg(index))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(optionBorder(index), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    .disabled(selected != nil)
                }

                // Explanation + Next
                if selected != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(currentQuiz.explanation)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                        Button("Next Question →") {
                            withAnimation {
                                selected = nil
                                quizIndex += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    .padding(16)
                    .background(Color(red:0.14,green:0.14,blue:0.13))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 20)
        }
    }

    func optionBg(_ i: Int) -> Color {
        guard let sel = selected else { return Color(red:0.14,green:0.14,blue:0.13) }
        if i == currentQuiz.correctIndex { return Color(red:0.10,green:0.23,blue:0.16) }
        if i == sel { return Color(red:0.23,green:0.10,blue:0.10) }
        return Color(red:0.14,green:0.14,blue:0.13)
    }

    func optionBorder(_ i: Int) -> Color {
        guard let sel = selected else { return Color.white.opacity(0.08) }
        if i == currentQuiz.correctIndex { return .green }
        if i == sel { return .red }
        return Color.white.opacity(0.08)
    }

    func optionTextColor(_ i: Int) -> Color {
        guard let sel = selected else { return .white }
        if i == currentQuiz.correctIndex { return .green }
        if i == sel { return .red }
        return Color.gray
    }
}

#Preview {
    EducationView().environmentObject(GameManager())
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
}
