//
//  Lab.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/21/25.
//

import SwiftUI


struct MyCustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Example: Draw a triangle
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))        // Top
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))     // Bottom right
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))     // Bottom left
        path.closeSubpath()                                       // Close the triangle

        return path
    }
}
//
//struct TopCapsuleShape: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//
//        // Draw top arc (semi-circle)
//        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY),
//                    radius: rect.width / 2,
//                    startAngle: .degrees(180),
//                    endAngle: .degrees(0),
//                    clockwise: false)
//
//        // Draw vertical lines down from arc to mid-height
//        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
//        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
//
//        // Close the shape
//        path.closeSubpath()
//
//        return path
//    }
//}

struct Lab: View {
    var body: some View {
         ZStack(alignment: .top) {
             // Bottom capsule (full height)
//             Capsule()
//                 .fill(Color.blue.opacity(0.3))
//                 .frame(width: 60, height: 200)

             // Top capsule (50% height, darker)
//             Capsule()
//                 .fill(Color.blue)
//                 .frame(width: 60, height: 90) // 50% of 200
//             
             
             TopCapsuleShape().fill(LinearGradient(
                gradient: Gradient(colors: [
                   Color.red.opacity(0.8),
                   Color.red.opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ))
          .frame(width: 60, height: 30)
          .offset(y: 30)
             
             Capsule()
                 .fill(Color.blue.opacity(0.3))
                 .frame(width: 60, height: 200)
                 
         }
     }
}

#Preview {
    Lab()
}
