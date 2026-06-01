import Foundation

public enum RouteAIIntent: String, Codable, Equatable {
    case smallTalk = "small_talk"
    case inspiration
    case capabilityQuestion = "capability_question"
    case routeCreate = "route_create"
    case routeEdit = "route_edit"
    case clarify
    case unsupported
}

public struct RouteAIIntentDecision: Codable, Equatable {
    public var intent: RouteAIIntent
    public var confidence: Double
    public var needsCurrentLocation: Bool
    public var usesExistingRoute: Bool
    public var shouldCallRouteEditor: Bool
    public var normalizedPrompt: String
    public var assistantReply: String
    public var missingSlots: [String]

    enum CodingKeys: String, CodingKey {
        case intent
        case confidence
        case needsCurrentLocation = "needs_current_location"
        case usesExistingRoute = "uses_existing_route"
        case shouldCallRouteEditor = "should_call_route_editor"
        case normalizedPrompt = "normalized_prompt"
        case assistantReply = "assistant_reply"
        case missingSlots = "missing_slots"
    }

    public init(
        intent: RouteAIIntent,
        confidence: Double,
        needsCurrentLocation: Bool,
        usesExistingRoute: Bool,
        shouldCallRouteEditor: Bool,
        normalizedPrompt: String,
        assistantReply: String,
        missingSlots: [String]
    ) {
        self.intent = intent
        self.confidence = confidence
        self.needsCurrentLocation = needsCurrentLocation
        self.usesExistingRoute = usesExistingRoute
        self.shouldCallRouteEditor = shouldCallRouteEditor
        self.normalizedPrompt = normalizedPrompt
        self.assistantReply = assistantReply
        self.missingSlots = missingSlots
    }

    public var trimmedAssistantReply: String? {
        let trimmed = assistantReply.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public var routeEditorPrompt: String {
        let trimmed = normalizedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : trimmed
    }

    public var handlesConversationLocally: Bool {
        switch intent {
        case .smallTalk, .inspiration, .capabilityQuestion, .clarify, .unsupported:
            return !shouldCallRouteEditor
        case .routeCreate, .routeEdit:
            return false
        }
    }

    public var sanitizedForExecution: RouteAIIntentDecision {
        var copy = self
        copy.confidence = min(max(copy.confidence, 0), 1)

        switch copy.intent {
        case .routeCreate, .routeEdit:
            copy.shouldCallRouteEditor = true
            copy.assistantReply = ""
        case .smallTalk, .inspiration, .capabilityQuestion, .clarify, .unsupported:
            copy.shouldCallRouteEditor = false
        }

        copy.normalizedPrompt = copy.normalizedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.assistantReply = copy.assistantReply.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.missingSlots = copy.missingSlots
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if copy.needsCurrentLocation,
           copy.shouldCallRouteEditor,
           !copy.normalizedPrompt.containsCanonicalCurrentLocation {
            copy.normalizedPrompt = copy.normalizedPrompt.isEmpty ?
                "from current location" :
                "from current location, \(copy.normalizedPrompt)"
        }

        return copy
    }
}

public enum RouteAIInputIntent: Equatable {
    case smallTalk
    case inspiration
    case capabilityQuestion

    public init?(routeAIIntent: RouteAIIntent) {
        switch routeAIIntent {
        case .smallTalk:
            self = .smallTalk
        case .inspiration:
            self = .inspiration
        case .capabilityQuestion:
            self = .capabilityQuestion
        case .routeCreate, .routeEdit, .clarify, .unsupported:
            return nil
        }
    }

    public var routeAIIntent: RouteAIIntent {
        switch self {
        case .smallTalk: .smallTalk
        case .inspiration: .inspiration
        case .capabilityQuestion: .capabilityQuestion
        }
    }
}

public struct RouteAIInputRoutingResponse: Equatable {
    public var intent: RouteAIInputIntent
    public var fallbackText: String

    public init(intent: RouteAIInputIntent, fallbackText: String) {
        self.intent = intent
        self.fallbackText = fallbackText
    }
}

public enum RouteAIInputRouter {
    public static func response(
        for userPrompt: String,
        currentPoints: [Waypoint],
        priorConversationTurns: [RouteListEditingConversationTurn]
    ) -> RouteAIInputRoutingResponse? {
        let trimmed = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let compactText = compact(trimmed)
        let openQuestionContext = hasOpenAssistantQuestion(in: priorConversationTurns)

        if isCapabilityQuestion(compactText) {
            return RouteAIInputRoutingResponse(
                intent: .capabilityQuestion,
                fallbackText: "I can help find trip ideas, generate a route, or edit the current waypoint list."
            )
        }

        if !openQuestionContext, isSmallTalkGreeting(compactText) {
            return RouteAIInputRoutingResponse(
                intent: .smallTalk,
                fallbackText: "I am here. I can help find trip ideas, generate routes, or edit the current waypoints."
            )
        }

        if isInspirationRequest(trimmed, compactText: compactText) {
            if currentPoints.isEmpty {
                return RouteAIInputRoutingResponse(
                    intent: .inspiration,
                    fallbackText: "Tell me where to start, or say you want to use your current location."
                )
            }

            return RouteAIInputRoutingResponse(
                intent: .inspiration,
                fallbackText: "I can use the current waypoints and suggest something lighter, quieter, indoor-friendly, or food-focused."
            )
        }

        if !openQuestionContext, isLightCasualChat(trimmed, compactText: compactText) {
            return RouteAIInputRoutingResponse(
                intent: .smallTalk,
                fallbackText: "I am here. Give me a direction and I will turn it into actionable waypoints."
            )
        }

        return nil
    }

    private static func isSmallTalkGreeting(_ text: String) -> Bool {
        let exactGreetings = [
            "hey", "hi", "hello", "哈喽", "哈啰", "哈罗", "嗨", "你好", "您好", "在吗", "在不在",
            "早", "早上好", "晚上好", "下午好"
        ]
        return exactGreetings.contains(text)
    }

    private static func isCapabilityQuestion(_ text: String) -> Bool {
        containsAny(text, [
            "whatcanyoudo", "help", "features", "你能做什么", "能做什么", "你可以做什么", "可以做什么", "怎么用", "怎么玩",
            "你是谁", "功能", "帮助"
        ])
    }

    private static func isInspirationRequest(_ rawText: String, compactText: String) -> Bool {
        containsAny(compactText, [
            "ideas", "inspiration", "wheretogo", "灵感", "适合去哪", "适合去哪儿", "去哪玩", "去哪儿玩", "今天去哪", "周末去哪",
            "不知道去哪", "推荐去哪", "去哪比较好", "附近去哪", "散散心", "出去走走"
        ]) || containsAny(rawText, ["找灵感", "给点灵感", "帮我想想去哪"])
    }

    private static func isLightCasualChat(_ rawText: String, compactText: String) -> Bool {
        guard compactText.count <= 18 else { return false }
        guard !containsRouteAction(compactText) else { return false }
        return containsAny(compactText, [
            "thanks", "ok", "haha", "哈哈", "嘿嘿", "谢谢", "谢了", "好的", "行", "可以", "没事",
            "你还在吗", "聊聊", "随便聊聊"
        ]) || (rawText.contains("吗") && !rawText.contains("去哪"))
    }

    private static func containsRouteAction(_ text: String) -> Bool {
        containsAny(text, [
            "route", "waypoint", "origin", "destination", "路线", "行程", "规划", "出发", "起点", "终点", "目的地", "最后", "新增",
            "增加", "加一个", "删除", "删掉", "去掉", "移除", "替换", "换成", "改成",
            "午餐", "晚餐", "吃饭", "本地菜", "餐厅", "附近", "当前位置"
        ])
    }

    private static func hasOpenAssistantQuestion(in turns: [RouteListEditingConversationTurn]) -> Bool {
        guard let lastAssistant = turns.last(where: { $0.role == "assistant" }) else { return false }
        let text = lastAssistant.text
        return text.contains("？") || text.contains("?") ||
            text.contains("tell me") ||
            text.contains("告诉我") ||
            text.contains("想从哪里") ||
            text.contains("你想") ||
            text.contains("请选择")
    }

    private static func compact(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols))
            .joined()
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}

public struct RouteGenerationIntentDraft: Equatable {
    public var prompt: String

    public init(prompt: String = "") {
        self.prompt = prompt
    }
}

public struct RouteGenerationResolvedEndpointContext {
    public var currentLocationPoint: Waypoint?

    public init(currentLocationPoint: Waypoint?) {
        self.currentLocationPoint = currentLocationPoint
    }
}

public typealias RouteAIIntentRouterHandler = (
    String,
    [Waypoint],
    [RouteListEditingConversationTurn]
) async -> RouteAIIntentDecision?

public typealias RouteAIConversationResponder = (
    String,
    RouteAIIntentDecision,
    [Waypoint],
    [RouteListEditingConversationTurn]
) async -> String?

public typealias RouteAIEndpointContextProvider = (
    RouteGenerationIntentDraft,
    Bool
) async -> RouteGenerationResolvedEndpointContext

public enum RouteAIConversationOrchestrationResult: Equatable {
    case conversationHandled(assistantText: String)
    case routeEditing(prompt: String, needsCurrentLocation: Bool)
}

public enum RouteAIConversationOrchestrator {
    public static func resolve(
        visibleUserPrompt: String,
        routeEditingPrompt fallbackRouteEditingPrompt: String,
        requestDraft: RouteGenerationIntentDraft,
        currentPoints: [Waypoint],
        priorConversationTurns: [RouteListEditingConversationTurn],
        endpointContextProvider: @escaping RouteAIEndpointContextProvider,
        intentRouter: @escaping RouteAIIntentRouterHandler,
        conversationResponder: @escaping RouteAIConversationResponder
    ) async -> RouteAIConversationOrchestrationResult {
        let decision = await resolvedDecision(
            for: visibleUserPrompt,
            currentPoints: currentPoints,
            priorConversationTurns: priorConversationTurns,
            intentRouter: intentRouter
        )

        if let decision, decision.handlesConversationLocally {
            let conversationPoints = await resolvedConversationPoints(
                requestDraft: requestDraft,
                currentPoints: currentPoints,
                needsCurrentLocation: decision.needsCurrentLocation,
                endpointContextProvider: endpointContextProvider
            )
            let assistantText = await conversationResponder(
                visibleUserPrompt,
                decision,
                conversationPoints,
                priorConversationTurns
            ) ?? fallbackConversationText(for: decision, currentPoints: conversationPoints)
            return .conversationHandled(assistantText: assistantText)
        }

        return .routeEditing(
            prompt: routeEditingPrompt(
                fallbackPrompt: fallbackRouteEditingPrompt,
                decision: decision
            ),
            needsCurrentLocation: decision?.needsCurrentLocation == true
        )
    }

    public static func fallbackIntentDecision(
        for userPrompt: String,
        currentPoints: [Waypoint],
        priorConversationTurns: [RouteListEditingConversationTurn]
    ) -> RouteAIIntentDecision? {
        guard let routedResponse = RouteAIInputRouter.response(
            for: userPrompt,
            currentPoints: currentPoints,
            priorConversationTurns: priorConversationTurns
        ) else {
            return nil
        }
        return RouteAIIntentDecision(
            intent: routedResponse.intent.routeAIIntent,
            confidence: 0,
            needsCurrentLocation: false,
            usesExistingRoute: !currentPoints.isEmpty,
            shouldCallRouteEditor: false,
            normalizedPrompt: userPrompt,
            assistantReply: routedResponse.fallbackText,
            missingSlots: []
        ).sanitizedForExecution
    }

    public static func fallbackConversationText(
        for decision: RouteAIIntentDecision,
        currentPoints: [Waypoint]
    ) -> String {
        switch decision.intent {
        case .smallTalk:
            return "I am here. I can help find trip ideas, generate routes, or edit waypoints."
        case .inspiration:
            return currentPoints.isEmpty ?
                "Tell me where to start, or say you want to use your current location." :
                "I can use the current waypoints and suggest lighter, quieter, indoor-friendly, or food-focused options."
        case .capabilityQuestion:
            return "I can help find trip ideas, generate routes, and edit waypoint lists."
        case .clarify:
            return decision.missingSlots.isEmpty ?
                "Tell me one more key detail and I will continue." :
                "Tell me \(decision.missingSlots.joined(separator: ", ")) and I will continue."
        case .unsupported:
            return "This tool is focused on trip ideas, route generation, and waypoint editing."
        case .routeCreate, .routeEdit:
            return "I will continue with route editing."
        }
    }

    public static func routeEditingPrompt(
        fallbackPrompt: String,
        decision: RouteAIIntentDecision?
    ) -> String {
        guard let decision else { return fallbackPrompt }
        let prompt = decision.routeEditorPrompt.isEmpty ? fallbackPrompt : decision.routeEditorPrompt
        guard decision.needsCurrentLocation, !prompt.containsCanonicalCurrentLocation else {
            return prompt
        }
        return "from current location, \(prompt)"
    }

    private static func resolvedDecision(
        for userPrompt: String,
        currentPoints: [Waypoint],
        priorConversationTurns: [RouteListEditingConversationTurn],
        intentRouter: @escaping RouteAIIntentRouterHandler
    ) async -> RouteAIIntentDecision? {
        if let decision = await intentRouter(
            userPrompt,
            currentPoints,
            priorConversationTurns
        ) {
            return decision.sanitizedForExecution
        }

        return fallbackIntentDecision(
            for: userPrompt,
            currentPoints: currentPoints,
            priorConversationTurns: priorConversationTurns
        )
    }

    private static func resolvedConversationPoints(
        requestDraft: RouteGenerationIntentDraft,
        currentPoints: [Waypoint],
        needsCurrentLocation: Bool,
        endpointContextProvider: @escaping RouteAIEndpointContextProvider
    ) async -> [Waypoint] {
        guard needsCurrentLocation else { return currentPoints }
        let endpointContext = await endpointContextProvider(requestDraft, true)
        return endpointContext.currentLocationPoint.map { [$0] } ?? currentPoints
    }
}

private extension String {
    var containsCanonicalCurrentLocation: Bool {
        contains("current location") || contains("当前位置") || contains("当前定位") || contains("我的位置")
    }
}
