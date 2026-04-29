import SwiftUI

/// Procedural slot-machine style cabinet background that scales around the reel.
/// Image-free so it adapts cleanly across iPhone + iPad (including iPhone-compat frames).
struct CabinetBackground: View {
    let title: String
    let reelWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let shortEdge = min(w, h)

            // Use reel width as the main anchor so the background grows/shrinks with the mechanism.
            let u = max(0.70, min(1.20, reelWidth / 220))

            // Cabinet proportions (clamped so it never goes cartoonish on iPad or tiny phones).
            let cabinetWidth = min(w * 0.96, max(reelWidth * 2.12, 320))
            let cabinetHeight = min(h * 0.96, max(h * 0.86, 520))

            let corner: CGFloat = max(28, 52 * u)
            let innerCorner: CGFloat = max(18, 34 * u)

            // Marquee sizing (go big on iPhone, still clamped for iPad)
            let marqueeH: CGFloat = max(120, min(200, 156 * u))
            let marqueeInset: CGFloat = max(14, 18 * u)

            // Window area (where your mechanism sits visually)
            let windowW: CGFloat = max(270, min(cabinetWidth * 0.80, reelWidth * 1.95))
            let windowH: CGFloat = max(280, min(cabinetHeight * 0.48, 390 * u))

            // Side columns
            let columnW: CGFloat = max(22, min(36, 30 * u))

            // Base / plinth
            let baseH: CGFloat = max(96, min(170, 132 * u))

            ZStack {
                // Full-screen theatre backdrop, warm and punchy, but fades to black near the bottom.
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.02, blue: 0.02),
                            Color(red: 0.13, green: 0.03, blue: 0.02),
                            Color(red: 0.26, green: 0.06, blue: 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Hot marquee glow (top)
                    RadialGradient(
                        colors: [
                            Color(red: 1.00, green: 0.80, blue: 0.25).opacity(0.55),
                            Color(red: 1.00, green: 0.30, blue: 0.10).opacity(0.30),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 10,
                        endRadius: max(380, shortEdge * 0.95)
                    )
                    .blendMode(.screen)
                    // Warm cabinet bloom (mid)
                    RadialGradient(
                        colors: [
                            Color(red: 1.00, green: 0.88, blue: 0.40).opacity(0.16),
                            Color(red: 1.00, green: 0.55, blue: 0.18).opacity(0.14),
                            Color(red: 0.20, green: 0.05, blue: 0.02).opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: max(520, shortEdge * 1.10)
                    )
                    .blendMode(.screen)

                    // Slow moving theatre lights to add depth behind the cabinet.
                    StageLightRig(shortEdge: shortEdge)
                        .blendMode(.screen)
                        .opacity(0.68)

                    // Subtle texture so gradients don’t look flat.
                    Canvas { context, size in
                        let rect = CGRect(origin: .zero, size: size)
                        context.addFilter(.blur(radius: 0.6))

                        // A very light “grain” using tiny alpha dots.
                        // We keep it intentionally subtle for performance.
                        for i in 0..<260 {
                            let x = (CGFloat((i * 37) % 997) / 997.0) * size.width
                            let y = (CGFloat((i * 91) % 991) / 991.0) * size.height
                            let r = CGFloat(((i * 13) % 7) + 1)
                            let a = CGFloat(((i * 19) % 10)) / 255.0
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Color.white.opacity(a)))
                        }

                        // A couple of soft warm smudges.
                        context.fill(Path(ellipseIn: rect.insetBy(dx: size.width * 0.18, dy: size.height * 0.30)), with: .radialGradient(
                            Gradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.35).opacity(0.10), .clear]),
                            center: CGPoint(x: size.width * 0.55, y: size.height * 0.30),
                            startRadius: 10,
                            endRadius: max(size.width, size.height) * 0.65
                        ))
                    }
                    .blendMode(.overlay)

                    // Soft vignette to push focus onto the cabinet center.
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.22),
                            Color.black.opacity(0.58)
                        ],
                        center: .center,
                        startRadius: shortEdge * 0.35,
                        endRadius: max(w, h)
                    )
                    .blendMode(.multiply)

                    // Bottom fade to black so buttons sit cleanly.
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.50),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()

                // Cabinet shell
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.05, blue: 0.03),
                                    Color(red: 0.52, green: 0.10, blue: 0.05),
                                    Color(red: 0.86, green: 0.28, blue: 0.08),
                                    Color(red: 1.00, green: 0.68, blue: 0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .fill(
                                    AngularGradient(
                                        colors: [
                                            Color.white.opacity(0.05),
                                            Color(red: 1.00, green: 0.66, blue: 0.20).opacity(0.16),
                                            Color.black.opacity(0.22),
                                            Color.white.opacity(0.04)
                                        ],
                                        center: .center
                                    )
                                )
                                .blendMode(.softLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.88, blue: 0.46).opacity(0.22),
                                            Color.clear
                                        ],
                                        center: .topLeading,
                                        startRadius: 20,
                                        endRadius: max(cabinetWidth * 0.9, cabinetHeight * 0.7)
                                    )
                                )
                                .blendMode(.screen)
                        )
                        .overlay(
                            CabinetPatinaLayer(u: u)
                                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                                .opacity(0.55)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(Color(red: 1.00, green: 0.93, blue: 0.74).opacity(0.22), lineWidth: 1.2)
                        )
                        .shadow(color: .black.opacity(0.78), radius: 34, x: 0, y: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.00, green: 0.96, blue: 0.80).opacity(0.28),
                                            Color(red: 1.00, green: 0.86, blue: 0.42).opacity(0.12),
                                            Color.black.opacity(0.60)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: max(1.0, 2.2 * u)
                                )
                                .blendMode(.screen)
                        )

                    // Inner lip
                    RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        .padding(max(10, 14 * u))


                    // Marquee + flowing colour wash
                    VStack(spacing: 0) {
                        ZStack {
                            ArcBannerShape(curve: 0.24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.70, green: 0.12, blue: 0.05),
                                            Color(red: 0.92, green: 0.22, blue: 0.08),
                                            Color(red: 1.00, green: 0.78, blue: 0.22)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ArcBannerShape(curve: 0.24)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                                .overlay(
                                    // Inner gold trim
                                    ArcBannerShape(curve: 0.24)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.00, green: 0.95, blue: 0.75).opacity(0.75),
                                                    Color(red: 1.00, green: 0.80, blue: 0.28).opacity(0.55),
                                                    Color(red: 0.65, green: 0.22, blue: 0.06).opacity(0.35)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: max(2, 4 * u)
                                        )
                                        .padding(max(6, 8 * u))
                                )
                                .shadow(color: .black.opacity(0.65), radius: 18, x: 0, y: 10)

                            VStack(spacing: max(10, 12 * u)) {
                                Text(title.uppercased())
                                    .font(.system(size: max(34, 58 * u), weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(red: 1.0, green: 0.97, blue: 0.88))
                                    .shadow(color: .black.opacity(0.85), radius: 10, x: 0, y: 5)
                                    .shadow(color: Color(red: 1.0, green: 0.80, blue: 0.25).opacity(0.55), radius: 18, x: 0, y: 0)
                                    .tracking(max(0.5, 1.2 * u))
                                    .padding(.horizontal, 22)

                                // Bulb row (animated) sits clearly BELOW the title
                                BulbRow(count: 12, u: u)
                                    .padding(.bottom, max(6, 8 * u))
                            }
                            .padding(.top, max(8, 10 * u))
                        }
                        .frame(width: cabinetWidth - (marqueeInset * 2), height: marqueeH)
                        .padding(.top, max(12, safeTop + 8))

                        // Extended marquee colour wash (flows down the cabinet).
                        LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.78, blue: 0.22).opacity(0.38),
                                Color(red: 0.95, green: 0.28, blue: 0.10).opacity(0.26),
                                Color(red: 0.12, green: 0.03, blue: 0.02).opacity(0.10),
                                Color.black.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: marqueeH * 2.8)
                        .blendMode(.screen)

                        Spacer(minLength: 0)
                    }

                    // Side columns + cabinet void (no “box frame”)
                    VStack(spacing: 0) {
                        Spacer(minLength: marqueeH + max(30, 36 * u))

                        ZStack {
                            // Warm side light strips (feel like bulbs behind glass)
                            HStack(spacing: 0) {
                                SideGlowStrip(u: u)
                                    .frame(width: columnW)

                                Spacer(minLength: 0)

                                SideGlowStrip(u: u)
                                    .frame(width: columnW)
                            }
                            .frame(width: windowW + (columnW * 2) + max(18, 26 * u), height: windowH)

                            // Cabinet void: an arched cut-out with edge glow.
                            CabinetVoidShape(curve: 0.22)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.22),
                                            Color.black.opacity(0.58),
                                            Color.black.opacity(0.34)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    // Warm inner edge glow (no hard stroke)
                                    CabinetVoidShape(curve: 0.22)
                                        .stroke(Color(red: 1.00, green: 0.86, blue: 0.36).opacity(0.18), lineWidth: max(2, 4 * u))
                                        .blur(radius: 10 * u)
                                        .blendMode(.screen)
                                )
                                .overlay(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 1.00, green: 0.85, blue: 0.35).opacity(0.14),
                                            Color(red: 1.00, green: 0.35, blue: 0.12).opacity(0.10),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 12,
                                        endRadius: max(260, windowW)
                                    )
                                    .blendMode(.screen)
                                )
                                .shadow(color: .black.opacity(0.70), radius: 30, x: 0, y: 18)
                                .frame(width: windowW, height: windowH)
                        }

                        Spacer(minLength: 0)

                        // Base / plinth (warm metal, then fades into black below)
                        ZStack {
                            RoundedRectangle(cornerRadius: max(22, 28 * u), style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.38, green: 0.11, blue: 0.04),
                                            Color(red: 0.22, green: 0.06, blue: 0.03),
                                            Color(red: 0.08, green: 0.03, blue: 0.02),
                                            Color.black
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: max(22, 28 * u), style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.10),
                                                    Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.14),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .blendMode(.softLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: max(22, 28 * u), style: .continuous)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: max(18, 22 * u), style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.08),
                                                    Color.clear,
                                                    Color.black.opacity(0.18)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .padding(.horizontal, max(10, 18 * u))
                                        .padding(.vertical, max(8, 12 * u))
                                )

                            // A soft glow plate (less “box”, more glow)
                            RoundedRectangle(cornerRadius: max(14, 18 * u), style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: max(14, 18 * u), style: .continuous)
                                        .fill(Color(red: 1.0, green: 0.85, blue: 0.30).opacity(0.12))
                                        .blur(radius: 16 * u)
                                        .blendMode(.screen)
                                )
                                .frame(width: min(cabinetWidth * 0.66, 420), height: max(28, 36 * u))
                                .offset(y: -max(12, 14 * u))
                        }
                        .frame(width: cabinetWidth - max(26, 34 * u), height: baseH)
                        .padding(.bottom, max(12, safeBottom + 12))
                    }
                }
                .overlay(alignment: .top) {
                    HeroDetailsLayer(
                        u: u,
                        cabinetWidth: cabinetWidth,
                        cabinetHeight: cabinetHeight,
                        marqueeH: marqueeH,
                        baseH: baseH,
                        safeTop: safeTop,
                        safeBottom: safeBottom
                    )
                    .allowsHitTesting(false)
                }
                .frame(width: cabinetWidth, height: cabinetHeight)
                .position(x: w / 2, y: (h / 2) + (shortEdge > 700 ? 10 : 0))

                // Extra bottom fade so the area behind the buttons is properly black.
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.60),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: h * 0.46)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
}

// MARK: - Components

private struct HeroDetailsLayer: View {
    let u: CGFloat
    let cabinetWidth: CGFloat
    let cabinetHeight: CGFloat
    let marqueeH: CGFloat
    let baseH: CGFloat
    let safeTop: CGFloat
    let safeBottom: CGFloat

    var body: some View {
        ZStack {
            // Stars (classic cabinet vibe)
            // Anchor them INSIDE the cabinet void, just under the marquee, so they never overlap the title or top bulbs.
            let starBandH: CGFloat = max(34, 56 * u)

            // Geometry anchors (all in cabinet coordinates)
            let marqueeTopFromCabinetTop: CGFloat = max(12, safeTop + 8)
            let spacerH: CGFloat = max(30, 36 * u)

            // The void starts after the marquee + the spacer used in the main cabinet layout.
            let voidTopFromCabinetTop: CGFloat = marqueeTopFromCabinetTop + marqueeH + spacerH

            // Sit the stars across the arched "shoulder" of the void.
            // This places them visually between the marquee bulb row and the reel/void content.
            let insetIntoVoid: CGFloat = max(10, 18 * u)
            let starsCenterFromCabinetTop: CGFloat = voidTopFromCabinetTop + insetIntoVoid + (starBandH * 0.5)
            let starsY: CGFloat = -(cabinetHeight / 2) + starsCenterFromCabinetTop

            StarRow(count: 7, u: u)
                .frame(width: cabinetWidth * 0.88, height: starBandH)
                .offset(y: starsY)
                .opacity(0.98)
                .blendMode(.screen)

            // Warm metal glints across the cabinet (subtle, but adds depth)
            MetalGlints(u: u)
                .frame(width: cabinetWidth * 0.92, height: cabinetHeight * 0.86)
                .offset(y: 6)
                .blendMode(.screen)
                .opacity(0.75)

            // Coin stacks (bottom corners)
            // Rotated so the smallest coins read at the top (more like the reference cabinet).
            HStack {
                CoinStack(u: u, height: max(64, 108 * u))
                    .rotationEffect(.degrees(180))
                    .offset(x: -max(10, 18 * u))

                Spacer(minLength: 0)

                CoinStack(u: u, height: max(64, 108 * u))
                    .rotationEffect(.degrees(180))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: max(10, 18 * u))
            }
            .frame(width: cabinetWidth * 0.78)
            .offset(y: (cabinetHeight / 2) - baseH - max(40, 62 * u))
            .opacity(0.95)

            // Bottom marquee bulb strip (sits above the base)
            // Keep it BELOW the coin stacks, brighter, and closer to the base.
            BottomBulbStrip(u: u)
                .frame(width: cabinetWidth * 0.80, height: max(20, 30 * u))
                .offset(y: (cabinetHeight / 2) - baseH - max(4, 8 * u))
        }
    }
}

private struct StarRow: View {
    let count: Int
    let u: CGFloat

    var body: some View {
        HStack(spacing: max(14, 22 * u)) {
            ForEach(0..<count, id: \.self) { _ in
                GlowingStar(u: u)
            }
        }
    }
}

private struct GlowingStar: View {
    let u: CGFloat

    private var shape: StarShape {
        StarShape(points: 5, innerRatio: 0.45)
    }

    private var fillGradient: RadialGradient {
        RadialGradient(
            colors: [
                Color.white,
                Color(red: 1.0, green: 0.95, blue: 0.70),
                Color(red: 1.0, green: 0.74, blue: 0.18)
            ],
            center: .center,
            startRadius: 2,
            endRadius: max(18, 26 * u)
        )
    }

    var body: some View {
        shape
            .fill(fillGradient)
            .overlay(
                shape.stroke(Color.white.opacity(0.35), lineWidth: max(1, 1.6 * u))
            )
            .shadow(
                color: Color(red: 1.0, green: 0.75, blue: 0.20).opacity(0.85),
                radius: max(10, 18 * u),
                x: 0,
                y: 0
            )
            .frame(width: max(20, 34 * u), height: max(20, 34 * u))
    }
}

private struct BottomBulbStrip: View {
    let u: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: max(8, 12 * u)) {
                ForEach(0..<14, id: \.self) { i in
                    let wave = 0.55 + 0.45 * sin((t * 2.0) + (Double(i) * 0.40))
                    let intensity = max(0.0, min(1.0, wave))

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 1.0, green: 0.99, blue: 0.84),
                                    Color(red: 1.0, green: 0.78, blue: 0.22)
                                ],
                                center: .center,
                                startRadius: 1,
                                endRadius: max(12, 16 * u)
                            )
                        )
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.55))
                                .blur(radius: 9 * u)
                                .blendMode(.screen)
                        )
                        .shadow(
                            color: Color(red: 1.0, green: 0.78, blue: 0.22)
                                .opacity(0.75 + (0.25 * intensity)),
                            radius: (12 * u) + (8 * u * intensity),
                            x: 0,
                            y: 0
                        )
                        .opacity(0.88 + (0.12 * intensity))
                        .frame(width: max(10, 14 * u), height: max(10, 14 * u))
                }
            }
        }
    }
}

private struct CoinStack: View {
    let u: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // A soft glow behind the coins
            RoundedRectangle(cornerRadius: max(14, 18 * u), style: .continuous)
                .fill(Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.10))
                .blur(radius: 18 * u)
                .blendMode(.screen)
                .frame(width: max(42, 70 * u), height: height * 0.78)
                .offset(x: 8 * u, y: -10 * u)

            VStack(spacing: -max(10, 14 * u)) {
                ForEach(0..<9, id: \.self) { i in
                    Coin(u: u)
                        .frame(width: max(48, 78 * u) - (CGFloat(i) * (2.2 * u)),
                               height: max(14, 20 * u))
                        .shadow(color: .black.opacity(0.40), radius: 4 * u, x: 0, y: 2 * u)
                        .offset(x: CGFloat(i % 2 == 0 ? -1 : 1) * (1.2 * u))
                }
            }
        }
        .frame(width: max(60, 88 * u), height: height)
    }
}

private struct Coin: View {
    let u: CGFloat

    var body: some View {
        ZStack {
            // Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.95, blue: 0.70),
                            Color(red: 1.00, green: 0.78, blue: 0.22),
                            Color(red: 0.62, green: 0.22, blue: 0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Rim
            Ellipse()
                .stroke(Color.white.opacity(0.28), lineWidth: max(1, 1.4 * u))
                .padding(max(0.6, 1.0 * u))

            // Inner rim
            Ellipse()
                .stroke(Color.black.opacity(0.18), lineWidth: max(0.8, 1.0 * u))
                .padding(max(3.0, 4.0 * u))

            // Specular highlight
            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: max(10, 14 * u), height: max(6, 8 * u))
                .offset(x: -max(10, 14 * u), y: -max(1, 2 * u))
                .blur(radius: 1.4 * u)

            // Warm glow edge
            Ellipse()
                .stroke(Color(red: 1.0, green: 0.82, blue: 0.28).opacity(0.40), lineWidth: max(1, 1.2 * u))
                .blur(radius: 3.2 * u)
                .blendMode(.screen)
        }
    }
}

private struct MetalGlints: View {
    let u: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Diagonal warm sweep
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(red: 1.0, green: 0.90, blue: 0.55).opacity(0.10),
                        Color(red: 1.0, green: 0.75, blue: 0.20).opacity(0.14),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(-12))
                .frame(width: w * 1.2, height: h * 0.30)
                .offset(y: -h * 0.12)
                .blur(radius: 10 * u)

                // Thin edge glint
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.12),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: w * 0.80, height: max(10, 18 * u))
                .offset(y: -h * 0.33)
                .blur(radius: 6 * u)

                // Small warm spark near the marquee area
                Circle()
                    .fill(Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.12))
                    .frame(width: max(80, 140 * u), height: max(80, 140 * u))
                    .blur(radius: 18 * u)
                    .offset(x: w * 0.22, y: -h * 0.22)
            }
        }
    }
}

private struct BulbRow: View {
    let count: Int
    let u: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: max(10, 12 * u)) {
                ForEach(0..<count, id: \.self) { i in
                    // A lively, non-uniform flicker.
                    let wave = 0.55 + 0.45 * sin((t * 2.1) + (Double(i) * 0.55))
                    let pulse = 0.60 + 0.40 * sin((t * 1.2) + (Double(i) * 0.90) + 1.7)
                    let intensity = max(0.0, min(1.0, (wave * 0.65) + (pulse * 0.35)))

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 1.0, green: 0.97, blue: 0.72),
                                    Color(red: 1.0, green: 0.74, blue: 0.20)
                                ],
                                center: .center,
                                startRadius: 1,
                                endRadius: 10
                            )
                        )
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.40))
                                .blur(radius: 6 * u)
                                .blendMode(.screen)
                        )
                        .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.22).opacity(0.65 + (0.35 * intensity)), radius: (10 * u) + (6 * u * intensity), x: 0, y: 0)
                        .opacity(0.75 + (0.25 * intensity))
                        .frame(width: max(8, 12 * u), height: max(8, 12 * u))
                }
            }
        }
    }
}

private struct SideGlowStrip: View {
    let u: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let shimmer = 0.55 + 0.45 * sin(t * 0.9)

            RoundedRectangle(cornerRadius: max(12, 14 * u), style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.85, blue: 0.28).opacity(0.10),
                            Color(red: 1.00, green: 0.60, blue: 0.14).opacity(0.18 + (0.06 * shimmer)),
                            Color(red: 1.00, green: 0.85, blue: 0.28).opacity(0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: max(12, 14 * u), style: .continuous)
                        .fill(Color.white.opacity(0.10 + (0.06 * shimmer)))
                        .blur(radius: 12 * u)
                        .blendMode(.screen)
                )
        }
    }
}

private struct StageLightRig: View {
    let shortEdge: CGFloat

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let drift = sin(t * 0.22)

            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.86, blue: 0.42).opacity(0.22),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(240, shortEdge * 0.50), height: max(520, shortEdge * 1.45))
                    .rotationEffect(.degrees(-16 + (drift * 4)))
                    .offset(x: -shortEdge * 0.34, y: -shortEdge * 0.20)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.58, blue: 0.20).opacity(0.16),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(220, shortEdge * 0.46), height: max(500, shortEdge * 1.40))
                    .rotationEffect(.degrees(15 - (drift * 5)))
                    .offset(x: shortEdge * 0.34, y: -shortEdge * 0.22)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(180, shortEdge * 0.36), height: max(420, shortEdge * 1.10))
                    .rotationEffect(.degrees(-2 + (drift * 3)))
                    .offset(y: -shortEdge * 0.28)
            }
            .blur(radius: max(6, shortEdge * 0.02))
        }
    }
}

private struct CabinetPatinaLayer: View {
    let u: CGFloat

    var body: some View {
        Canvas { context, size in
            for i in 0..<42 {
                let y = (CGFloat(i) / 41.0) * size.height
                let alpha = (i % 5 == 0) ? 0.055 : 0.025
                context.fill(
                    Path(CGRect(x: 0, y: y, width: size.width, height: max(0.8, 1.2 * u))),
                    with: .color(Color.white.opacity(alpha))
                )
            }

            for i in 0..<22 {
                let x = (CGFloat(i) / 21.0) * size.width
                context.fill(
                    Path(CGRect(x: x, y: 0, width: max(0.6, 0.8 * u), height: size.height)),
                    with: .color(Color.black.opacity(0.018))
                )
            }
        }
        .blur(radius: 0.5 * u)
        .blendMode(.overlay)
    }
}

// MARK: - Shapes

private struct StarShape: Shape {
    let points: Int
    /// 0.35...0.60 (smaller = pointier)
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let p = max(3, points)
        let rOuter = min(rect.width, rect.height) * 0.5
        let rInner = rOuter * max(0.25, min(0.70, innerRatio))
        let c = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        let step = .pi * 2.0 / CGFloat(p * 2)
        var angle = -CGFloat.pi / 2

        var firstPoint = true
        for i in 0..<(p * 2) {
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
            if firstPoint {
                path.move(to: pt)
                firstPoint = false
            } else {
                path.addLine(to: pt)
            }
            angle += step
        }

        path.closeSubpath()
        return path
    }
}

/// A banner that feels like a sign, not a rounded rectangle.
private struct ArcBannerShape: Shape {
    /// 0...0.35, higher = more arch.
    var curve: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = max(0.0, min(0.35, curve))
        let lift = rect.height * c

        var p = Path()

        // Start bottom-left
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Left side up
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + lift),
            control: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.minY + rect.height * 0.55)
        )

        // Top arch
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + lift),
            control: CGPoint(x: rect.midX, y: rect.minY - lift)
        )

        // Right side down
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.55)
        )

        p.closeSubpath()
        return p
    }
}

/// A cabinet “void” that reads like a cut-out, not a framed box.
private struct CabinetVoidShape: Shape {
    /// 0...0.35, higher = more arch.
    var curve: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = max(0.0, min(0.35, curve))
        let lift = rect.height * c

        var p = Path()

        // Bottom left
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.08))

        // Left wall
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + lift),
            control: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.midY)
        )

        // Top arch
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + lift),
            control: CGPoint(x: rect.midX, y: rect.minY - lift)
        )

        // Right wall
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.08),
            control: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.midY)
        )

        // Bottom curve
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.08),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.06)
        )

        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        CabinetBackground(title: "Takeaway", reelWidth: 220)
    }
}
