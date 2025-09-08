import SwiftUI

// MARK: - Break Suggestion Card Component with Swipe Gestures
struct BreakSuggestionCard: View {
    let suggestion: BreakSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isBeingDragged = false
    @State private var showingActionHint = false
    
    // Swipe thresholds
    private let acceptThreshold: CGFloat = 80
    private let dismissThreshold: CGFloat = -80
    private let hapticThreshold: CGFloat = 60
    
    @State private var hasTriggeredAcceptHaptic = false
    @State private var hasTriggeredDismissHaptic = false
    
    var body: some View {
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
            
            // Suggestion content with swipe overlay
            ZStack {
                // Background action indicators
                HStack {
                    // Left side - Dismiss action
                    if dragOffset.width < -20 {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("dismiss", comment: "Dismiss button"))
                                    .font(AppFonts.caption())
                                    .foregroundColor(.red)
                                Text(NSLocalizedString("not_interested", comment: "Not interested text"))
                                    .font(AppFonts.caption())
                                    .foregroundColor(.gray)
                            }
                        }
                        .opacity(min(1.0, abs(dragOffset.width) / abs(dismissThreshold)))
                        .scaleEffect(dragOffset.width <= dismissThreshold ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: dragOffset.width <= dismissThreshold)
                    }
                    
                    Spacer()
                    
                    // Right side - Accept action
                    if dragOffset.width > 20 {
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(NSLocalizedString("add_break", comment: "Add break button"))
                                    .font(AppFonts.caption())
                                    .foregroundColor(suggestion.type.color)
                                Text(String(format: NSLocalizedString("minutes", comment: "Minutes format"), suggestion.suggestedDuration))
                                    .font(AppFonts.caption())
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(suggestion.type.color)
                                .font(.title2)
                        }
                        .opacity(min(1.0, dragOffset.width / acceptThreshold))
                        .scaleEffect(dragOffset.width >= acceptThreshold ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: dragOffset.width >= acceptThreshold)
                    }
                }
                .padding(.horizontal, 20)
                
                // Main suggestion content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(suggestion.type.color)
                            .font(.system(size: 14))
                        
                        Text(timeUntilText)
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Swipe hint
                        if !isBeingDragged && showingActionHint {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text(NSLocalizedString("swipe", comment: "Swipe instruction"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .opacity(0.6)
                            .transition(.opacity)
                        }
                    }
                    
                    HStack {
                        Text(suggestion.icon)
                            .font(.title3)
                        
                        Text(String(format: NSLocalizedString("plan_a_break", comment: "Plan a break question"), suggestion.type.displayName.lowercased(), timeUntilText))
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text(suggestion.reason)
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(cardBorderColor, lineWidth: cardBorderWidth)
                        )
                )
                .offset(dragOffset)
                .scaleEffect(isBeingDragged ? 1.02 : 1.0)
                .rotation3DEffect(
                    .degrees(Double(dragOffset.width) * 0.1),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isBeingDragged)
            }
            
            Spacer()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring()) {
                        dragOffset = value.translation
                        isBeingDragged = true
                        showingActionHint = false
                    }
                    
                    // Haptic feedback when reaching thresholds
                    if value.translation.width >= hapticThreshold && !hasTriggeredAcceptHaptic {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        hasTriggeredAcceptHaptic = true
                        hasTriggeredDismissHaptic = false
                    } else if value.translation.width <= -hapticThreshold && !hasTriggeredDismissHaptic {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        hasTriggeredDismissHaptic = true
                        hasTriggeredAcceptHaptic = false
                    } else if abs(value.translation.width) < hapticThreshold {
                        hasTriggeredAcceptHaptic = false
                        hasTriggeredDismissHaptic = false
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        if value.translation.width >= acceptThreshold {
                            // Accept action
                            dragOffset = CGSize(width: 300, height: 0) // Slide off screen
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onAccept()
                            }
                        } else if value.translation.width <= dismissThreshold {
                            // Dismiss action
                            dragOffset = CGSize(width: -300, height: 0) // Slide off screen
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDismiss()
                            }
                        } else {
                            // Snap back to center
                            dragOffset = .zero
                            isBeingDragged = false
                            
                            // Show hint after a moment if user didn't complete the gesture
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showingActionHint = true
                                }
                                
                                // Hide hint after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        showingActionHint = false
                                    }
                                }
                            }
                        }
                    }
                }
        )
        .onAppear {
            // Show initial hint
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingActionHint = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingActionHint = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeUntilText: String {
        if suggestion.timeUntilOptimal <= 0 {
            return NSLocalizedString("now", comment: "Now time indicator")
        } else if suggestion.timeUntilOptimal < 60 {
            return "\(suggestion.timeUntilOptimal)" + NSLocalizedString("m", comment: "Minutes abbreviation")
        } else {
            let hours = suggestion.timeUntilOptimal / 60
            let minutes = suggestion.timeUntilOptimal % 60
            return minutes > 0 ? "\(hours)" + NSLocalizedString("h", comment: "Hours abbreviation") + " \(minutes)" + NSLocalizedString("m", comment: "Minutes abbreviation") : "\(hours)" + NSLocalizedString("h", comment: "Hours abbreviation")
        }
    }
    
    private var cardBackgroundColor: Color {
        if dragOffset.width >= acceptThreshold {
            return suggestion.type.color.opacity(0.15)
        } else if dragOffset.width <= dismissThreshold {
            return Color.red.opacity(0.1)
        } else {
            return suggestion.type.color.opacity(0.05)
        }
    }
    
    private var cardBorderColor: Color {
        if dragOffset.width >= acceptThreshold {
            return suggestion.type.color.opacity(0.6)
        } else if dragOffset.width <= dismissThreshold {
            return Color.red.opacity(0.4)
        } else {
            return suggestion.type.color.opacity(0.2)
        }
    }
    
    private var cardBorderWidth: CGFloat {
        if abs(dragOffset.width) >= hapticThreshold {
            return 2
        } else {
            return 1
        }
    }
}

#Preview {
    VStack(spacing: 20) {
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
        
        BreakSuggestionCard(
            suggestion: BreakSuggestion(
                type: .movement,
                suggestedDuration: 10,
                reason: "Take a walking break",
                icon: "🚶",
                timeUntilOptimal: 15,
                insertAfterTaskId: UUID(),
                suggestedStartTime: Date().addingTimeInterval(15 * 60)
            ),
            onAccept: { print("Accepted break suggestion") },
            onDismiss: { print("Dismissed break suggestion") }
        )
    }
    .padding()
    .background(AppColors.background)
}
