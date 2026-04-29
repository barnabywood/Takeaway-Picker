//
//  SlotMachineChrome.swift
//  Takeaway Picker
//
//  Lightweight chrome wrapper used inside the cabinet background.
//  It renders the passed-in reel/handle content, plus the three
//  status dials and instruction text beneath.
//

import SwiftUI
import UIKit

struct SlotMachineChrome<Content: View>: View {
    let content: Content
    let dialProgress: Double
    let spacingScale: CGFloat
    let dialTuck: CGFloat
    let uiScale: CGFloat

    init(
        dialProgress: Double,
        spacingScale: CGFloat = 1.0,
        dialTuck: CGFloat = 1.0,
        uiScale: CGFloat = 1.0,
        @ViewBuilder content: () -> Content
    ) {
        self.dialProgress = dialProgress
        self.spacingScale = spacingScale
        self.dialTuck = dialTuck
        self.uiScale = uiScale
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let s: CGFloat = spacingScale
            let u: CGFloat = max(0.85, min(1.0, uiScale))
            let isPad = (UIDevice.current.userInterfaceIdiom == .pad)
            let shortEdge = min(proxy.size.width, proxy.size.height)
            let compactHeight = proxy.size.height < 640

            // Negative values pull the dials upward (towards the reel).
            // We keep this size-driven and allow a caller-provided tweak via `dialTuck`.
            let baseDialTopGap: CGFloat = {
                if isPad {
                    let minEdge: CGFloat = 834
                    let maxEdge: CGFloat = 1024
                    let tRaw = (shortEdge - minEdge) / max(1, (maxEdge - minEdge))
                    let t = min(1, max(0, tRaw))
                    return (-60) + (t * (-210 - (-60)))
                }

                // Cover the full iPhone range from compact widths (SE/mini) to Pro Max.
                let minEdge: CGFloat = 320
                let maxEdge: CGFloat = 430
                let tRaw = (shortEdge - minEdge) / max(1, (maxEdge - minEdge))
                let t = min(1, max(0, tRaw))
                return (-160) + (t * (-245 - (-160)))
            }()

            // Apply spacingScale gently while preserving a tight dial cluster.
            let sClamp = min(1.16, max(0.92, s * (compactHeight ? 1.05 : 1.14)))
            let dialTopGap: CGFloat = baseDialTopGap * sClamp * dialTuck
            let dialLowering: CGFloat = (compactHeight ? 8 : 12) * u

            VStack(spacing: 0) {
                contentArea(u: u)

                bottomPanel(u: u)
                    .padding(.top, dialTopGap + dialLowering)
                    .padding(.bottom, 0)
            }
            .padding(.horizontal, 24 * u)
            .padding(.vertical, 4 * s * u)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Sections

    private func contentArea(u: CGFloat) -> some View {
        content
            .padding(.horizontal, 8 * u)
    }

    private func bottomPanel(u: CGFloat) -> some View {
        let s: CGFloat = spacingScale

        return VStack(spacing: 3 * s * u) {
            VStack(spacing: 3 * s * u) {
                HStack(spacing: 16 * u) {
                    statusDial(label: "SPIN", angle: -60 + dialProgress * 1080, u: u)
                    statusDial(label: "VOTE", angle: -30 + dialProgress * 720, u: u)
                    statusDial(label: "EAT",  angle:  20 - dialProgress * 540, u: u)
                }

                Text("Pull the handle\nto pick tonight's takeaway")
                    .font(.system(size: max(9, 11 * u), weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.6), radius: 3 * u, x: 0, y: 1 * u)
                    .padding(.horizontal, 16 * u)
            }
        }
    }

    // MARK: - Dials

    private func statusDial(label: String, angle: Double, u: CGFloat) -> some View {
        VStack(spacing: 4 * u) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("MachineChromeLight"),
                                Color("MachineChromeMid"),
                                Color("MachineChromeDark")
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 22 * u
                        )
                    )
                    .shadow(color: .black.opacity(0.6), radius: 4 * u, x: 0, y: 2 * u)

                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                    .padding(3 * u)

                Capsule(style: .continuous)
                    .fill(Color("AccentGreen"))
                    .frame(width: max(1.5, 2 * u), height: 14 * u)
                    .offset(y: -8 * u)
                    .rotationEffect(.degrees(angle))

                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 6 * u, height: 6 * u)
            }
            .frame(width: 40 * u, height: 40 * u)

            Text(label)
                .font(.system(size: max(7, 8 * u), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SlotMachineChrome(dialProgress: 0.5, spacingScale: 1.0) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .frame(height: 140)
        }
        .padding()
    }
}
