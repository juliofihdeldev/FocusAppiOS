//
//  TopCapsuleShape.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/21/25.
//

import SwiftUI


struct TopCapsuleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Draw top arc (semi-circle)
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY),
                    radius: rect.width / 2,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false)

        // Draw vertical lines down from arc to mid-height
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))

        // Close the shape
        path.closeSubpath()

        return path
    }
}

#Preview {
    TopCapsuleShape()
}
