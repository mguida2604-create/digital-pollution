//
//  Rob8View.swift
//  Polly
//
//  Created by Gennaro Biagino on 03/03/26.
//

import SwiftUI

struct Rob8View: View {
    let mood: RobotMood
    var size: CGFloat = 120
    var animate: Bool = true

    @State private var bobOffset: CGFloat = 0

    var eyeColor: Color {
        switch mood {
        case .happy:   return .white
        case .hungry:  return Color.orange
        case .tired:   return Color.gray
        case .curious: return Color.blue
        case .bored:   return Color.gray
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color.orange)
                .frame(width: size, height: size)
                .shadow(color: .orange.opacity(0.45), radius: 16, y: 8)

            VStack(spacing: size * 0.06) {
                HStack(spacing: size * 0.12) {
                    EyeView(size: size, eyeColor: eyeColor, mood: mood)
                    EyeView(size: size, eyeColor: eyeColor, mood: mood)
                }
                MouthView(size: size, mood: mood)
            }
        }
        .offset(y: bobOffset)
        .onAppear {
            guard animate else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bobOffset = -8
            }
        }
        .animation(.easeInOut(duration: 0.4), value: mood)
    }
}

struct EyeView: View {
    let size: CGFloat
    let eyeColor: Color
    let mood: RobotMood

    var eyeHeight: CGFloat { mood == .tired ? size * 0.04 : size * 0.12 }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.black)
            .frame(width: size * 0.18, height: size * 0.22)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .fill(eyeColor)
                    .frame(width: size * 0.10, height: eyeHeight)
                    .animation(.easeInOut(duration: 0.4), value: mood)
            )
    }
}

struct MouthView: View {
    let size: CGFloat
    let mood: RobotMood

    var mouthColor: Color {
        switch mood {
        case .happy, .curious: return .white
        default: return Color.gray.opacity(0.8)
        }
    }

    var mouthWidth: CGFloat {
        switch mood {
        case .happy:   return size * 0.30
        case .hungry:  return size * 0.12
        case .tired:   return size * 0.20
        case .curious: return size * 0.25
        case .bored:   return size * 0.15
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.07)
            .fill(Color.black)
            .frame(width: size * 0.5, height: size * 0.14)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.035)
                    .fill(mouthColor)
                    .frame(width: mouthWidth, height: size * 0.07)
                    .animation(.easeInOut(duration: 0.4), value: mood)
            )
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach([RobotMood.happy, .hungry, .tired, .curious, .bored], id: \.self) { mood in
            Rob8View(mood: mood, size: 70, animate: false)
        }
    }
    .padding()
    .background(Color(red: 0.1, green: 0.1, blue: 0.09))
}
