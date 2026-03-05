import Foundation
import Combine
import UserNotifications

enum RobotMood: Equatable {
    case happy, hungry, tired, curious, bored
}

class GameManager: ObservableObject {

    @Published var hunger: Double = 85
    @Published var energy: Double = 72
    @Published var education: Double = 60
    @Published var sociality: Double = 90
    @Published var showOveruseWarning: Bool = false
    @Published var screenTimeMinutes: Int = 0

    private var decayTimer: AnyCancellable?
    private var sessionTimer: AnyCancellable?
    private var sessionSeconds: Int = 0
    private let overuseThreshold: Int = 300
    private var lastNotificationTime: [String: Date] = [:]
    private let notificationCooldown: TimeInterval = 300

    init() {
        requestNotificationPermission()
        startDecayTimer()
        startSessionTimer()
    }

    // MARK: - Mood
    var currentMood: RobotMood {
        let values: [(String, Double)] = [
            ("hunger", hunger), ("energy", energy),
            ("education", education), ("sociality", sociality)
        ]
        let minEntry = values.min(by: { $0.1 < $1.1 })!
        if minEntry.1 > 60 { return .happy }
        switch minEntry.0 {
        case "hunger":    return .hungry
        case "energy":    return .tired
        case "education": return .curious
        default:          return .bored
        }
    }

    // MARK: - Stat Mutators
    func increaseHunger(by amount: Double = 8)      { hunger    = min(100, hunger + amount) }
    func increaseEnergy(by amount: Double = 8)       { energy    = min(100, energy + amount) }
    func increaseEducation(by amount: Double = 12)   { education = min(100, education + amount) }
    func increaseSociality(by amount: Double = 10)   { sociality = min(100, sociality + amount) }
    func decreaseEnergy(by amount: Double = 5)       { energy    = max(0, energy - amount) }

    // MARK: - Decay Timer
    private func startDecayTimer() {
        decayTimer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.decayRandomStat() }
    }

    private func decayRandomStat() {
        let amount = Double.random(in: 0.5...3.0)
        switch Int.random(in: 0...3) {
        case 0: hunger    = max(0, hunger - amount);    checkAndNotify(stat: "hunger",    value: hunger)
        case 1: energy    = max(0, energy - amount);    checkAndNotify(stat: "energy",    value: energy)
        case 2: education = max(0, education - amount); checkAndNotify(stat: "education", value: education)
        default: sociality = max(0, sociality - amount); checkAndNotify(stat: "sociality", value: sociality)
        }
    }

    // MARK: - Session Timer
    private func startSessionTimer() {
        sessionTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.sessionSeconds += 1
                self.screenTimeMinutes = self.sessionSeconds / 60
                if self.sessionSeconds >= self.overuseThreshold && !self.showOveruseWarning {
                    self.showOveruseWarning = true
                    self.decreaseEnergy()
                }
            }
    }

    func dismissOveruseWarning() {
        showOveruseWarning = false
        sessionSeconds = 0
    }

    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func checkAndNotify(stat: String, value: Double) {
        guard value < 50 else { return }
        if let last = lastNotificationTime[stat],
           Date().timeIntervalSince(last) < notificationCooldown { return }
        lastNotificationTime[stat] = Date()
        sendNotification(for: stat)
    }

    private func sendNotification(for stat: String) {
        let content = UNMutableNotificationContent()
        switch stat {
        case "hunger":
            content.title = "Polly is getting hungry"
            content.body  = "Too much unused data is stored. Let's clean it up."
        case "energy":
            content.title = "Polly is tired"
            content.body  = "Too much screen time drains energy."
        case "education":
            content.title = "Polly needs to learn"
            content.body  = "Take a quick quiz and grow awareness."
        default:
            content.title = "Polly feels lonely"
            content.body  = "Chat with Rob8 to boost sociality."
        }
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id = "\(stat)-\(Date().timeIntervalSince1970)"
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }
}
