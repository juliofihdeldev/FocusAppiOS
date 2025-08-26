//
//  FeatureRow.swift
//  FocusZone
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI

struct FeatureRow_: View {
    let icon: String
    let title: String
    let delay: Double
    let description: String
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Text
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FeatureRow_(
            icon: "infinity.circle.fill",
            title: "Unlimited Tasks",
            delay: 0.0,
            description:"Focus on what really matters."
        
        )
        
        FeatureRow_(
            icon: "chart.line.uptrend.xyaxis",
            title: "Advanced Analytics",
            delay: 0.1,
            description: "Get insights into your productivity."
        )
        
        FeatureRow_(
            icon: "brain.head.profile",
            title: "AI Assistant",
            delay: 0.2,
            description: "Let the AI help you boost your productivity."
        )
    }
    .padding()
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.8),
                Color.blue.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

