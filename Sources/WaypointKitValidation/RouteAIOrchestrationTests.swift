import WaypointKit

struct RouteAIOrchestrationTests {
    func testGreetingIsAnsweredWithoutRouteEditing() {
        let response = RouteAIInputRouter.response(
            for: "hey",
            currentPoints: [],
            priorConversationTurns: []
        )

        XCTAssertEqual(response?.intent, .smallTalk)
        XCTAssertTrue(response?.fallbackText.contains("trip ideas") == true)
        XCTAssertTrue(response?.fallbackText.contains("edit") == true)
    }
    func testChineseGreetingIsRoutedToAIConversation() {
        let response = RouteAIInputRouter.response(
            for: "哈喽",
            currentPoints: [],
            priorConversationTurns: []
        )

        XCTAssertEqual(response?.intent, .smallTalk)
    }
    func testInspirationWithoutRouteAsksForDeparture() {
        let response = RouteAIInputRouter.response(
            for: "今天适合去哪，帮我找灵感",
            currentPoints: [],
            priorConversationTurns: []
        )

        XCTAssertEqual(response?.intent, .inspiration)
        XCTAssertTrue(response?.fallbackText.contains("where to start") == true)
        XCTAssertTrue(response?.fallbackText.contains("current location") == true)
    }
    func testInspirationWithCurrentRouteKeepsRouteContext() {
        let response = RouteAIInputRouter.response(
            for: "帮我找点灵感",
            currentPoints: [
                Waypoint(name: "深圳湾公园", address: "深圳市南山区", latitude: 22.52, longitude: 113.94),
                Waypoint(name: "海上世界", address: "深圳市南山区", latitude: 22.48, longitude: 113.92)
            ],
            priorConversationTurns: []
        )

        XCTAssertEqual(response?.intent, .inspiration)
        XCTAssertTrue(response?.fallbackText.contains("current waypoints") == true)
    }
    func testCapabilityQuestionIsAnsweredDirectly() {
        let response = RouteAIInputRouter.response(
            for: "what can you do?",
            currentPoints: [],
            priorConversationTurns: []
        )

        XCTAssertEqual(response?.intent, .capabilityQuestion)
        XCTAssertTrue(response?.fallbackText.contains("generate") == true)
    }
    func testRouteEditRequestsPassThroughToRouteEditor() {
        let response = RouteAIInputRouter.response(
            for: "delete the second waypoint and add dinner at the end",
            currentPoints: [
                Waypoint(name: "A", address: "A", latitude: 22.0, longitude: 113.0),
                Waypoint(name: "B", address: "B", latitude: 22.1, longitude: 113.1),
                Waypoint(name: "C", address: "C", latitude: 22.2, longitude: 113.2)
            ],
            priorConversationTurns: []
        )

        XCTAssertNil(response)
    }
    func testShortAnswerAfterAssistantQuestionPassesThrough() {
        let response = RouteAIInputRouter.response(
            for: "南山",
            currentPoints: [],
            priorConversationTurns: [
                RouteListEditingConversationTurn(role: "assistant", text: "可以。你想从哪里出发？")
            ]
        )

        XCTAssertNil(response)
    }
    func testContradictorySmallTalkDecisionNeverCallsRouteEditor() async {
        let result = await RouteAIConversationOrchestrator.resolve(
            visibleUserPrompt: "哈咯",
            routeEditingPrompt: "哈咯",
            requestDraft: RouteGenerationIntentDraft(prompt: "哈咯"),
            currentPoints: [],
            priorConversationTurns: [],
            endpointContextProvider: { _, _ in
                XCTFail("Small talk should not request endpoint context.")
                return RouteGenerationResolvedEndpointContext(currentLocationPoint: nil)
            },
            intentRouter: { _, _, _ in
                RouteAIIntentDecision(
                    intent: .smallTalk,
                    confidence: 1.5,
                    needsCurrentLocation: false,
                    usesExistingRoute: false,
                    shouldCallRouteEditor: true,
                    normalizedPrompt: "哈咯",
                    assistantReply: "哈咯，我在。",
                    missingSlots: []
                )
            },
            conversationResponder: { _, decision, _, _ in
                XCTAssertEqual(decision.confidence, 1)
                XCTAssertFalse(decision.shouldCallRouteEditor)
                return decision.assistantReply
            }
        )

        XCTAssertEqual(result, .conversationHandled(assistantText: "哈咯，我在。"))
    }
    func testRouteCreateNearMeGetsCanonicalCurrentLocationPrompt() async {
        let result = await RouteAIConversationOrchestrator.resolve(
            visibleUserPrompt: "from here to the coast",
            routeEditingPrompt: "from here to the coast",
            requestDraft: RouteGenerationIntentDraft(prompt: "from here to the coast"),
            currentPoints: [],
            priorConversationTurns: [],
            endpointContextProvider: { _, _ in
                XCTFail("Route editing should defer current-location lookup to the app layer.")
                return RouteGenerationResolvedEndpointContext(currentLocationPoint: nil)
            },
            intentRouter: { _, _, _ in
                RouteAIIntentDecision(
                    intent: .routeCreate,
                    confidence: 0.88,
                    needsCurrentLocation: true,
                    usesExistingRoute: false,
                    shouldCallRouteEditor: false,
                    normalizedPrompt: "go to the coast",
                    assistantReply: "should not respond",
                    missingSlots: []
                )
            },
            conversationResponder: { _, _, _, _ in nil }
        )

        XCTAssertEqual(
            result,
            .routeEditing(prompt: "from current location, go to the coast", needsCurrentLocation: true)
        )
    }
    func testModelFailureFallsBackToLocalGreetingRouter() async {
        let result = await RouteAIConversationOrchestrator.resolve(
            visibleUserPrompt: "hey",
            routeEditingPrompt: "hey",
            requestDraft: RouteGenerationIntentDraft(prompt: "hey"),
            currentPoints: [],
            priorConversationTurns: [],
            endpointContextProvider: { _, _ in
                XCTFail("Fallback greeting should not request endpoint context.")
                return RouteGenerationResolvedEndpointContext(currentLocationPoint: nil)
            },
            intentRouter: { _, _, _ in nil },
            conversationResponder: { _, decision, _, _ in
                XCTAssertEqual(decision.intent, .smallTalk)
                return decision.assistantReply
            }
        )

        if case .conversationHandled(let assistantText) = result {
            XCTAssertTrue(assistantText.contains("trip ideas"))
        } else {
            XCTFail("Local greeting fallback should stay in conversation.")
        }
    }
    func testConversationLocationDecisionPassesCurrentPointToResponder() async {
        let currentPoint = Waypoint(
            name: "Current location",
            address: "Shenzhen",
            latitude: 22.5333,
            longitude: 113.9304,
            source: .gps
        )
        var didRequestCurrentLocation = false

        let result = await RouteAIConversationOrchestrator.resolve(
            visibleUserPrompt: "find ideas near me",
            routeEditingPrompt: "find ideas near me",
            requestDraft: RouteGenerationIntentDraft(prompt: "find ideas near me"),
            currentPoints: [],
            priorConversationTurns: [],
            endpointContextProvider: { _, needsCurrentLocation in
                didRequestCurrentLocation = needsCurrentLocation
                return RouteGenerationResolvedEndpointContext(currentLocationPoint: currentPoint)
            },
            intentRouter: { _, _, _ in
                RouteAIIntentDecision(
                    intent: .inspiration,
                    confidence: 0.91,
                    needsCurrentLocation: true,
                    usesExistingRoute: false,
                    shouldCallRouteEditor: false,
                    normalizedPrompt: "find ideas near current location",
                    assistantReply: "",
                    missingSlots: []
                )
            },
            conversationResponder: { _, decision, currentPoints, _ in
                XCTAssertEqual(decision.intent, .inspiration)
                XCTAssertEqual(currentPoints.first?.name, "Current location")
                return "I will use your current location."
            }
        )

        XCTAssertTrue(didRequestCurrentLocation)
        XCTAssertEqual(result, .conversationHandled(assistantText: "I will use your current location."))
    }
    func testClarifyFallbackMentionsMissingSlots() async {
        let result = await RouteAIConversationOrchestrator.resolve(
            visibleUserPrompt: "anything works",
            routeEditingPrompt: "anything works",
            requestDraft: RouteGenerationIntentDraft(prompt: "anything works"),
            currentPoints: [],
            priorConversationTurns: [],
            endpointContextProvider: { _, _ in
                RouteGenerationResolvedEndpointContext(currentLocationPoint: nil)
            },
            intentRouter: { _, _, _ in
                RouteAIIntentDecision(
                    intent: .clarify,
                    confidence: 0.52,
                    needsCurrentLocation: false,
                    usesExistingRoute: false,
                    shouldCallRouteEditor: false,
                    normalizedPrompt: "",
                    assistantReply: "",
                    missingSlots: ["origin", "target city"]
                )
            },
            conversationResponder: { _, _, _, _ in nil }
        )

        if case .conversationHandled(let assistantText) = result {
            XCTAssertTrue(assistantText.contains("origin"))
            XCTAssertTrue(assistantText.contains("target city"))
        } else {
            XCTFail("Clarification should stay in conversation.")
        }
    }
}
