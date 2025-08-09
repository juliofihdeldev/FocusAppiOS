import SwiftUI

struct WeeklyPlanPreviewState: Identifiable {
    let id = UUID()
    var changes: [PlannedChange]
}

struct WeeklyPlanPreviewSheet: View {
    let state: WeeklyPlanPreviewState
    @State private var selection: [Bool]
    let onApply: ([PlannedChange]) -> Void
    let onUndo: () -> Void

    init(state: WeeklyPlanPreviewState, onApply: @escaping ([PlannedChange]) -> Void, onUndo: @escaping () -> Void) {
        self.state = state
        self.onApply = onApply
        self.onUndo = onUndo
        self._selection = State(initialValue: Array(repeating: true, count: state.changes.count))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(Array(state.changes.enumerated()), id: \.offset) { idx, change in
                        HStack(alignment: .top, spacing: 12) {
                            Toggle("", isOn: Binding(get: { selection[idx] }, set: { selection[idx] = $0 }))
                                .labelsHidden()
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title(for: change))
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.textPrimary)
                                Text(detail(for: change))
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)

                HStack(spacing: 12) {
                    // Undo button - glass outline style
                    Button(action: { onUndo() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo last")
                        }
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(LinearGradient(
                                    colors: [AppColors.accent.opacity(0.9), AppColors.accent.opacity(0.3)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(CapsulePressStyle())

                    // Apply button - prominent gradient capsule
                    Button(action: {
                        let selected = zip(state.changes, selection).compactMap { $1 ? $0 : nil }
                        onApply(selected)
                    }) {
                        let selectedCount = selection.filter { $0 }.count
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.white)
                            Text("Apply Selected")
                                .foregroundColor(.white)
                            if selectedCount > 0 {
                                Text("(\(selectedCount))")
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .font(AppFonts.body())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [AppColors.accent, AppColors.accent.opacity(0.85)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                                .blendMode(.overlay)
                        )
                        .shadow(color: AppColors.accent.opacity(0.25), radius: 14, x: 0, y: 10)
                        .opacity(selection.contains(true) ? 1 : 0.6)
                    }
                    .disabled(!selection.contains(true))
                    .buttonStyle(CapsulePressStyle())
                }
                .padding(16)
            }
            .navigationTitle("Weekly Plan Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func title(for change: PlannedChange) -> String {
        switch change {
        case .moveTask: return "Move Task"
        case .createBreak: return "Add Break"
        case .splitTask: return "Split Task"
        case .addFocusBlock: return "Add Focus Block"
        }
    }

    private func detail(for change: PlannedChange) -> String {
        switch change {
        case let .moveTask(_, toStart):
            return "New start: \(DateFormatter.shortTime.string(from: toStart))"
        case let .createBreak(_, minutes):
            return "Break: \(minutes)m"
        case let .splitTask(_, chunks):
            return "Chunks: \(chunks.map(String.init).joined(separator: "+"))m"
        case let .addFocusBlock(date, durationMinutes, title):
            return "\(title) — \(durationMinutes)m at \(DateFormatter.shortTime.string(from: date))"
        }
    }
}

// Press feedback for capsule-styled buttons
private struct CapsulePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

fileprivate extension DateFormatter {
    static let shortTime: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()
}

// MARK: - Preview

#Preview {
    let now = Date()
    let sampleChanges: [PlannedChange] = [
        .moveTask(taskId: UUID(), toStart: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: now) ?? now),
        .createBreak(beforeTaskId: UUID(), minutes: 10),
        .splitTask(taskId: UUID(), chunksMinutes: [45, 45]),
        .addFocusBlock(date: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now, durationMinutes: 60, title: "Catch-up Focus (Auto)")
    ]
    let state = WeeklyPlanPreviewState(changes: sampleChanges)
    WeeklyPlanPreviewSheet(state: state) { _ in } onUndo: {}
}


