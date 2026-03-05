//
//  ContentView.swift
//  Polly
//
//  Created by Gennaro Biagino on 03/03/26.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameManager()
    @AppStorage("isOnboarded") private var isOnboarded: Bool = false
    @State private var selectedTab: Int = 2 // Home = center

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.09).ignoresSafeArea()

            if !isOnboarded {
                OnboardingView(isOnboarded: $isOnboarded)
                    .transition(.opacity)
            } else {
                mainContent
            }

            // Overuse warning overlay
            if game.showOveruseWarning {
                overuseOverlay
                    .transition(.opacity)
            }
        }
        .environmentObject(game)
        .animation(.easeInOut(duration: 0.4), value: isOnboarded)
        .animation(.easeInOut(duration: 0.3), value: game.showOveruseWarning)
    }

    var mainContent: some View {
        TabView(selection: $selectedTab) {
            HungerView()
                .tabItem { Label("Hungry", systemImage: "pause.fill") }
                .tag(0)

            EnergyView()
                .tabItem { Label("Energy", systemImage: "bolt.fill") }
                .tag(1)

            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(2)

            EducationView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
                .tag(3)

            SocialityView()
                .tabItem { Label("Sociality", systemImage: "message.fill") }
                .tag(4)
        }
        .accentColor(.orange)
        .toolbarBackground(
            Color(red: 0.14, green: 0.14, blue: 0.13),
            for: .tabBar
        )
        .toolbarBackground(.visible, for: .tabBar)
    }

    var overuseOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                Rob8View(mood: .tired, size: 110)

                VStack(spacing: 10) {
                    Text("Too much screen time?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("\"Are you using this app too much?\nIf you keep going, I might get tired.\"")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Button("I'll take a break") {
                    game.dismissOveruseWarning()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 48)
                .background(Color.orange)
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.4), radius: 12, y: 6)
            }
        }
    }
}

#Preview {
    ContentView()
}
