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
    /// The chosen takeaway type, e.g. "Pizza", "Chinese".
    let chosenType: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var locationManager = TakeawayLocationManager()
    @State private var restaurantName: String = ""
    @State private var locationText: String = ""

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
                // Background aligned to core app colours
                LinearGradient(
                    colors: [
                        Color("Background"),
                        Color("BrandPrimary").opacity(0.14),
                        Color.black.opacity(0.70)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Context card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tonight's choice")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)

                        Text(chosenType)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color("BrandPrimary"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color("SurfaceAlt").opacity(0.94))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)

                    // Input fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Restaurant name (optional)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            TextField("e.g. Roma Pizza", text: $restaurantName)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .padding(12)
                                .foregroundColor(Color("TextPrimary"))
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color("SurfaceAlt").opacity(0.94))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Location")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)

                            HStack {
                                TextField("Town, postcode or area", text: $locationText)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .foregroundColor(Color("TextPrimary"))

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
                                        .foregroundColor(Color("BrandPrimary"))
                                        .padding(.leading, 4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color("SurfaceAlt").opacity(0.94))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Primary action button
                    Button {
                        performSearch()
                    } label: {
                        Text("Search in Maps")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isSearchEnabled ? Color("AccentGreen") : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(18)
                            .shadow(color: .black.opacity(isSearchEnabled ? 0.25 : 0.0), radius: 6, x: 0, y: 3)
                    }
                    .disabled(!isSearchEnabled)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Select local takeaway")
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
