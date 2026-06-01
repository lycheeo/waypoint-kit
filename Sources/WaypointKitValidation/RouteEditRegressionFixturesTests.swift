import Foundation
import WaypointKit

struct RouteEditRegressionFixturesTests {
    func testRegressionFixtureFileDecodes() {
        let fixtures = loadFixtures()

        XCTAssertEqual(fixtures.schemaVersion, 1)
        XCTAssertEqual(fixtures.cases.count, 4)
    }

    func testRegressionFixturesProduceExpectedDiffKinds() {
        for fixture in loadFixtures().cases {
            let proposal = proposal(for: fixture)

            XCTAssertEqual(
                proposal.changes.map { $0.kind.rawValue },
                fixture.expectedChangeKinds,
                "Unexpected change kinds for \(fixture.id)"
            )
            XCTAssertEqual(proposal.pointCountDeltaText, fixture.expectedPointCountDelta)
        }
    }

    func testRegressionFixturesProduceExpectedNarratives() {
        for fixture in loadFixtures().cases {
            let proposal = proposal(for: fixture)

            XCTAssertEqual(
                RouteChangeProposalNarrative.cardTitle(for: proposal),
                fixture.expectedCardTitle,
                "Unexpected card title for \(fixture.id)"
            )
            XCTAssertEqual(
                RouteChangeProposalNarrative.safetyLine(for: proposal),
                fixture.expectedSafetyLine,
                "Unexpected safety line for \(fixture.id)"
            )
        }
    }

    func testRegressionFixturesSurfaceBlockingWarnings() {
        for fixture in loadFixtures().cases {
            let proposal = proposal(for: fixture)

            XCTAssertEqual(proposal.isRouteUsable, fixture.expectedUsable)
            if fixture.expectedUsable {
                XCTAssertEqual(proposal.warnings.count, 0)
            } else {
                XCTAssertEqual(proposal.warnings.map(\.severity), [.blocking])
            }
        }
    }

    private func proposal(for fixture: RouteEditRegressionFixture) -> RouteChangeProposal {
        let before = fixture.before.map(\.waypoint)
        let after = fixture.after.map(\.waypoint)
        return RouteChangeProposal(
            baseRouteVersion: 1,
            source: .ai,
            userPrompt: fixture.userPrompt,
            beforePoints: before,
            proposedPoints: after,
            proposedRouteName: fixture.routeName,
            summary: fixture.summary,
            changes: RouteChangeDiffBuilder.changes(before: before, after: after),
            warnings: RouteChangeDiffBuilder.warnings(for: after)
        )
    }

    private func loadFixtures() -> RouteEditRegressionFixtureFile {
        do {
            let data = try Data(contentsOf: fixtureURL())
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(RouteEditRegressionFixtureFile.self, from: data)
        } catch {
            fatalError("Failed to load route-edit regression fixtures: \(error)")
        }
    }

    private func fixtureURL() -> URL {
        let fileManager = FileManager.default
        let relativePath = "Fixtures/route-edit-regressions.json"
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

private struct RouteEditRegressionFixtureFile: Decodable {
    var schemaVersion: Int
    var cases: [RouteEditRegressionFixture]
}

private struct RouteEditRegressionFixture: Decodable {
    var id: String
    var title: String
    var userPrompt: String
    var routeName: String
    var summary: String
    var before: [RouteEditRegressionWaypoint]
    var after: [RouteEditRegressionWaypoint]
    var expectedChangeKinds: [String]
    var expectedCardTitle: String
    var expectedSafetyLine: String
    var expectedUsable: Bool
    var expectedPointCountDelta: String
}

private struct RouteEditRegressionWaypoint: Decodable {
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
