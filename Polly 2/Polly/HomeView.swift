//
//  HomeView.swift
//  Polly
//
//  Created by Gennaro Biagino on 03/03/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var game: GameManager

    var moodLabel: String {
        switch game.currentMood {
        case .happy:   return "Rob8 is happy 😊"
        case .hungry:  return "Rob8 is hungry 😟"
        case .tired:   return "Rob8 needs rest 😴"
        case .curious: return "Rob8 wants to learn 🤔"
        case .bored:   return "Rob8 is bored 😑"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Fact banner
                HStack {
                    Text("💡 Did you know? You saved ~30g CO₂ today!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(12)
                .background(Color.orange)
                .cornerRadius(12)

                // Stat bars card
                VStack(spacing: 14) {
                    StatBarView(label: "HUNGER",    value: game.hunger,    color: .orange, icon: "pause.fill")
                    StatBarView(label: "ENERGY",    value: game.energy,    color: .blue,   icon: "bolt.fill")
                    StatBarView(label: "EDUCATION", value: game.education, color: .green,  icon: "book.fill")
                    StatBarView(label: "SOCIALITY", value: game.sociality, color: .yellow, icon: "message.fill")
                }
                .padding(18)
                .background(Color(red: 0.14, green: 0.14, blue: 0.13))
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

                // Rob8 mascot
                VStack(spacing: 12) {
                    Rob8View(mood: game.currentMood, size: 140)
                    Text(moodLabel)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .padding(20)
        }
    }
}

// MARK: - Stat Bar
struct StatBarView: View {
    let label: String
    let value: Double
    let color: Color
    let icon: String

    var barColor: Color {
        value < 30 ? .red : value < 60 ? .yellow : color
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(barColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * (value / 100), height: 6)
                        .animation(.easeInOut(duration: 0.6), value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(GameManager())
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
}
