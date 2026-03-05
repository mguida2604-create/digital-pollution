import SwiftUI

struct EnergyView: View {
    @EnvironmentObject var game: GameManager

    var statusMessage: (String, Color) {
        if game.energy > 70 { return ("You're doing well!", .green) }
        if game.energy > 40 { return ("Screen time is rising...", .yellow) }
        return ("Polly is exhausted!", .red)
    }

    var sessionFormatted: String {
        let mins = game.screenTimeMinutes
        if mins < 1 { return "Just started" }
        if mins < 60 { return "\(mins) min" }
        return "\(mins / 60)h \(mins % 60)m"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Header
                HStack {
                    Rob8View(mood: .tired, size: 48, animate: false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Time Impact")
                            .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        Text("Your daily CO₂ footprint")
                            .font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 16)

                // Status
                VStack(spacing: 6) {
                    Text(statusMessage.0)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(statusMessage.1)
                    Text("Energy: \(Int(game.energy))%")
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity).padding(16)
                .background(Color(red: 0.14, green: 0.14, blue: 0.13)).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
                .padding(.horizontal, 20)

                // Energy bar
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ENERGY LEVEL")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.18, green: 0.18, blue: 0.17))
                                .frame(height: 20)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(energyBarColor)
                                .frame(width: geo.size.width * CGFloat(game.energy / 100), height: 20)
                                .animation(.easeInOut(duration: 0.5), value: game.energy)
                        }
                    }
                    .frame(height: 20)
                }
                .padding(.horizontal, 20)

                // Session time card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("CURRENT SESSION")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                    }

                    HStack(spacing: 16) {
                        SessionStat(icon: "clock.fill", value: sessionFormatted, label: "Time in app")
                        SessionStat(icon: "bolt.fill", value: "\(Int(game.energy))%", label: "Energy left")
                        SessionStat(icon: "leaf.fill",
                                    value: String(format: "%.0fg", Double(game.screenTimeMinutes) * 0.3),
                                    label: "CO₂ est.")
                    }
                }
                .padding(.horizontal, 20)

                // Tips
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ECO TIPS")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    EcoTipCard(icon: "moon.fill",
                               title: "Use Dark Mode",
                               description: "OLED screens use less energy with dark pixels.",
                               color: Color(red: 0.15, green: 0.12, blue: 0.22))

                    EcoTipCard(icon: "wifi.slash",
                               title: "Disconnect When Idle",
                               description: "Turn off Wi-Fi and data when not in use.",
                               color: Color(red: 0.12, green: 0.18, blue: 0.22))

                    EcoTipCard(icon: "arrow.down.circle.fill",
                               title: "Reduce Streaming Quality",
                               description: "Lower resolution saves bandwidth and CO₂.",
                               color: Color(red: 0.18, green: 0.15, blue: 0.10))

                    EcoTipCard(icon: "trash.fill",
                               title: "Delete Unused Apps",
                               description: "Background processes drain battery and energy.",
                               color: Color(red: 0.20, green: 0.12, blue: 0.12))
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(red: 0.10, green: 0.10, blue: 0.09))
    }

    private var energyBarColor: Color {
        if game.energy > 70 { return .green }
        if game.energy > 40 { return .yellow }
        return .red
    }
}

// MARK: - Session Stat

private struct SessionStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.orange)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(red: 0.14, green: 0.14, blue: 0.13))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07)))
    }
}

// MARK: - Eco Tip Card

private struct EcoTipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(14)
        .background(color)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06)))
        .padding(.horizontal, 20)
    }
}
