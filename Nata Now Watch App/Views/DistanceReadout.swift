import SwiftUI
import CoreLocation

struct DistanceReadout: View {
    let distance: CLLocationDistance

    var body: some View {
        VStack(spacing: 2) {
            Text(formattedDistance)
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundColor(.white)

            if distance >= 1000 {
                Text("km")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            } else {
                Text("m")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
    }

    private var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.1f", distance / 1000)
        } else {
            return "\(Int(distance))"
        }
    }
}
