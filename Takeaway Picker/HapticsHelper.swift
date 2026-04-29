//
//  HapticsHelper.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import UIKit

/// Centralised haptics helper so we keep feedback consistent across the app.
enum HapticsHelper {

    /// Light tap for simple UI interactions (taps, button presses).
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium impact when a spin starts or a more deliberate action is taken.
    static func spinStart() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Subtle "tick" used while the spinner steps through choices.
    static func tick() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Success-style notification when the spinner finishes on a choice.
    static func spinEndSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
