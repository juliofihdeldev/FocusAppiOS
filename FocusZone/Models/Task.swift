import SwiftUI
import SwiftData
import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "inProgress"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
}

@Model
class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var icon: String
    var startTime: Date
    var durationMinutes: Int
    var isCompleted: Bool
    var taskTypeRawValue: String?
    var statusRawValue: String
    var timeSpentMinutes: Int
    var actualStartTime: Date?
    var repeatRuleRawValue: String
    var createdAt: Date
    var updatedAt: Date
    
    // Simple color storage as string
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        startTime: Date,
        durationMinutes: Int,
        color: Color = .blue,
        isCompleted: Bool = false,
        taskType: TaskType? = nil,
        status: TaskStatus = .scheduled,
        timeSpentMinutes: Int = 0,
        actualStartTime: Date? = nil,
        repeatRule: RepeatRule = .once
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
        self.taskTypeRawValue = taskType?.rawValue
        self.statusRawValue = status.rawValue
        self.timeSpentMinutes = timeSpentMinutes
        self.actualStartTime = actualStartTime
        self.repeatRuleRawValue = repeatRule.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        self.colorHex = color.toHex()
    }
    
    // Computed properties
    var color: Color {
        get {
            Color(hex: colorHex) ?? .blue
        }
        set {
            colorHex = newValue.toHex()
            updatedAt = Date()
        }
    }
    
    var taskType: TaskType? {
        get {
            guard let rawValue = taskTypeRawValue else { return nil }
            return TaskType(rawValue: rawValue)
        }
        set {
            taskTypeRawValue = newValue?.rawValue
            updatedAt = Date()
        }
    }
    
    var status: TaskStatus {
        get {
            TaskStatus(rawValue: statusRawValue) ?? .scheduled
        }
        set {
            statusRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    var repeatRule: RepeatRule {
        get {
            RepeatRule(rawValue: repeatRuleRawValue) ?? .once
        }
        set {
            repeatRuleRawValue = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    // Computed properties for task timing
    var isScheduled: Bool {
        status == .scheduled
    }
    
    var isActive: Bool {
        status == .inProgress
    }
    
    var isPaused: Bool {
        status == .paused
    }
    
    var isFinished: Bool {
        status == .completed || isCompleted
    }
    
    var remainingMinutes: Int {
        max(0, durationMinutes - timeSpentMinutes)
    }
    
    var progressPercentage: Double {
        guard durationMinutes > 0 else { return 0 }
        return min(1.0, Double(timeSpentMinutes) / Double(durationMinutes))
    }
    
    var estimatedEndTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
}

// Helper extensions for Color conversion
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
