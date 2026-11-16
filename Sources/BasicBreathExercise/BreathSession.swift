import AppKit
import SwiftUI

/// Nefes fazları — 4-7-8 tekniği (Dr. Andrew Weil).
/// 4 sn nefes al + 7 sn tut + 8 sn ver = 19 sn / tur.
/// 3 sn geri sayım + 3 tur × 19 sn = tam 60 sn.
enum BreathPhase: Equatable {
    case inhale, hold, exhale

    var duration: Int {
        switch self {
        case .inhale: return 4
        case .hold:   return 7
        case .exhale: return 8
        }
    }

    var title: String {
        switch self {
        case .inhale: return "Nefes Al"
        case .hold:   return "Tut"
        case .exhale: return "Nefes Ver"
        }
    }

    var hint: String {
        switch self {
        case .inhale: return "Burnundan yavaşça"
        case .hold:   return "Rahat ve sakin"
        case .exhale: return "Ağzından, tamamen boşalt"
        }
    }

    var color: Color {
        switch self {
        case .inhale: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .hold:   return Color(red: 1.00, green: 0.78, blue: 0.10)
        case .exhale: return Color(red: 0.95, green: 0.26, blue: 0.24)
        }
    }

    var nsColor: NSColor { NSColor(color) }

    var next: BreathPhase? {
        switch self {
        case .inhale: return .hold
        case .hold:   return .exhale
        case .exhale: return nil
        }
    }

    static var cycleLength: Int { [BreathPhase.inhale, .hold, .exhale].map(\.duration).reduce(0, +) }
}

enum SessionState: Equatable {
    case idle
    case countdown(Int)
    case breathing(BreathPhase, remaining: Int)
    case finished
}

@MainActor
final class BreathSession: ObservableObject {
    static let countdownSeconds = 3
    static let cyclesPerMinute = 3

    @Published private(set) var state: SessionState = .idle
    @Published private(set) var cycle = 0
    @Published private(set) var totalCycles = 0
    @Published private(set) var elapsed = 0
    @Published private(set) var minutes = 0
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    /// Menü çubuğunu güncellemek için.
    var onChange: (() -> Void)?

    private var timer: Timer?

    init() {
        soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    var totalDuration: Int {
        Self.countdownSeconds + totalCycles * BreathPhase.cycleLength
    }

    var progress: Double {
        totalDuration == 0 ? 0 : min(1, Double(elapsed) / Double(totalDuration))
    }

    func start(minutes: Int) {
        stopTimer()
        self.minutes = minutes
        totalCycles = minutes * Self.cyclesPerMinute
        cycle = 0
        elapsed = 0
        state = .countdown(Self.countdownSeconds)
        playSound("Tink")
        startTimer()
        onChange?()
    }

    func stop() {
        stopTimer()
        state = .idle
        onChange?()
    }

    func reset() {
        state = .idle
        onChange?()
    }

    private func startTimer() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // .common: popover/menü açıkken de çalışsın
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        elapsed += 1
        switch state {
        case .idle, .finished:
            stopTimer()

        case .countdown(let n):
            if n > 1 {
                state = .countdown(n - 1)
                playSound("Tink")
            } else {
                cycle = 1
                enter(.inhale)
            }

        case .breathing(let phase, let remaining):
            if remaining > 1 {
                state = .breathing(phase, remaining: remaining - 1)
            } else if let next = phase.next {
                enter(next)
            } else if cycle < totalCycles {
                cycle += 1
                enter(.inhale)
            } else {
                stopTimer()
                state = .finished
                playSound("Glass")
            }
        }
        onChange?()
    }

    private func enter(_ phase: BreathPhase) {
        state = .breathing(phase, remaining: phase.duration)
        switch phase {
        case .inhale: playSound("Pop")
        case .hold:   playSound("Morse")
        case .exhale: playSound("Bottle")
        }
    }

    private func playSound(_ name: String) {
        guard soundEnabled else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }
}
