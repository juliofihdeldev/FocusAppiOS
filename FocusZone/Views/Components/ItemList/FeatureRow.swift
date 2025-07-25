//
//  FeatureRow.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    FeatureRow(icon: "square.and.arrow.up", title: "Title", description: "Lorem ipsum")
}
