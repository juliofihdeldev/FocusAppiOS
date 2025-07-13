import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var input: String = ""
    @State private var isRecording: Bool = false
    @State private var recentChats: [ChatPreview] = [
        ChatPreview(title: "Daily Schedule", preview: "Plan my day with meetings", time: "2m ago"),
        ChatPreview(title: "Focus Session", preview: "45 min deep work block", time: "1h ago"),
        ChatPreview(title: "Break Reminder", preview: "Added 5 min breaks", time: "3h ago")
    ]
    @State private var quickActions: [QuickAction] = [
        QuickAction(icon: "calendar.badge.plus", title: "Schedule", subtitle: "Plan my day"),
        QuickAction(icon: "brain.head.profile", title: "Focus", subtitle: "Deep work session"),
        QuickAction(icon: "figure.walk", title: "Break", subtitle: "Add rest periods"),
        QuickAction(icon: "chart.line.uptrend.xyaxis", title: "Analytics", subtitle: "View insights")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with greeting
                    headerSection
                    
                    // Quick Actions Grid
                    quickActionsSection
                    
                    // Recent Conversations
                    recentChatsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(theme.currentBackground)
            .overlay(
                // Floating Input Bar
                floatingInputBar,
                alignment: .bottom
            )
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good afternoon")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                    
                    Text("What can I help you with?")
                        .font(AppFonts.headline())
                        .foregroundColor(theme.currentTextColor)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.accent)
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(AppFonts.subheadline())
                .foregroundColor(theme.currentTextColor)
                .fontWeight(.medium)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(quickActions) { action in
                    QuickActionCard(action: action) {
                        input = action.subtitle
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Chats Section
    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent")
                    .font(AppFonts.subheadline())
                    .foregroundColor(theme.currentTextColor)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("See all") {
                    // Navigate to chat history
                }
                .font(AppFonts.caption())
                .foregroundColor(AppColors.accent)
            }
            
            VStack(spacing: 12) {
                ForEach(recentChats) { chat in
                    ChatPreviewRow(chat: chat)
                }
            }
        }
    }
    
    // MARK: - Floating Input Bar
    private var floatingInputBar: some View {
        VStack(spacing: 0) {
            // Suggestion pills
            if !input.isEmpty {
                suggestionPills
            }
            
            // Input container
            HStack(spacing: 12) {
                // Voice input button
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.title3)
                        .foregroundColor(isRecording ? .red : .gray)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                        )
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isRecording)
                }
                
                // Text input
                HStack(spacing: 8) {
                    TextField("Ask me anything...", text: $input)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AppFonts.body())
                    
                    if !input.isEmpty {
                        Button(action: clearInput) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppColors.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(input.isEmpty ? Color.clear : AppColors.accent, lineWidth: 1)
                        )
                )
                
                // Send button
                Button(action: sendPrompt) {
                    Image(systemName: "arrow.up")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(input.isEmpty ? Color.gray : AppColors.accent)
                        )
                        .scaleEffect(input.isEmpty ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: input.isEmpty)
                }
                .disabled(input.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(theme.currentBackground)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
        }
    }
    
    // MARK: - Suggestion Pills
    private var suggestionPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(getSmartSuggestions(), id: \.self) { suggestion in
                    Button(action: {
                        input = suggestion
                    }) {
                        Text(suggestion)
                            .font(AppFonts.caption())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppColors.accent.opacity(0.1))
                            )
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Functions
    private func sendPrompt() {
        guard !input.isEmpty else { return }
        print("User asked: \(input)")
        input = ""
    }
    
    private func clearInput() {
        input = ""
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func getSmartSuggestions() -> [String] {
        // Return contextual suggestions based on input
        if input.lowercased().contains("schedule") {
            return ["Plan my morning", "Add meeting", "Check conflicts"]
        } else if input.lowercased().contains("focus") {
            return ["25 min session", "Deep work block", "Pomodoro timer"]
        } else {
            return ["Plan my day", "Set focus time", "Add break"]
        }
    }
}

// MARK: - Supporting Views and Models
struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct ChatPreview: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let time: String
}

struct QuickActionCard: View {
    let action: QuickAction
    let onTap: () -> Void
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(AppColors.accent)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(AppFonts.subheadline())
                        .foregroundColor(theme.currentTextColor)
                        .fontWeight(.medium)
                    
                    Text(action.subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChatPreviewRow: View {
    let chat: ChatPreview
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Chat icon
            Image(systemName: "message.circle.fill")
                .font(.title2)
                .foregroundColor(AppColors.accent)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(AppColors.accent.opacity(0.1))
                )
            
            // Chat content
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.title)
                    .font(AppFonts.subheadline())
                    .foregroundColor(theme.currentTextColor)
                    .fontWeight(.medium)
                
                Text(chat.preview)
                    .font(AppFonts.caption())
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time
            Text(chat.time)
                .font(AppFonts.caption())
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Navigate to chat
        }
    }
}

#Preview {
    AIAssistantView()
        .environmentObject(ThemeManager())
}
