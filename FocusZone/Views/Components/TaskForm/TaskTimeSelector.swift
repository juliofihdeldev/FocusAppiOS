import SwiftUI

struct TaskTimeSelector: View {
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    @State private var showingTimeSlots: Bool = false
    
    private var timeSlots: [String] {
        generateTimeSlots()
    }
    
    private var selectedTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func generateTimeSlots() -> [String] {
        var slots: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        // Generate time slots from 6:00 AM to 11:45 PM in 15-minute intervals
        for hour in 6...23 {
            for minute in stride(from: 0, to: 60, by: 30) {
                if let timeSlot = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                   let finalTime = calendar.date(byAdding: .minute, value: minute, to: timeSlot) {
                    slots.append(formatter.string(from: finalTime))
                }
            }
        }
        
        return slots
    }
    
    private func selectTime(_ timeString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            if let newStartTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                              minute: timeComponents.minute ?? 0,
                                              second: 0,
                                              of: selectedDate) {
                startTime = newStartTime
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("When?")
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
                Button("More...") {
                    showingTimeSlots.toggle()
                }
                .font(.system(size: 16))
                .foregroundColor(.pink)
            }
            
            if showingTimeSlots {
                VStack(spacing: 12) {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(timeSlots, id: \.self) { time in
                                Button(action: {
                                    selectTime(time)
                                }) {
                                    HStack {
                                        Text(time)
                                            .font(.system(size: 16))
                                            .foregroundColor(time == selectedTimeString ? .white : .gray)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(time == selectedTimeString ? Color.pink : Color.clear)
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    
                    // Date
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .padding(.top, 10)
                }
            } else {
                Text(selectedTimeString)
                    .font(AppFonts.body())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.pink)
                    )
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.pink)
                    Text(selectedDateString)
                        .font(AppFonts.body())
                        .foregroundColor(.pink)
                    Spacer()
                }
            }
        }
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
