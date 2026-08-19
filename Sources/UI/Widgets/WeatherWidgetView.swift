import SwiftUI

/// Dynamic notch widget displaying current weather, temperature, and condition forecast.
public struct WeatherWidgetView: View {
    @State private var widgetManager = WidgetManager.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            // Weather Icon & Temperature
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.4), .cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)

                Image(systemName: widgetManager.weatherIcon)
                    .font(.system(size: 26))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
            }

            // City & Temperature Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(widgetManager.weatherCity)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text(widgetManager.weatherTemp)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.cyan)
                }

                Text(widgetManager.weatherCondition)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                Text("H: \(widgetManager.weatherHighLow)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
