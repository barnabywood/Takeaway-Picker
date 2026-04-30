import SwiftUI

struct DinnerSpinnerView: View {
    let choices: [String]
    let currentIndex: Int
    let rotation: Double
    let isSpinning: Bool
    let hasSpunOnce: Bool
    let onSpin: () -> Void

    private let wheelColors: [Color] = [
        Color(red: 0.98, green: 0.16, blue: 0.12),
        Color(red: 1.00, green: 0.47, blue: 0.05),
        Color(red: 1.00, green: 0.80, blue: 0.12),
        Color(red: 0.04, green: 0.72, blue: 0.36),
        Color(red: 0.16, green: 0.30, blue: 0.92),
        Color(red: 0.55, green: 0.14, blue: 0.84)
    ]

    private var currentChoice: String {
        guard !choices.isEmpty else { return "Dinner" }
        return choices[currentIndex % choices.count]
    }

    var body: some View {
        GeometryReader { proxy in
            let wheelSize = min(proxy.size.width * 0.92, proxy.size.height * 0.66, 410)
            let hubSize = max(112, wheelSize * 0.33)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    DinnerPointer()
                        .frame(width: wheelSize * 0.22, height: wheelSize * 0.18)
                        .offset(y: -(wheelSize * 0.535))
                        .zIndex(4)

                    DinnerWheel(
                        choices: choices,
                        colors: wheelColors
                    )
                    .rotationEffect(.degrees(rotation))
                    .frame(width: wheelSize, height: wheelSize)
                    .shadow(color: .black.opacity(0.55), radius: 28, x: 0, y: 18)
                    .overlay {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color.white.opacity(0.98),
                                        Color(red: 1.0, green: 0.78, blue: 0.34),
                                        Color.white.opacity(0.72),
                                        Color(red: 0.34, green: 0.20, blue: 0.10),
                                        Color.white.opacity(0.98)
                                    ],
                                    center: .center
                                ),
                                lineWidth: max(14, wheelSize * 0.044)
                            )
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.82), lineWidth: max(8, wheelSize * 0.024))
                            .padding(max(24, wheelSize * 0.072))
                    }
                    .overlay {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.92),
                                        Color.white.opacity(0.72),
                                        Color.black.opacity(0.12)
                                    ],
                                    center: .topLeading,
                                    startRadius: 4,
                                    endRadius: hubSize
                                )
                            )
                            .frame(width: hubSize, height: hubSize)
                            .overlay {
                                Circle()
                                    .stroke(Color.black.opacity(0.80), lineWidth: max(6, wheelSize * 0.018))
                                    .padding(hubSize * 0.24)
                            }
                            .overlay {
                                ZStack {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: hubSize * 0.26, weight: .bold))
                                        .foregroundColor(.black.opacity(hasSpunOnce || isSpinning ? 0.10 : 0.58))

                                    if hasSpunOnce || isSpinning {
                                        Text(currentChoice)
                                            .font(.system(size: 25, weight: .black, design: .rounded))
                                            .foregroundColor(.black)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.55)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 12)
                                    }
                                }
                            }
                            .overlay(alignment: .topLeading) {
                                Circle()
                                    .fill(Color.white.opacity(0.42))
                                    .frame(width: hubSize * 0.22, height: hubSize * 0.22)
                                    .blur(radius: 2)
                                    .offset(x: hubSize * 0.17, y: hubSize * 0.15)
                            }
                            .shadow(color: .black.opacity(0.48), radius: 14, x: 0, y: 8)
                    }
                    .overlay(alignment: .bottom) {
                        if hasSpunOnce {
                            Text(currentChoice)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(1.1)
                                .textCase(.uppercase)
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.black.opacity(0.55))
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                        )
                                )
                                .offset(y: wheelSize * 0.13)
                        }
                    }
                    .scaleEffect(isSpinning ? 1.025 : 1)
                    .gesture(
                        DragGesture(minimumDistance: 14)
                            .onEnded { value in
                                let travel = hypot(value.translation.width, value.translation.height)
                                if travel > 28 {
                                    onSpin()
                                }
                            }
                    )
                    .onTapGesture {
                        onSpin()
                    }
                    .accessibilityLabel("Dinner spinner")
                    .accessibilityHint("Swipe or tap the wheel to spin")
                }
                .frame(width: wheelSize, height: wheelSize + (hasSpunOnce ? wheelSize * 0.18 : 30))

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct DinnerWheel: View {
    let choices: [String]
    let colors: [Color]

    var body: some View {
        Canvas { context, size in
            let count = max(choices.count, 1)
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(size.width, size.height) / 2
            let segmentDegrees = 360.0 / Double(count)
            let pocketInnerRadius = radius * 0.78
            let pocketOuterRadius = radius * 0.94
            let foodInnerRadius = radius * 0.22
            let foodOuterRadius = radius * 0.76

            func ringSegment(startDegrees: Double, endDegrees: Double, innerRadius: CGFloat, outerRadius: CGFloat) -> Path {
                var path = Path()
                let startAngle = Angle.degrees(startDegrees)
                let endAngle = Angle.degrees(endDegrees)
                path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                path.closeSubpath()
                return path
            }

            let table = Path(ellipseIn: rect.insetBy(dx: radius * 0.035, dy: radius * 0.035))
            context.fill(
                table,
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.10, green: 0.04, blue: 0.025),
                        Color.black
                    ]),
                    center: center,
                    startRadius: radius * 0.18,
                    endRadius: radius
                )
            )

            for index in 0..<count {
                let start = -90.0 + segmentDegrees * Double(index)
                let end = start + segmentDegrees
                let foodPath = ringSegment(
                    startDegrees: start + 1.4,
                    endDegrees: end - 1.4,
                    innerRadius: foodInnerRadius,
                    outerRadius: foodOuterRadius
                )
                let color = colors[index % colors.count]
                context.fill(
                    foodPath,
                    with: .radialGradient(
                        Gradient(colors: [
                            color.opacity(0.98),
                            color,
                            color.opacity(0.54)
                        ]),
                        center: center,
                        startRadius: foodInnerRadius,
                        endRadius: foodOuterRadius
                    )
                )
                context.stroke(foodPath, with: .color(.black.opacity(0.72)), lineWidth: max(2, radius * 0.014))

                let pocketPath = ringSegment(
                    startDegrees: start + 0.8,
                    endDegrees: end - 0.8,
                    innerRadius: pocketInnerRadius,
                    outerRadius: pocketOuterRadius
                )
                let pocketColor: Color = index == 0
                    ? Color(red: 0.02, green: 0.45, blue: 0.23)
                    : (index.isMultiple(of: 2) ? Color(red: 0.92, green: 0.06, blue: 0.04) : Color(red: 0.045, green: 0.04, blue: 0.038))

                context.fill(
                    pocketPath,
                    with: .radialGradient(
                        Gradient(colors: [
                            pocketColor.opacity(0.92),
                            pocketColor.opacity(0.58)
                        ]),
                        center: center,
                        startRadius: pocketInnerRadius,
                        endRadius: pocketOuterRadius
                    )
                )
                context.stroke(pocketPath, with: .color(.white.opacity(0.16)), lineWidth: max(1, radius * 0.006))

                let midDegrees = start + (segmentDegrees / 2)
                let radians = midDegrees * Double.pi / 180
                let dotRadius = radius * 0.855
                let dotCenter = CGPoint(
                    x: center.x + cos(radians) * dotRadius,
                    y: center.y + sin(radians) * dotRadius
                )
                let dotSize = max(5, radius * 0.045)
                let dotRect = CGRect(
                    x: dotCenter.x - dotSize / 2,
                    y: dotCenter.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color.white,
                            Color(red: 1.0, green: 0.83, blue: 0.34)
                        ]),
                        center: dotCenter,
                        startRadius: 1,
                        endRadius: dotSize
                    )
                )

                let spokeRadians = start * Double.pi / 180
                var spoke = Path()
                spoke.move(to: CGPoint(
                    x: center.x + cos(spokeRadians) * foodInnerRadius,
                    y: center.y + sin(spokeRadians) * foodInnerRadius
                ))
                spoke.addLine(to: CGPoint(
                    x: center.x + cos(spokeRadians) * pocketOuterRadius,
                    y: center.y + sin(spokeRadians) * pocketOuterRadius
                ))
                context.stroke(spoke, with: .color(.white.opacity(0.18)), lineWidth: max(1.4, radius * 0.008))
            }

            let innerTrack = Path(ellipseIn: CGRect(
                x: center.x - pocketInnerRadius,
                y: center.y - pocketInnerRadius,
                width: pocketInnerRadius * 2,
                height: pocketInnerRadius * 2
            ))
            context.stroke(innerTrack, with: .color(.black.opacity(0.72)), lineWidth: max(4, radius * 0.024))

            let hubSeat = Path(ellipseIn: CGRect(
                x: center.x - foodInnerRadius,
                y: center.y - foodInnerRadius,
                width: foodInnerRadius * 2,
                height: foodInnerRadius * 2
            ))
            context.fill(
                hubSeat,
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.08, green: 0.065, blue: 0.06),
                        Color.black
                    ]),
                    center: center,
                    startRadius: 1,
                    endRadius: foodInnerRadius
                )
            )
            context.stroke(hubSeat, with: .color(.white.opacity(0.18)), lineWidth: max(2, radius * 0.012))
        }
        .clipShape(Circle())
        .overlay {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.02),
                            Color.black.opacity(0.18)
                        ],
                        center: .topLeading,
                        startRadius: 12,
                        endRadius: 330
                    )
                )
                .blendMode(.screen)
        }
    }
}

private struct DinnerPointer: View {
    var body: some View {
        Triangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 0.88, green: 0.89, blue: 0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 5)
            .overlay {
                Triangle()
                    .stroke(Color.black.opacity(0.16), lineWidth: 1)
            }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct DinnerSpinnerBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.055),
                    Color(red: 0.12, green: 0.06, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.78, blue: 0.24).opacity(0.28),
                    Color(red: 0.96, green: 0.18, blue: 0.12).opacity(0.10),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [
                    Color("AccentGreen").opacity(0.16),
                    Color.clear
                ],
                center: .center,
                startRadius: 70,
                endRadius: 480
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.72)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        DinnerSpinnerBackground()
        DinnerSpinnerView(
            choices: ["Indian", "Pizza", "Thai", "Burgers", "Sushi", "Pasta"],
            currentIndex: 0,
            rotation: 24,
            isSpinning: false,
            hasSpunOnce: true,
            onSpin: {}
        )
    }
}
