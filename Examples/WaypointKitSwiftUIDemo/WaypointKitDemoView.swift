import SwiftUI
import WaypointKit

public struct WaypointKitDemoView: View {
    @StateObject private var model: WaypointKitDemoModel

    public init(model: WaypointKitDemoModel = WaypointKitDemoModel()) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        NavigationStack {
            List {
                Section("Current route") {
                    ForEach(model.currentPoints) { point in
                        WaypointRow(point: point)
                    }
                }

                Section("Verified provider candidates") {
                    if model.providerMatches.isEmpty {
                        Text("No candidates loaded")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.providerMatches) { point in
                            WaypointRow(point: point)
                        }
                    }
                }

                if let proposal = model.proposal {
                    Section("Review proposal") {
                        Label(RouteChangeProposalNarrative.cardTitle(for: proposal), systemImage: "sparkles")
                        ForEach(RouteChangeProposalNarrative.changeLines(for: proposal), id: \.self) { line in
                            Text(line)
                        }
                        Text(RouteChangeProposalNarrative.safetyLine(for: proposal))
                            .font(.footnote)
                            .foregroundColor(proposal.isRouteUsable ? .secondary : .red)
                    }
                }
            }
            .navigationTitle("WaypointKit")
            .toolbar {
                Button {
                    Task { await model.proposeRiversideReplacement() }
                } label: {
                    Label("Propose", systemImage: "arrow.triangle.branch")
                }
            }
            .task {
                await model.proposeRiversideReplacement()
            }
        }
    }
}

public final class WaypointKitDemoModel: ObservableObject {
    @Published public private(set) var currentPoints: [Waypoint]
    @Published public private(set) var providerMatches: [Waypoint] = []
    @Published public private(set) var proposal: RouteChangeProposal?

    private let poiProvider: any POIProvider

    public init(
        currentPoints: [Waypoint] = WaypointKitDemoModel.defaultRoute,
        poiProvider: any POIProvider = MockPOIProvider(points: WaypointKitDemoModel.mockPOIs)
    ) {
        self.currentPoints = currentPoints
        self.poiProvider = poiProvider
    }

    @MainActor
    public func proposeRiversideReplacement() async {
        do {
            let candidates = try await poiProvider.searchPOIs(
                POISearchRequest(
                    query: "Riverside",
                    city: "Shanghai",
                    placeKind: "scenic",
                    centerCoordinateSystem: .wgs84,
                    limit: 3
                )
            )
            providerMatches = candidates
            guard let replacement = candidates.first else {
                proposal = nil
                return
            }

            let proposed = currentPoints.map { point in
                point.name == "Shanghai Museum" ? replacement : point
            }
            proposal = RouteChangeProposal(
                baseRouteVersion: 1,
                source: .ai,
                userPrompt: "Replace the museum stop with a quieter riverside walk.",
                beforePoints: currentPoints,
                proposedPoints: proposed,
                proposedRouteName: "Shanghai riverside evening",
                summary: "Replace the museum visit with a verified riverside stop.",
                changes: RouteChangeDiffBuilder.changes(before: currentPoints, after: proposed),
                warnings: RouteChangeDiffBuilder.warnings(for: proposed)
            )
        } catch {
            providerMatches = []
            proposal = nil
        }
    }

    public static let defaultRoute = [
        Waypoint(
            name: "People's Square",
            address: "Huangpu, Shanghai",
            latitude: 31.2304,
            longitude: 121.4737,
            stayMinutes: 20,
            source: .user,
            poiCategory: "landmark",
            cityName: "Shanghai",
            districtName: "Huangpu"
        ),
        Waypoint(
            name: "Shanghai Museum",
            address: "201 Renmin Avenue, Shanghai",
            latitude: 31.2303,
            longitude: 121.4707,
            stayMinutes: 60,
            source: .user,
            poiCategory: "museum indoor",
            cityName: "Shanghai",
            districtName: "Huangpu"
        ),
        Waypoint(
            name: "The Bund",
            address: "Zhongshan East 1st Road, Shanghai",
            latitude: 31.2397,
            longitude: 121.4998,
            stayMinutes: 30,
            source: .user,
            poiCategory: "scenic",
            cityName: "Shanghai",
            districtName: "Huangpu"
        )
    ]

    public static let mockPOIs = [
        Waypoint(
            name: "Xuhui Riverside",
            address: "Longteng Avenue, Shanghai",
            latitude: 31.1808,
            longitude: 121.4639,
            stayMinutes: 45,
            source: .user,
            poiCategory: "scenic riverside",
            cityName: "Shanghai",
            districtName: "Xuhui"
        )
    ]
}

private struct WaypointRow: View {
    var point: Waypoint

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.name)
                .font(.headline)
            Text(point.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(point.latitude, specifier: "%.4f"), \(point.longitude, specifier: "%.4f")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}
