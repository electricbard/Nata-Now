import SwiftUI

struct NearArrivalView: View {
    let tier: SearchTier
    @State private var isPulsing = false

    var body: some View {
        Text(tier == .nata ? "🥧" : "☕")
            .font(.system(size: 40))
            .scaleEffect(isPulsing ? 1.15 : 1.0)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}
