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

    private var previousChoice: String {
        guard !choices.isEmpty else { return "Dinner" }
        return choices[(currentIndex - 1 + choices.count) % choices.count]
    }

    private var nextChoice: String {
        guard !choices.isEmpty else { return "Dinner" }
        return choices[(currentIndex + 1) % choices.count]
    }

    var body: some View {
        GeometryReader { proxy in
            let wheelSize = min(proxy.size.width * 0.92, proxy.size.height * 0.66, 410)
            let hubSize = max(112, wheelSize * 0.33)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    DinnerPointer()
                        .frame(width: wheelSize * 0.25, height: wheelSize * 0.20)
                        .offset(y: -(wheelSize * 0.54))
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
                .frame(width: wheelSize, height: wheelSize + 30)

                if hasSpunOnce || isSpinning {
                    DinnerChoiceTicker(
                        previousChoice: previousChoice,
                        currentChoice: currentChoice,
                        nextChoice: nextChoice
                    )
                    .frame(width: min(wheelSize * 0.74, 290))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(currentChoice)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct DinnerChoiceTicker: View {
    let previousChoice: String
    let currentChoice: String
    let nextChoice: String

    var body: some View {
        VStack(spacing: 0) {
            Text(previousChoice)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.34))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(currentChoice)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.56)
                .padding(.vertical, 2)

            Text(nextChoice)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.34))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.76),
                            Color(red: 0.14, green: 0.08, blue: 0.045).opacity(0.84)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.30),
                                    Color(red: 1.0, green: 0.72, blue: 0.24).opacity(0.36),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.36), radius: 16, x: 0, y: 8)
        }
        .overlay {
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.42), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                Spacer()

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.42)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .animation(.snappy(duration: 0.18), value: currentChoice)
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
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let jewelSize = min(width, height) * 0.32

            ZStack {
                RoulettePointer()
                    .fill(Color.black.opacity(0.58))
                    .blur(radius: 5)
                    .offset(y: 5)

                RoulettePointer()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.98, green: 0.93, blue: 0.78),
                                Color(red: 0.78, green: 0.70, blue: 0.54)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoulettePointer()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.92),
                                        Color(red: 0.34, green: 0.22, blue: 0.10).opacity(0.72)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: max(2, width * 0.035)
                            )
                    }
                    .overlay(alignment: .topLeading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.64))
                            .frame(width: width * 0.34, height: height * 0.08)
                            .blur(radius: 1.2)
                            .offset(x: width * 0.26, y: height * 0.18)
                    }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color(red: 1.0, green: 0.82, blue: 0.32),
                                Color(red: 0.42, green: 0.24, blue: 0.08)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: jewelSize
                        )
                    )
                    .frame(width: jewelSize, height: jewelSize)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.26), lineWidth: max(1, width * 0.016))
                    }
                    .offset(y: -(height * 0.15))
                    .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.26).opacity(0.44), radius: 8)
            }
        }
        .shadow(color: .black.opacity(0.34), radius: 12, x: 0, y: 8)
    }
}

private struct RoulettePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.18, y: rect.minY + height * 0.30),
            control1: CGPoint(x: rect.midX - width * 0.28, y: rect.maxY - height * 0.16),
            control2: CGPoint(x: rect.minX + width * 0.06, y: rect.minY + height * 0.60)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + width * 0.31, y: rect.minY + height * 0.08),
            control: CGPoint(x: rect.minX + width * 0.18, y: rect.minY + height * 0.08)
        )
        path.addLine(to: CGPoint(x: rect.maxX - width * 0.31, y: rect.minY + height * 0.08))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - width * 0.18, y: rect.minY + height * 0.30),
            control: CGPoint(x: rect.maxX - width * 0.18, y: rect.minY + height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX - width * 0.06, y: rect.minY + height * 0.60),
            control2: CGPoint(x: rect.midX + width * 0.28, y: rect.maxY - height * 0.16)
        )
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
