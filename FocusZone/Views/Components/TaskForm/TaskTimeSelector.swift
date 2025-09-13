import SwiftUI

struct TaskTimeSelector: View {
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @State private var showingTimePicker: Bool = false
    @State private var showingDatePicker: Bool = false
    
    // Time picker state
    @State private var selectedHour: Int = 12
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: TimePeriod = .am
    
    enum TimePeriod: String, CaseIterable {
        case am = "AM"
        case pm = "PM"
    }
    
    private var selectedTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(selectedDate)
    }
    
    private var dateDisplayString: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            return selectedDateString
        }
    }
    
    private var hours: [Int] {
        Array(1...12)
    }
    
    private var minutes: [Int] {
        Array(stride(from: 0, to: 60, by: 5))
    }
    
    private var periods: [TimePeriod] {
        TimePeriod.allCases
    }
    
    private func updateStartTime() {
        let calendar = Calendar.current
        var hour24 = selectedHour
        
        if selectedPeriod == .pm && selectedHour != 12 {
            hour24 += 12
        } else if selectedPeriod == .am && selectedHour == 12 {
            hour24 = 0
        }
        
        if let newStartTime = calendar.date(bySettingHour: hour24,
              minute: selectedMinute,
              second: 0,
              of: selectedDate) {
            startTime = newStartTime
        }
    }
    
    private func loadCurrentTime() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)
        
        // Convert to 12-hour format
        if hour == 0 {
            selectedHour = 12
            selectedPeriod = .am
        } else if hour < 12 {
            selectedHour = hour
            selectedPeriod = .am
        } else if hour == 12 {
            selectedHour = 12
            selectedPeriod = .pm
        } else {
            selectedHour = hour - 12
            selectedPeriod = .pm
        }
        
        // Round to nearest 5 minutes
        selectedMinute = (minute / 5) * 5
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        updateStartTime()
    }
    
    private func quickDateSelection(_ daysOffset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: daysOffset, to: Date()) {
            selectDate(newDate)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(NSLocalizedString("when", comment: "When question for time selection"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                  
                Spacer()
                
                Button(NSLocalizedString("more", comment: "More button for time selection")) {
                    showingTimePicker.toggle()
                    if showingTimePicker {
                        loadCurrentTime()
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.blue)
            }
            
            if showingTimePicker {
                VStack(spacing: 20) {
                    // Quick date selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("quick_select", comment: "Quick select section title"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button(NSLocalizedString("today", comment: "Today button")) {
                                quickDateSelection(0)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isToday ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isToday ? Color.blue : Color.blue.opacity(0.1))
                            )
                            
                            Button(NSLocalizedString("tomorrow", comment: "Tomorrow button")) {
                                quickDateSelection(1)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isTomorrow ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isTomorrow ? Color.blue : Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("select_date", comment: "Select date label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            .onChange(of: selectedDate) { newDate in
                                selectDate(newDate)
                            }
                    }
                    
                    // Native-style time picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("select_time", comment: "Select time label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TimePickerView(
                            selectedHour: $selectedHour,
                            selectedMinute: $selectedMinute,
                            selectedPeriod: $selectedPeriod,
                            hours: hours,
                            minutes: minutes,
                            periods: periods
                        )
                        .onChange(of: selectedHour) { _ in updateStartTime() }
                        .onChange(of: selectedMinute) { _ in updateStartTime() }
                        .onChange(of: selectedPeriod) { _ in updateStartTime() }
                    }
                }
            } else {
                // Compact view
                VStack(spacing: 12) {
                    // Time display
                    Text(selectedTimeString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.blue)
                        )
                        .onTapGesture {
                            showingTimePicker.toggle()
                            if showingTimePicker {
                                loadCurrentTime()
                            }
                        }
                    
                    // Date display
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(dateDisplayString)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        Spacer()
                        
                        Button(NSLocalizedString("change", comment: "Change button for time selection")) {
                            showingTimePicker.toggle()
                            if showingTimePicker {
                                loadCurrentTime()
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        }
    }
}

struct TimePickerView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var selectedPeriod: TaskTimeSelector.TimePeriod
    
    let hours: [Int]
    let minutes: [Int]
    let periods: [TaskTimeSelector.TimePeriod]
    
    var body: some View {
        HStack(spacing: 0) {
            // Hours column
            Picker("Hour", selection: $selectedHour) {
                ForEach(hours, id: \.self) { hour in
                    Text("\(hour)")
                        .tag(hour)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Minutes column
            Picker("Minute", selection: $selectedMinute) {
                ForEach(minutes, id: \.self) { minute in
                    Text(String(format: "%02d", minute))
                        .tag(minute)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
            
            // AM/PM column
            Picker("Period", selection: $selectedPeriod) {
                ForEach(periods, id: \.self) { period in
                    Text(period.rawValue)
                        .tag(period)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .overlay(
            // Selection highlight
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    @State var date = Date()
    @State var time = Date()
    
    return TaskTimeSelector(
        selectedDate: $date,
        startTime: $time
    )
}
