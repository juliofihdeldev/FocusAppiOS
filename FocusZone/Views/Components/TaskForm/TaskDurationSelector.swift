import SwiftUI

struct TaskDurationSelector: View {
    @Binding var duration: Int
    
    let durations = [15, 30, 45, 60, 90, 120, 240]
    
    private func durationDisplayText(_ minutes: Int) -> String {
        switch minutes {
        case 15: return "15m"
        case 30: return "30m"
        case 45: return "45m"
        case 60: return "1h"
        case 90: return "1.5h"
        case 120: return "2h"
        case 240: return "4h"
        default:
            if minutes < 60 {
                return "\(minutes)m"
            } else {
                let hours = minutes / 60
                let remainingMinutes = minutes % 60
                if remainingMinutes == 0 {
                    return "\(hours)h"
                } else {
                    return "\(hours)h \(remainingMinutes)m"
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("How long?")
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
                Button("More...") {}
                    .font(.system(size: 16))
                    .foregroundColor(.pink)
            }
            
            HStack(spacing: 0) {
                ForEach(Array(durations.enumerated()), id: \.offset) { index, d in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            duration = d
                        }
                    }) {
                        Text(durationDisplayText(d))
                            .font(AppFonts.caption())
                            .foregroundColor(duration == d ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(duration == d ? Color.pink : Color.gray.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < durations.count - 1 {
                        Spacer().frame(width: 8)
                    }
                }
            }
        }
    }
}

#Preview {
    @State var duration = 90
    return TaskDurationSelector(duration: $duration)
}
