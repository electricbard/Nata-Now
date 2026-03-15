import SwiftUI

struct CompassView: View {
    @ObservedObject var viewModel: CompassViewModel

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - 22 // Margin for 36pt icons sitting on the dial

            ZStack {
                Color.black.ignoresSafeArea()

                // Compass dial — rotates opposite to heading
                CompassDial(
                    heading: viewModel.heading,
                    locations: viewModel.locations,
                    highlightedID: viewModel.highlightedLocation?.id,
                    nearestID: viewModel.nearestLocation?.id,
                    radius: radius
                )
                .position(center)

                // Centre content: distance, sad face, or near-arrival throb
                CentreContent(viewModel: viewModel)
                    .position(center)
            }
            .onTapGesture { tapLocation in
                handleTap(at: tapLocation, center: center, radius: radius)
            }
        }
        .ignoresSafeArea()
    }

    private func handleTap(at point: CGPoint, center: CGPoint, radius: CGFloat) {
        let rotation = Angle.degrees(-viewModel.heading)
        let hitRadius: CGFloat = 24 // Generous for watch taps

        for location in viewModel.locations {
            let markerAngle = Angle.degrees(location.bearing) + rotation
            let radians = markerAngle.radians - .pi / 2
            let markerCenter = CGPoint(
                x: center.x + radius * cos(radians),
                y: center.y + radius * sin(radians)
            )

            let dx = point.x - markerCenter.x
            let dy = point.y - markerCenter.y
            if sqrt(dx * dx + dy * dy) <= hitRadius {
                viewModel.tapLocation(location)
                return
            }
        }
    }
}

// MARK: - Compass Dial (Canvas)

struct CompassDial: View {
    let heading: Double
    let locations: [NataLocation]
    let highlightedID: UUID?   // Facing — white ring
    let nearestID: UUID?       // Nearest — orange-red ring
    let radius: CGFloat

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rotation = Angle.degrees(-heading)

            // Collect bearings of location markers for tick occlusion
            let markerBearings = locations.map { $0.bearing }

            // Draw tick marks
            for i in 0..<36 {
                let angle = Double(i) * 10.0
                let isNorth = i == 0

                // Check if this tick is occluded by a marker (within 10 degrees)
                let isOccluded = markerBearings.contains { bearing in
                    let diff = abs(angle - bearing).truncatingRemainder(dividingBy: 360)
                    return min(diff, 360 - diff) < 10
                }

                guard !isOccluded else { continue }

                let tickAngle = Angle.degrees(angle) + rotation
                let outerPoint = pointOnCircle(center: center, radius: radius, angle: tickAngle)
                let tickLength: CGFloat = isNorth ? 14 : 8
                let innerPoint = pointOnCircle(center: center, radius: radius - tickLength, angle: tickAngle)

                var path = Path()
                path.move(to: outerPoint)
                path.addLine(to: innerPoint)

                if isNorth {
                    // North: draw a red triangle
                    context.stroke(path, with: .color(.red), lineWidth: 3)

                    // Draw "N" label
                    let labelPoint = pointOnCircle(center: center, radius: radius - 22, angle: tickAngle)
                    let text = Text("N").font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                    context.draw(context.resolve(text), at: labelPoint)
                } else {
                    context.stroke(path, with: .color(.gray), lineWidth: 1.5)
                }
            }

            // Draw location markers — on the dial circumference
            let iconSize: CGFloat = 36
            for location in locations {
                let markerAngle = Angle.degrees(location.bearing) + rotation
                let markerCenter = pointOnCircle(center: center, radius: radius, angle: markerAngle)
                let isFacing = location.id == highlightedID
                let isNearest = location.id == nearestID

                // Determine ring color: orange-red for nearest, white for facing-only
                // If both, orange-red wins
                if isNearest {
                    let ringPath = Path(ellipseIn: CGRect(
                        x: markerCenter.x - iconSize / 2 - 5,
                        y: markerCenter.y - iconSize / 2 - 5,
                        width: iconSize + 10,
                        height: iconSize + 10
                    ))
                    context.stroke(ringPath, with: .color(Color(red: 1.0, green: 0.35, blue: 0.1)), lineWidth: 2.5)
                } else if isFacing {
                    let ringPath = Path(ellipseIn: CGRect(
                        x: markerCenter.x - iconSize / 2 - 5,
                        y: markerCenter.y - iconSize / 2 - 5,
                        width: iconSize + 10,
                        height: iconSize + 10
                    ))
                    context.stroke(ringPath, with: .color(.white), lineWidth: 2.5)
                }

                // Icon background circle
                let bgRect = CGRect(
                    x: markerCenter.x - iconSize / 2,
                    y: markerCenter.y - iconSize / 2,
                    width: iconSize,
                    height: iconSize
                )
                context.fill(Path(ellipseIn: bgRect), with: .color(.black))

                // Draw emoji for tier
                let emoji = location.tier == .nata ? "🥧" : "☕"
                let emojiText = Text(emoji).font(.system(size: 24))
                context.draw(context.resolve(emojiText), at: markerCenter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        // Angle measured from top (12 o'clock), clockwise
        let radians = angle.radians - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }
}

// MARK: - Centre Content

struct CentreContent: View {
    @ObservedObject var viewModel: CompassViewModel

    var body: some View {
        Group {
            if let tapped = viewModel.tappedLocation {
                // Tapped location: show name + distance
                VStack(spacing: 4) {
                    Text(tapped.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 120)
                    DistanceReadout(distance: tapped.distance)
                }
            } else if viewModel.isNearArrival, let location = viewModel.highlightedLocation {
                // Throbbing icon for near-arrival
                NearArrivalView(tier: location.tier)
            } else if let location = viewModel.highlightedLocation {
                // Distance readout
                DistanceReadout(distance: location.distance)
            } else if viewModel.hasSearched {
                // Empty state: sad face
                Text("😢")
                    .font(.system(size: 36))
            } else {
                // Still loading
                ProgressView()
                    .tint(.white)
            }
        }
    }
}
