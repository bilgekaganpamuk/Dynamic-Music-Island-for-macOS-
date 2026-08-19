import SwiftUI

/// Daily hydration tracker with liquid glass visualizer.
public struct HydrationWidgetView: View {
    @AppStorage("DailyHydrationCups") private var cupsDrank: Int = 4
    private let targetCups: Int = 8

    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            // Water Glass Graphic
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 48, height: 64)
                    .background(Color.white.opacity(0.04))

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.85), Color.blue.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: max(6, CGFloat(cupsDrank) / CGFloat(targetCups) * 60))
                    .padding(2)
                    .animation(Constants.Animation.liquidSpring, value: cupsDrank)

                VStack(spacing: 0) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Text("\(cupsDrank)/\(targetCups)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.dailyHydration)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                Text(cupsDrank >= targetCups ? L10n.goalReached : L10n.cupsLeft(count: targetCups - cupsDrank))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button {
                        if cupsDrank < targetCups + 4 {
                            withAnimation { cupsDrank += 1 }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                            Text(L10n.drinkCup)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.8))
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    if cupsDrank > 0 {
                        Button {
                            withAnimation { cupsDrank -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Button(L10n.clear) {
                        withAnimation { cupsDrank = 0 }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
