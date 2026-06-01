import Foundation
import WaypointKit

let currentRoute = [
    Waypoint(
        id: UUID(uuidString: "1A7B82F0-9EA5-4D50-A1B5-000000000001")!,
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
        id: UUID(uuidString: "1A7B82F0-9EA5-4D50-A1B5-000000000002")!,
        name: "Shanghai Museum",
        address: "201 Renmin Avenue, Shanghai",
        latitude: 31.2303,
        longitude: 121.4707,
        stayMinutes: 60,
        source: .user,
        poiCategory: "museum",
        cityName: "Shanghai",
        districtName: "Huangpu"
    ),
    Waypoint(
        id: UUID(uuidString: "1A7B82F0-9EA5-4D50-A1B5-000000000003")!,
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

let verifiedCandidates = [
    "candidate-xuhui-riverside": Waypoint(
        id: UUID(uuidString: "1A7B82F0-9EA5-4D50-A1B5-000000000101")!,
        name: "Xuhui Riverside",
        address: "Longteng Avenue, Shanghai",
        latitude: 31.1808,
        longitude: 121.4639,
        stayMinutes: 45,
        source: .user,
        poiCategory: "scenic",
        cityName: "Shanghai",
        districtName: "Xuhui"
    )
]

let userPrompt = "Replace the museum stop with a quieter riverside walk, but keep the start and final stop."
let verifiedReplacement = verifiedCandidates["candidate-xuhui-riverside"]!
let proposedRoute = [currentRoute[0], verifiedReplacement, currentRoute[2]]
let changes = RouteChangeDiffBuilder.changes(before: currentRoute, after: proposedRoute)
let proposal = RouteChangeProposal(
    baseRouteVersion: 12,
    source: .ai,
    userPrompt: userPrompt,
    beforePoints: currentRoute,
    proposedPoints: proposedRoute,
    proposedRouteName: "Shanghai riverside evening",
    summary: "Replace the museum visit with a quieter riverside stop while preserving the rest of the route.",
    changes: changes,
    warnings: RouteChangeDiffBuilder.warnings(for: proposedRoute)
)

let prompt = RouteListEditingPromptBuilder.userPromptForEdit(
    currentPoints: currentRoute,
    userPrompt: userPrompt,
    conversationTurns: [
        RouteListEditingConversationTurn(role: "user", text: "I want an easy Shanghai evening route.")
    ]
)

print("WaypointKit Demo")
print("===============")
print("User request: \(userPrompt)")
print("Verified candidate: \(verifiedReplacement.name) (\(verifiedReplacement.address))")
print("Prompt contains provider boundary: \(prompt.contains("Do not invent coordinates"))")
print("Proposal: \(RouteChangeProposalNarrative.cardTitle(for: proposal))")
for line in RouteChangeProposalNarrative.changeLines(for: proposal) {
    print("- \(line)")
}
print("Safety: \(RouteChangeProposalNarrative.safetyLine(for: proposal))")
print("Distance fallback: \(RouteMetrics.distanceText(legs: [], routePoints: proposedRoute))")
