//
//  ContentView.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import SwiftUI

struct ContentView: View {
    private let defaultChoices = [
        "Indian",
        "Chinese",
        "Pizza",
        "Fish and Chips",
        "Burgers"
    ]

    var body: some View {
        MainPickerView(choices: defaultChoices)
    }
}

#Preview {
    ContentView()
}
