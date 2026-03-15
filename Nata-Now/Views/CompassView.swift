import SwiftUI

struct CompassView: View {
    @ObservedObject var viewModel: CompassViewModel

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - 36 // Margin for icons on the dial

            ZStack {
                Color.black.ignoresSafeArea()

                CompassDial(
                    heading: viewModel.heading,
                    locations: viewModel.locations,
                    highlightedID: viewModel.highlightedLocation?.id,
                    nearestID: viewModel.nearestLocation?.id,
                    radius: radius
                )
                .position(center)

                CentreContent(viewModel: viewModel)
                    .position(center)
            }
            .onTapGesture { tapLocation in
                handleTap(at: tapLocation, center: center, radius: radius)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    private func handleTap(at point: CGPoint, center: CGPoint, radius: CGFloat) {
        let rotation = Angle.degrees(-viewModel.heading)
        let hitRadius: CGFloat = 36

        for location in viewModel.locations {
            let markerAngle = Angle.degrees(location.bearing) + rotation
            let radians = CGFloat(markerAngle.radians - .pi / 2)
            let markerCenter = CGPoint(
                x: center.x + radius * Foundation.cos(radians),
                y: center.y + radius * Foundation.sin(radians)
            )

            let dx = point.x - markerCenter.x
            let dy = point.y - markerCenter.y
            let dist = Foundation.sqrt(dx * dx + dy * dy)
            if dist <= hitRadius {
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

            let markerBearings = locations.map { $0.bearing }

            // Draw tick marks
            for i in 0..<36 {
                let angle = Double(i) * 10.0
                let isNorth = i == 0

                let isOccluded = markerBearings.contains { bearing in
                    let diff = abs(angle - bearing).truncatingRemainder(dividingBy: 360)
                    return min(diff, 360 - diff) < 8
                }

                guard !isOccluded else { continue }

                let tickAngle = Angle.degrees(angle) + rotation
                let outerPoint = pointOnCircle(center: center, radius: radius, angle: tickAngle)
                let tickLength: CGFloat = isNorth ? 24 : 14
                let innerPoint = pointOnCircle(center: center, radius: radius - tickLength, angle: tickAngle)

                var path = Path()
                path.move(to: outerPoint)
                path.addLine(to: innerPoint)

                if isNorth {
                    context.stroke(path, with: .color(.red), lineWidth: 4)

                    let labelPoint = pointOnCircle(center: center, radius: radius - 36, angle: tickAngle)
                    let text = Text("N").font(.system(size: 20, weight: .bold)).foregroundColor(.red)
                    context.draw(context.resolve(text), at: labelPoint)
                } else {
                    context.stroke(path, with: .color(.gray), lineWidth: 2)
                }
            }

            // Draw location markers on the dial circumference
            let iconSize: CGFloat = 48
            for location in locations {
                let markerAngle = Angle.degrees(location.bearing) + rotation
                let markerCenter = pointOnCircle(center: center, radius: radius, angle: markerAngle)
                let isFacing = location.id == highlightedID
                let isNearest = location.id == nearestID

                // Orange-red for nearest, white for facing-only. If both, orange-red wins.
                if isNearest {
                    let ringPath = Path(ellipseIn: CGRect(
                        x: markerCenter.x - iconSize / 2 - 6,
                        y: markerCenter.y - iconSize / 2 - 6,
                        width: iconSize + 12,
                        height: iconSize + 12
                    ))
                    context.stroke(ringPath, with: .color(Color(red: 1.0, green: 0.35, blue: 0.1)), lineWidth: 3)
                } else if isFacing {
                    let ringPath = Path(ellipseIn: CGRect(
                        x: markerCenter.x - iconSize / 2 - 6,
                        y: markerCenter.y - iconSize / 2 - 6,
                        width: iconSize + 12,
                        height: iconSize + 12
                    ))
                    context.stroke(ringPath, with: .color(.white), lineWidth: 3)
                }

                let bgRect = CGRect(
                    x: markerCenter.x - iconSize / 2,
                    y: markerCenter.y - iconSize / 2,
                    width: iconSize,
                    height: iconSize
                )
                context.fill(Path(ellipseIn: bgRect), with: .color(.black))

                let emoji = location.tier == .nata ? "🥧" : "☕"
                let emojiText = Text(emoji).font(.system(size: 32))
                context.draw(context.resolve(emojiText), at: markerCenter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let radians = CGFloat(angle.radians - .pi / 2)
        return CGPoint(
            x: center.x + radius * Foundation.cos(radians),
            y: center.y + radius * Foundation.sin(radians)
        )
    }
}

// MARK: - Centre Content

struct CentreContent: View {
    @ObservedObject var viewModel: CompassViewModel

    var body: some View {
        Group {
            if let tapped = viewModel.tappedLocation {
                VStack(spacing: 8) {
                    Text(tapped.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                    DistanceReadout(distance: tapped.distance)
                }
            } else if viewModel.isNearArrival, let location = viewModel.highlightedLocation {
                NearArrivalView(tier: location.tier)
            } else if let location = viewModel.highlightedLocation {
                DistanceReadout(distance: location.distance)
            } else if viewModel.hasSearched {
                Text("😢")
                    .font(.system(size: 64))
            } else {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }
}
