import Foundation
import WaypointKit

struct MultiTurnRouteEditFixtureTests {
    func testMultiTurnFixtureFileDecodes() {
        let fixtures = loadFixtures()

        XCTAssertEqual(fixtures.schemaVersion, 1)
        XCTAssertEqual(fixtures.cases.count, 3)
    }

    func testMultiTurnFixturesMatchRouterExpectations() {
        for fixture in loadFixtures().cases {
            let points = fixture.currentPoints.map(\.waypoint)
            let turns = fixture.conversationTurns.map(\.turn)
            let response = RouteAIInputRouter.response(
                for: fixture.userPrompt,
                currentPoints: points,
                priorConversationTurns: turns
            )

            if fixture.expectedRouteEditorPassthrough {
                XCTAssertNil(response, "Expected route editor passthrough for \(fixture.id)")
            } else {
                XCTAssertEqual(response?.intent.routeAIIntent.rawValue, fixture.expectedRouterIntent)
            }
        }
    }

    func testMultiTurnFixturesPreservePromptContext() {
        for fixture in loadFixtures().cases {
            let prompt = RouteListEditingPromptBuilder.userPromptForEdit(
                currentPoints: fixture.currentPoints.map(\.waypoint),
                userPrompt: fixture.userPrompt,
                conversationTurns: fixture.conversationTurns.map(\.turn)
            )

            for expectedText in fixture.expectedPromptContains {
                XCTAssertTrue(prompt.contains(expectedText), "Missing '\(expectedText)' in \(fixture.id)")
            }
        }
    }

    private func loadFixtures() -> MultiTurnRouteEditFixtureFile {
        do {
            let data = try Data(contentsOf: fixtureURL())
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(MultiTurnRouteEditFixtureFile.self, from: data)
        } catch {
            fatalError("Failed to load multi-turn route-edit fixtures: \(error)")
        }
    }

    private func fixtureURL() -> URL {
        let fileManager = FileManager.default
        let relativePath = "Fixtures/multi-turn-route-edits.json"
        var current = URL(fileURLWithPath: #filePath)

        while current.path != "/" {
            let candidate = current
                .deletingLastPathComponent()
                .appendingPathComponent(relativePath)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            current.deleteLastPathComponent()
        }

        fatalError("Missing \(relativePath)")
    }
}

private struct MultiTurnRouteEditFixtureFile: Decodable {
    var schemaVersion: Int
    var cases: [MultiTurnRouteEditFixture]
}

private struct MultiTurnRouteEditFixture: Decodable {
    var id: String
    var title: String
    var userPrompt: String
    var currentPoints: [MultiTurnFixtureWaypoint]
    var conversationTurns: [MultiTurnFixtureConversationTurn]
    var expectedRouteEditorPassthrough: Bool
    var expectedRouterIntent: String?
    var expectedPromptContains: [String]
}

private struct MultiTurnFixtureWaypoint: Decodable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var isSelected: Bool
    var stayMinutes: Int

    var waypoint: Waypoint {
        Waypoint(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            isSelected: isSelected,
            stayMinutes: stayMinutes,
            source: .user
        )
    }
}

private struct MultiTurnFixtureConversationTurn: Decodable {
    var role: String
    var text: String

    var turn: RouteListEditingConversationTurn {
        RouteListEditingConversationTurn(role: role, text: text)
    }
}
