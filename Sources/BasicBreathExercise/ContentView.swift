import SwiftUI

struct ContentView: View {
    @ObservedObject var session: BreathSession

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            Group {
                switch session.state {
                case .idle:
                    PickerView(session: session)
                case .countdown, .breathing:
                    RunningView(session: session)
                case .finished:
                    FinishedView(session: session)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            Divider().opacity(0.4)
            footer
        }
        .frame(width: 300)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "wind")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Basic Breath Exercise")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Toggle(isOn: $session.soundEnabled) {
                Label("Ses", systemImage: session.soundEnabled ? "speaker.wave.2" : "speaker.slash")
                    .font(.system(size: 11))
            }
            .toggleStyle(.button)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            Spacer()
            Button("Çıkış") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Süre seçimi

private struct PickerView: View {
    @ObservedObject var session: BreathSession

    var body: some View {
        VStack(spacing: 14) {
            TrafficLight(active: nil)
            VStack(spacing: 4) {
                Text("Bir dakika dur, nefes al.")
                    .font(.system(size: 14, weight: .medium))
                Text("4 sn al · 7 sn tut · 8 sn ver")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ForEach([1, 2, 3], id: \.self) { m in
                    Button {
                        session.start(minutes: m)
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(m)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("dk · \(m * BreathSession.cyclesPerMinute) tur")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Egzersiz

private struct RunningView: View {
    @ObservedObject var session: BreathSession

    private var phase: BreathPhase? {
        if case .breathing(let p, _) = session.state { return p }
        return nil
    }

    private var bigNumber: Int {
        switch session.state {
        case .countdown(let n): return n
        case .breathing(_, let r): return r
        default: return 0
        }
    }

    private var circleScale: CGFloat {
        switch phase {
        case .inhale?, .hold?: return 1.0
        default: return 0.5
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            TrafficLight(active: phase)

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 2)
                Circle()
                    .fill((phase?.color ?? .gray).opacity(0.22))
                    .overlay(Circle().stroke(phase?.color ?? .gray, lineWidth: 3))
                    // Animasyon yalnızca ölçeğe uygulanır; konum ve renk anında değişir.
                    .animation(.easeInOut(duration: Double(phase?.duration ?? 1))) {
                        $0.scaleEffect(circleScale)
                    }
                VStack(spacing: 2) {
                    Text("\(bigNumber)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy, value: bigNumber)
                    Text(phase?.title ?? "Hazırlan")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .frame(width: 170, height: 170)

            Text(phase?.hint ?? "Rahat bir pozisyon al")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ProgressView(value: session.progress)
                    .progressViewStyle(.linear)
                    .tint(phase?.color ?? .gray)
                HStack {
                    Text(session.cycle > 0 ? "Tur \(session.cycle)/\(session.totalCycles)" : "\(session.minutes) dk · \(session.totalCycles) tur")
                    Spacer()
                    Text(timeLeft)
                        .monospacedDigit()
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Button("Durdur") { session.stop() }
                .controlSize(.small)
        }
    }

    private var timeLeft: String {
        let left = max(0, session.totalDuration - session.elapsed)
        return String(format: "%d:%02d", left / 60, left % 60)
    }
}

// MARK: - Bitti

private struct FinishedView: View {
    @ObservedObject var session: BreathSession

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 36))
                .foregroundStyle(BreathPhase.inhale.color)
            Text("Tamamlandı")
                .font(.system(size: 16, weight: .semibold))
            Text("\(session.totalCycles) tur nefes egzersizi yaptın.\nNasıl hissediyorsun?")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("Tekrarla") { session.start(minutes: session.minutes) }
                Button("Kapat") { session.reset() }
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Trafik ışığı

struct TrafficLight: View {
    let active: BreathPhase?

    var body: some View {
        HStack(spacing: 14) {
            lamp(.inhale)
            lamp(.hold)
            lamp(.exhale)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.75)))
    }

    private func lamp(_ p: BreathPhase) -> some View {
        let on = active == p
        return VStack(spacing: 3) {
            Circle()
                .fill(p.color.opacity(on ? 1 : 0.18))
                .frame(width: 22, height: 22)
                .shadow(color: on ? p.color.opacity(0.9) : .clear, radius: 8)
            Text("\(p.duration)s")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(on ? 0.95 : 0.4))
        }
        .animation(.easeInOut(duration: 0.25), value: on)
    }
}
