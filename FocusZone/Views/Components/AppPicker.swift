
import SwiftUI

struct AppPicker<T: Hashable & CustomStringConvertible>: View {
    var title: String
    var options: [T]
    @Binding var selection: T

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary)
            Picker(title, selection: $selection) {
                ForEach(options, id: \ .self) { item in
                    Text(item.description).tag(item)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.card)
            .cornerRadius(10)
        }
    }
}
