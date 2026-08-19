import SwiftUI

/// Dynamic notch widget displaying today's date, day of week, and upcoming calendar schedule.
public struct CalendarWidgetView: View {
    @State private var widgetManager = WidgetManager.shared

    public init() {}

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date()).uppercased()
    }

    private var dateNumberString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Calendar Date Icon Badge
            VStack(spacing: 0) {
                Text(dayString)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(Color.red)

                Text(dateNumberString)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.12))
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )

            // Events List
            VStack(alignment: .leading, spacing: 3) {
                Text("Today's Schedule")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                if widgetManager.calendarEvents.isEmpty {
                    Text("No events today")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(widgetManager.calendarEvents.prefix(2), id: \.self) { event in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 5, height: 5)
                            Text(event)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
