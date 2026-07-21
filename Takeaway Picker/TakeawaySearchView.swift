//
//  RestaurantSearchView.swift
//  Eat Something
//
//  Created by Barnaby Wood on 14/01/2026.
//

import SwiftUI
import CoreLocation
import Combine
import UIKit

// Simple location manager for requesting the user's current location
final class RestaurantLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
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

private struct LocationCandidate: Identifiable {
    let id = UUID()
    let fieldValue: String
    let detail: String
    let coordinate: CLLocationCoordinate2D
}

struct RestaurantSearchView: View {
    /// The chosen dinner type, e.g. "Pizza", "Chinese".
    let chosenType: String
    let isRestaurantMode: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var locationManager = RestaurantLocationManager()
    @State private var restaurantName: String = ""
    @State private var locationText: String = ""
    @State private var takeawayOnly: Bool = false
    @State private var isResolvingLocation: Bool = false
    @State private var locationSearchError: String?
    @State private var locationCandidates: [LocationCandidate] = []
    @State private var selectedLocationCandidate: LocationCandidate?
    @State private var pendingSearchQuery: String?
    @State private var missingMapsProvider: MapsProvider?
    @AppStorage("EatSomethingMapsProvider") private var preferredMapsProvider: String = MapsProvider.apple.rawValue

    init(chosenType: String, isRestaurantMode: Bool = false) {
        self.chosenType = chosenType
        self.isRestaurantMode = isRestaurantMode
        _restaurantName = State(initialValue: isRestaurantMode ? chosenType : "")
    }

    private var isSearchEnabled: Bool {
        let trimmedName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = locationText.trimmingCharacters(in: .whitespacesAndNewlines)

        let locationCountsAsText = !trimmedLocation.isEmpty && trimmedLocation.lowercased() != "current location"
        let hasText = !trimmedName.isEmpty || locationCountsAsText

        return hasText || locationManager.currentCoordinate != nil
    }

    private var selectedMapsProvider: MapsProvider {
        MapsProvider(rawValue: preferredMapsProvider) ?? .apple
    }

    private var searchButtonTitle: String {
        isResolvingLocation ? "Finding location..." : "Search in \(selectedMapsProvider.title)"
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
                            Text(isRestaurantMode ? "Restaurant name" : "Restaurant name (optional)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.72))

                            TextField(
                                text: $restaurantName,
                                prompt: Text("e.g. Roma Pizza")
                                    .foregroundColor(.white.opacity(0.52))
                            ) {
                                Text("e.g. Roma Pizza")
                            }
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

                            VStack(spacing: 10) {
                                HStack {
                                    TextField(
                                        text: $locationText,
                                        prompt: Text("Town, postcode or area")
                                            .foregroundColor(.white.opacity(0.52))
                                    ) {
                                        Text("Town, postcode or area")
                                    }
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                        .onChange(of: locationText) { _, newValue in
                                            if selectedLocationCandidate?.fieldValue != newValue.trimmingCharacters(in: .whitespacesAndNewlines) {
                                                selectedLocationCandidate = nil
                                            }
                                        }
                                }
                                .padding(14)
                                .background(inputBackground)

                                Button {
                                    useCurrentLocation()
                                } label: {
                                    Label("Use Current Location", systemImage: "location.fill")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .foregroundColor(.white)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(Color.white.opacity(0.10))
                                        )
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .stroke(Color(red: 1.0, green: 0.74, blue: 0.24).opacity(0.28), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
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
                        Label(searchButtonTitle, systemImage: "map.fill")
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
                    .disabled(!isSearchEnabled || isResolvingLocation)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                if !locationCandidates.isEmpty {
                    LocationChoiceOverlay(
                        candidates: locationCandidates,
                        onSelect: selectLocationCandidate,
                        onDismiss: { locationCandidates = [] }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .navigationTitle("Select local restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(.white)
            .alert("Location not found", isPresented: Binding(
                get: { locationSearchError != nil },
                set: { if !$0 { locationSearchError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(locationSearchError ?? "")
            }
            .alert("Install \(missingMapsProvider?.title ?? "Maps")?", isPresented: Binding(
                get: { missingMapsProvider != nil },
                set: { if !$0 { missingMapsProvider = nil } }
            )) {
                Button("Not now", role: .cancel) { }
                Button("Install") {
                    openSelectedMapsInstallPage()
                }
            } message: {
                Text("Your selected maps app is not installed. Install it or choose a different maps app in Help & Settings.")
            }
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

        if isRestaurantMode {
            // Restaurant mode is a direct lookup of the selected favourite.
            components.append(trimmedName.isEmpty ? chosenType : trimmedName)
        } else {
            if !trimmedName.isEmpty {
                components.append(trimmedName)
            }

            // Dinner mode uses the chosen cuisine to bias nearby results.
            components.append(chosenType)
        }

        if takeawayOnly {
            components.append("takeaway")
        }

        let query = components.joined(separator: " ")

        if !trimmedLocation.isEmpty,
           trimmedLocation.lowercased() != "current location" {
            if let selectedLocationCandidate,
               selectedLocationCandidate.fieldValue == trimmedLocation {
                openMapsSearch(query: query, coordinate: selectedLocationCandidate.coordinate)
                return
            }

            isResolvingLocation = true
            pendingSearchQuery = query
            CLGeocoder().geocodeAddressString(trimmedLocation) { placemarks, _ in
                let candidates = makeLocationCandidates(from: placemarks ?? [])

                DispatchQueue.main.async {
                    isResolvingLocation = false

                    guard !candidates.isEmpty else {
                        pendingSearchQuery = nil
                        locationSearchError = "Try a more specific town, city, postcode or area."
                        return
                    }

                    if candidates.count == 1, let candidate = candidates.first {
                        selectedLocationCandidate = candidate
                        locationText = candidate.fieldValue
                        pendingSearchQuery = nil
                        openMapsSearch(query: query, coordinate: candidate.coordinate)
                        return
                    }

                    locationCandidates = candidates
                }
            }
            return
        }

        openMapsSearch(
            query: query,
            coordinate: locationManager.currentCoordinate,
            nearbySearch: true
        )
    }

    private func useCurrentLocation() {
        locationManager.requestLocation()
        selectedLocationCandidate = nil
        locationText = "Current location"
    }

    private func openMapsSearch(
        query: String,
        coordinate: CLLocationCoordinate2D?,
        nearbySearch: Bool = false
    ) {
        let provider = selectedMapsProvider

        guard isMapsProviderInstalled(provider) else {
            missingMapsProvider = provider
            return
        }

        guard let url = mapsURL(
            for: provider,
            query: query,
            coordinate: coordinate,
            nearbySearch: nearbySearch
        ) else {
            return
        }

        openURL(url)
        // User can then pick the correct place, open the website or call from Maps.
    }

    private func mapsURL(
        for provider: MapsProvider,
        query: String,
        coordinate: CLLocationCoordinate2D?,
        nearbySearch: Bool
    ) -> URL? {
        switch provider {
        case .apple:
            return appleMapsURL(
                query: query,
                coordinate: coordinate,
                scheme: "maps",
                nearbySearch: nearbySearch
            )
        case .google:
            return googleMapsURL(query: query, coordinate: coordinate, nearbySearch: nearbySearch)
        }
    }

    private func isMapsProviderInstalled(_ provider: MapsProvider) -> Bool {
        switch provider {
        case .apple:
            guard let url = URL(string: "maps://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        case .google:
            guard let url = URL(string: "comgooglemaps://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    private func appleMapsURL(
        query: String,
        coordinate: CLLocationCoordinate2D?,
        scheme: String,
        nearbySearch: Bool
    ) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        var urlString = "\(scheme)://?q=\(encoded)"

        if let coordinate {
            // Use sll (search location) so Maps searches near the coordinate,
            // rather than treating the coordinate as the selected place.
            urlString += "&sll=\(coordinate.latitude),\(coordinate.longitude)"
            // Current Location should stay local rather than opening a city-sized search area.
            urlString += nearbySearch ? "&sspn=0.04,0.04" : "&sspn=0.25,0.25"
        }

        return URL(string: urlString)
    }

    private func googleMapsURL(
        query: String,
        coordinate: CLLocationCoordinate2D?,
        nearbySearch: Bool
    ) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        var urlString = "comgooglemaps://?q=\(encoded)"

        if let coordinate {
            // Google Maps uses center as the search viewport. Putting coordinates
            // into the query text can cause it to bias back to the user's location.
            urlString += "&center=\(coordinate.latitude),\(coordinate.longitude)"
            urlString += "&zoom=\(nearbySearch ? 16 : 14)"
        }

        return URL(string: urlString)
    }

    private func openSelectedMapsInstallPage() {
        guard let provider = missingMapsProvider,
              let url = mapsInstallURL(for: provider) else {
            return
        }

        missingMapsProvider = nil
        openURL(url)
    }

    private func mapsInstallURL(for provider: MapsProvider) -> URL? {
        switch provider {
        case .apple:
            return URL(string: "https://apps.apple.com/app/apple-maps/id915056765")
        case .google:
            return URL(string: "https://apps.apple.com/app/google-maps/id585027354")
        }
    }

    private func selectLocationCandidate(_ candidate: LocationCandidate) {
        selectedLocationCandidate = candidate
        locationText = candidate.fieldValue
        locationCandidates = []

        if let pendingSearchQuery {
            self.pendingSearchQuery = nil
            openMapsSearch(query: pendingSearchQuery, coordinate: candidate.coordinate)
        }
    }

    private func makeLocationCandidates(from placemarks: [CLPlacemark]) -> [LocationCandidate] {
        var seenValues: Set<String> = []

        return placemarks.compactMap { placemark in
            guard let coordinate = placemark.location?.coordinate else {
                return nil
            }

            let primary = [
                placemark.locality,
                placemark.name
            ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }

            guard let primary else {
                return nil
            }

            let detailParts = [
                placemark.administrativeArea,
                placemark.country
            ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != primary }

            let detail = detailParts.joined(separator: ", ")
            let fieldValue = ([primary] + detailParts).joined(separator: ", ")

            guard seenValues.insert(fieldValue).inserted else {
                return nil
            }

            return LocationCandidate(
                fieldValue: fieldValue,
                detail: detail.isEmpty ? "Use this location" : detail,
                coordinate: coordinate
            )
        }
        .prefix(6)
        .map { $0 }
    }
}

private struct LocationChoiceOverlay: View {
    let candidates: [LocationCandidate]
    let onSelect: (LocationCandidate) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Which location?")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("Pick the closest match, or type more detail if it is not listed.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.66))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white.opacity(0.82))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 10) {
                    ForEach(candidates) { candidate in
                        Button {
                            onSelect(candidate)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color(red: 1.0, green: 0.74, blue: 0.24))
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(candidate.fieldValue)
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.78)

                                    Text(candidate.detail)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.58))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.white.opacity(0.42))
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.black.opacity(0.34))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.09, blue: 0.05).opacity(0.98),
                                Color.black.opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.20),
                                        Color(red: 1.0, green: 0.74, blue: 0.24).opacity(0.32)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    )
                    .shadow(color: .black.opacity(0.42), radius: 28, x: 0, y: 18)
            )
            .padding(.horizontal, 22)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: candidates.count)
    }
}

#Preview {
    RestaurantSearchView(chosenType: "Pizza")
}
