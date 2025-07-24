import SwiftUI

// MARK: - Break Suggestion Card Component
struct BreakSuggestionCard: View {
    let suggestion: BreakSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main suggestion row
            HStack(spacing: 12) {
                // Timeline connector
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 15)
                    
                    Circle()
                        .fill(suggestion.type.color.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(suggestion.type.color, lineWidth: 2)
                        )
                        .overlay(
                            Text("?")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(suggestion.type.color)
                        )
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 15)
                }
                .frame(width: 60) // Match TaskCard timeline width
                
                // Suggestion content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(suggestion.type.color)
                            .font(.system(size: 14))
                        
                        Text(timeUntilText)
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text(suggestion.icon)
                            .font(.title3)
                        
                        Text("Plan a \(suggestion.type.displayName.lowercased()) in \(timeUntilText)?")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text(suggestion.reason)
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(suggestion.type.color.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(suggestion.type.color.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Expanded actions
            if isExpanded {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button(action: onAccept) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add \(suggestion.suggestedDuration)m break")
                                    .font(AppFonts.caption())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(suggestion.type.color)
                            .cornerRadius(20)
                        }
                        
                        Button(action: {
                            withAnimation(.easeOut) {
                                onDismiss()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                Text("Not now")
                                    .font(AppFonts.caption())
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 88) // Align with text content
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    private var timeUntilText: String {
        if suggestion.timeUntilOptimal <= 0 {
            return "now"
        } else if suggestion.timeUntilOptimal < 60 {
            return "\(suggestion.timeUntilOptimal)m"
        } else {
            let hours = suggestion.timeUntilOptimal / 60
            let minutes = suggestion.timeUntilOptimal % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

#Preview {
    BreakSuggestionCard(
        suggestion: BreakSuggestion(
            type: .snack,
            suggestedDuration: 15,
            reason: "Perfect time for a snack",
            icon: "🍎",
            timeUntilOptimal: 34,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date().addingTimeInterval(34 * 60)
        ),
        onAccept: { print("Accepted break suggestion") },
        onDismiss: { print("Dismissed break suggestion") }
    )
    .padding()
    .background(AppColors.background)
}
