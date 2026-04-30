//
//  TakeawaySearchView.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import SwiftUI
import CoreLocation
import Combine

// Simple location manager for requesting the user's current location
final class TakeawayLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var currentCoordinate: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentCoordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // For now we silently ignore errors.
    }
}

struct TakeawaySearchView: View {
    /// The chosen dinner type, e.g. "Pizza", "Chinese".
    let chosenType: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var locationManager = TakeawayLocationManager()
    @State private var restaurantName: String = ""
    @State private var locationText: String = ""
    @State private var takeawayOnly: Bool = false

    private var isSearchEnabled: Bool {
        let trimmedName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = locationText.trimmingCharacters(in: .whitespacesAndNewlines)

        let locationCountsAsText = !trimmedLocation.isEmpty && trimmedLocation.lowercased() != "current location"
        let hasText = !trimmedName.isEmpty || locationCountsAsText

        return hasText || locationManager.currentCoordinate != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DinnerSpinnerBackground()

                VStack(spacing: 20) {
                    // Context card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tonight's choice")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(red: 1.0, green: 0.74, blue: 0.24))

                        Text(chosenType)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(restaurantPanelBackground(cornerRadius: 28))
                    .padding(.horizontal)

                    // Input fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Restaurant name (optional)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.72))

                            TextField("e.g. Roma Pizza", text: $restaurantName)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .padding(14)
                                .foregroundColor(.white)
                                .background(inputBackground)
                        }

                        Toggle(isOn: $takeawayOnly) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Takeaway only")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Prefer restaurants that offer takeaway")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.58))
                            }
                        }
                        .tint(Color("AccentGreen"))
                        .padding(14)
                        .background(inputBackground)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.72))

                            HStack {
                                TextField("Town, postcode or area", text: $locationText)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)

                                Button {
                                    // Request the user's current location.
                                    locationManager.requestLocation()

                                    // Give a simple visual hint that "current location" is being used
                                    if locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        locationText = "Current location"
                                    }
                                } label: {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 1.0, green: 0.74, blue: 0.24))
                                        .padding(.leading, 4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(inputBackground)
                        }
                    }
                    .padding(16)
                    .background(restaurantPanelBackground(cornerRadius: 28))
                    .padding(.horizontal)

                    Spacer()

                    // Primary action button
                    Button {
                        performSearch()
                    } label: {
                        Label("Search in Maps", systemImage: "map.fill")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: isSearchEnabled
                                                ? [
                                                    Color("AccentGreen"),
                                                    Color(red: 1.0, green: 0.62, blue: 0.12)
                                                ]
                                                : [
                                                    Color.white.opacity(0.15),
                                                    Color.white.opacity(0.08)
                                                ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(isSearchEnabled ? 0.25 : 0.0), radius: 6, x: 0, y: 3)
                    }
                    .disabled(!isSearchEnabled)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Select local restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                            Text("Close")
                        }
                    }
                }
            }
        }
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.black.opacity(0.40))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
    }

    private func restaurantPanelBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.68),
                        Color(red: 0.15, green: 0.07, blue: 0.04).opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color(red: 1.0, green: 0.74, blue: 0.24).opacity(0.26)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.3
                    )
            )
            .shadow(color: .black.opacity(0.36), radius: 18, x: 0, y: 10)
    }

    // MARK: - Actions

    private func performSearch() {
        let trimmedName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = locationText.trimmingCharacters(in: .whitespacesAndNewlines)

        var components: [String] = []

        if !trimmedName.isEmpty {
            components.append(trimmedName)
        }

        // Always include the chosen type to bias results, e.g. "Pizza"
        components.append(chosenType)

        if takeawayOnly {
            components.append("takeaway")
        }

        if !trimmedLocation.isEmpty,
           trimmedLocation.lowercased() != "current location" {
            components.append(trimmedLocation)
        }

        let query = components.joined(separator: " ")

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }

        var urlString = "http://maps.apple.com/?q=\(encoded)"

        if let coordinate = locationManager.currentCoordinate {
            // Use sll (search location) so Maps searches near the coordinate,
            // rather than treating the coordinate as the selected place.
            urlString += "&sll=\(coordinate.latitude),\(coordinate.longitude)"
        }

        guard let url = URL(string: urlString) else {
            return
        }

        openURL(url)
        // User can then pick the correct place, open the website or call from Maps.
    }
}

#Preview {
    TakeawaySearchView(chosenType: "Pizza")
}
