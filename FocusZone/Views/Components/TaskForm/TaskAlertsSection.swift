import SwiftUI

struct TaskAlertsSection: View {
    @Binding var alerts: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Needs alerts?")
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.pink)
                    Text("Nudge")
                        .font(.system(size: 16))
                        .foregroundColor(.pink)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(alerts, id: \.self) { alert in
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.pink)
                        Text(alert)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) {
                                alerts.removeAll(where: { $0 == alert })
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                
                // Pro alerts
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.gray)
                    Text("At end of task")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .strikethrough()
                    Spacer()
                    Text("PRO")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
                
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.gray)
                    Text("5m before start")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .strikethrough()
                    Spacer()
                    Text("PRO")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
                
                Button("+ Add Alert") {
                    // Add alert functionality
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
    }
}

#Preview {
    @State var alerts = ["At start of task"]
    
    return TaskAlertsSection(alerts: $alerts)
}