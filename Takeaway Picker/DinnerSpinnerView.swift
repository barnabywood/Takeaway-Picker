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
            let wheelSize = min(proxy.size.width * 0.86, proxy.size.height * 0.62, 360)
            let hubSize = max(108, wheelSize * 0.34)

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                ZStack {
                    DinnerPointer()
                        .frame(width: wheelSize * 0.20, height: wheelSize * 0.16)
                        .offset(y: -(wheelSize * 0.52))
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
                            .stroke(Color.white.opacity(0.92), lineWidth: max(10, wheelSize * 0.035))
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.72), lineWidth: max(5, wheelSize * 0.018))
                            .padding(max(20, wheelSize * 0.065))
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
                                VStack(spacing: 4) {
                                    Text(hasSpunOnce ? "Tonight" : "Swipe")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.black.opacity(0.48))
                                        .textCase(.uppercase)

                                    Text(hasSpunOnce ? currentChoice : "to spin")
                                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.62)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 10)
                                }
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
                    .accessibilityHint("Swipe or tap to spin")
                }
                .frame(width: wheelSize, height: wheelSize + 34)

                Text(isSpinning ? "Spinning..." : (hasSpunOnce ? "Dinner picked" : "Swipe the wheel"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.86))
                    .textCase(.uppercase)
                    .tracking(1.6)

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
            let angle = Angle.degrees(360.0 / Double(count))

            for index in 0..<count {
                let start = Angle.degrees(-90) + angle * Double(index)
                let end = start + angle
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                path.closeSubpath()

                let color = colors[index % colors.count]
                context.fill(
                    path,
                    with: .radialGradient(
                        Gradient(colors: [
                            color.opacity(0.82),
                            color,
                            color.opacity(0.72)
                        ]),
                        center: center,
                        startRadius: radius * 0.12,
                        endRadius: radius
                    )
                )

                context.stroke(path, with: .color(.black.opacity(0.78)), lineWidth: max(4, radius * 0.035))
            }
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
