import SwiftUI

struct CompassView: View {
    @ObservedObject var viewModel: CompassViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLaunching {
                LaunchScreen()
            } else {
                compassContent
            }
        }
        .ignoresSafeArea()
    }

    private var compassContent: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - 22

            ZStack {
                CompassDial(
                    heading: viewModel.heading,
                    locations: viewModel.locations,
                    highlightedID: viewModel.tappedLocation?.id ?? viewModel.highlightedLocation?.id,
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
    }

    private func handleTap(at point: CGPoint, center: CGPoint, radius: CGFloat) {
        let rotation = Angle.degrees(-viewModel.heading)
        let hitRadius: CGFloat = 24

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

// MARK: - Launch Screen

struct LaunchScreen: View {
    @State private var isPulsing = false

    var body: some View {
        Text("🔮")
            .font(.system(size: 60))
            .scaleEffect(isPulsing ? 1.15 : 1.0)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - Compass Dial (Canvas)

struct CompassDial: View {
    let heading: Double
    let locations: [NataLocation]
    let highlightedID: UUID?   // Facing or tapped — shown at 100%
    let nearestID: UUID?       // Nearest — orange-red dot
    let radius: CGFloat

    private let fullIconSize: CGFloat = 36
    private let fullEmojiSize: CGFloat = 24

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
                    context.stroke(path, with: .color(.red), lineWidth: 3)
                    let labelPoint = pointOnCircle(center: center, radius: radius - 22, angle: tickAngle)
                    let text = Text("N").font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                    context.draw(context.resolve(text), at: labelPoint)
                } else {
                    context.stroke(path, with: .color(.gray), lineWidth: 1.5)
                }
            }

            // Draw location markers on the dial circumference
            for location in locations {
                let markerAngle = Angle.degrees(location.bearing) + rotation
                let markerCenter = pointOnCircle(center: center, radius: radius, angle: markerAngle)
                let isHighlighted = location.id == highlightedID
                let isNearest = location.id == nearestID

                let scale: CGFloat = isHighlighted ? 1.0 : 0.75
                let iconSize = fullIconSize * scale
                let emojiSize = fullEmojiSize * scale

                // Orange-red dot at fixed inner radius for nearest location
                if isNearest {
                    let dotRadius = radius - fullIconSize / 2 - 10
                    let dotCenter = pointOnCircle(center: center, radius: dotRadius, angle: markerAngle)
                    let dotRect = CGRect(x: dotCenter.x - 4, y: dotCenter.y - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: dotRect), with: .color(Color(red: 1.0, green: 0.35, blue: 0.1)))
                }

                // Icon background circle
                let bgRect = CGRect(
                    x: markerCenter.x - iconSize / 2,
                    y: markerCenter.y - iconSize / 2,
                    width: iconSize,
                    height: iconSize
                )
                context.fill(Path(ellipseIn: bgRect), with: .color(.black))

                // Emoji
                let emoji: String
                switch location.tier {
                case .nata: emoji = "🥧"
                case .cafe: emoji = "☕"
                case .bakery: emoji = "🥐"
                }
                let emojiText = Text(emoji).font(.system(size: emojiSize))
                context.draw(context.resolve(emojiText), at: markerCenter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
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

    private var displayLocation: NataLocation? {
        viewModel.tappedLocation ?? viewModel.highlightedLocation
    }

    var body: some View {
        Group {
            if viewModel.isNearArrival, let location = viewModel.highlightedLocation {
                NearArrivalView(tier: location.tier)
            } else if let location = displayLocation {
                VStack(spacing: 4) {
                    Text(location.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 120)
                    DistanceReadout(distance: location.distance)
                }
            } else if viewModel.hasSearched {
                Text("😢")
                    .font(.system(size: 36))
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
    }
}
