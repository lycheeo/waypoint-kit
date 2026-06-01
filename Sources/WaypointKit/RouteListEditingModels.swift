import Foundation

public struct RouteListEditPlanRequestResult {
    public var plan: RouteListEditPlan?
    public var failureMessage: String?

    public static func success(_ plan: RouteListEditPlan) -> RouteListEditPlanRequestResult {
        RouteListEditPlanRequestResult(plan: plan, failureMessage: nil)
    }

    public static func failure(_ message: String) -> RouteListEditPlanRequestResult {
        RouteListEditPlanRequestResult(plan: nil, failureMessage: message)
    }
}

public struct RouteListEditPlan: Decodable {
    public enum Mode: String, Decodable {
        case update
        case clarify
    }

    public var mode: Mode
    public var replyText: String?
    public var question: String?
    public var routeName: String?
    public var summary: String?
    public var operation: String?
    public var targetCity: String?
    public var constraints: RouteListEditConstraints?
    public var structuredIntent: RouteListEditStructuredIntent?
    public var allowsEmptyRoute: Bool
    public var targetPoints: [RouteListEditTargetPoint]
    public var candidatePoints: [String: Waypoint]

    enum CodingKeys: String, CodingKey {
        case mode
        case replyText = "reply_text"
        case question
        case routeName = "route_name"
        case summary
        case operation
        case targetCity = "target_city"
        case constraints
        case structuredIntent = "structured_intent"
        case allowsEmptyRoute = "allows_empty_route"
        case targetPoints = "target_points"
    }

    public init(
        mode: Mode,
        replyText: String? = nil,
        question: String? = nil,
        routeName: String? = nil,
        summary: String? = nil,
        operation: String? = nil,
        targetCity: String? = nil,
        constraints: RouteListEditConstraints? = nil,
        structuredIntent: RouteListEditStructuredIntent? = nil,
        allowsEmptyRoute: Bool = false,
        targetPoints: [RouteListEditTargetPoint],
        candidatePoints: [String: Waypoint] = [:]
    ) {
        self.mode = mode
        self.replyText = replyText
        self.question = question
        self.routeName = routeName
        self.summary = summary
        self.operation = operation
        self.targetCity = targetCity
        self.constraints = constraints
        self.structuredIntent = structuredIntent
        self.allowsEmptyRoute = allowsEmptyRoute
        self.targetPoints = targetPoints
        self.candidatePoints = candidatePoints
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? .clarify
        replyText = try container.decodeIfPresent(String.self, forKey: .replyText)
        question = try container.decodeIfPresent(String.self, forKey: .question)
        routeName = try container.decodeIfPresent(String.self, forKey: .routeName)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        operation = try container.decodeIfPresent(String.self, forKey: .operation)
        targetCity = try container.decodeIfPresent(String.self, forKey: .targetCity)
        constraints = try container.decodeIfPresent(RouteListEditConstraints.self, forKey: .constraints)
        structuredIntent = try container.decodeIfPresent(RouteListEditStructuredIntent.self, forKey: .structuredIntent)
        allowsEmptyRoute = try container.decodeIfPresent(Bool.self, forKey: .allowsEmptyRoute) ?? false
        targetPoints = try container.decodeIfPresent([RouteListEditTargetPoint].self, forKey: .targetPoints) ?? []
        candidatePoints = [:]
    }
}

public struct RouteListEditStructuredIntent: Decodable {
    public var targetCity: String?
    public var routeTheme: String?
    public var requestedFood: Bool?
    public var requestedCurrentLocation: Bool?
    public var pace: String?
    public var mobility: String?
    public var personalNeeds: [String]?
    public var requiredPlaceKinds: [String]?
    public var avoidPlaceKinds: [String]?

    enum CodingKeys: String, CodingKey {
        case targetCity = "target_city"
        case routeTheme = "route_theme"
        case requestedFood = "requested_food"
        case requestedCurrentLocation = "requested_current_location"
        case pace
        case mobility
        case personalNeeds = "personal_needs"
        case requiredPlaceKinds = "required_place_kinds"
        case avoidPlaceKinds = "avoid_place_kinds"
    }

    public init(
        targetCity: String? = nil,
        routeTheme: String? = nil,
        requestedFood: Bool? = nil,
        requestedCurrentLocation: Bool? = nil,
        pace: String? = nil,
        mobility: String? = nil,
        personalNeeds: [String]? = nil,
        requiredPlaceKinds: [String]? = nil,
        avoidPlaceKinds: [String]? = nil
    ) {
        self.targetCity = targetCity
        self.routeTheme = routeTheme
        self.requestedFood = requestedFood
        self.requestedCurrentLocation = requestedCurrentLocation
        self.pace = pace
        self.mobility = mobility
        self.personalNeeds = personalNeeds
        self.requiredPlaceKinds = requiredPlaceKinds
        self.avoidPlaceKinds = avoidPlaceKinds
    }
}

public struct RouteListEditConstraints: Decodable {
    public var avoid: [String]?
    public var prefer: [String]?
    public var mustInclude: [String]?

    enum CodingKeys: String, CodingKey {
        case avoid
        case prefer
        case mustInclude = "must_include"
    }

    public init(avoid: [String]? = nil, prefer: [String]? = nil, mustInclude: [String]? = nil) {
        self.avoid = avoid
        self.prefer = prefer
        self.mustInclude = mustInclude
    }
}

public struct RouteListEditTargetPoint: Decodable {
    public var existingPointID: String?
    public var selectedCandidateID: String?
    public var placeQuery: String?
    public var displayName: String?
    public var searchQuery: String?
    public var city: String?
    public var placeKind: String?
    public var purpose: String?
    public var addressHint: String?
    public var stayMinutes: Int?
    public var isSelected: Bool?

    enum CodingKeys: String, CodingKey {
        case existingPointID = "existing_point_id"
        case selectedCandidateID = "selected_candidate_id"
        case placeQuery = "place_query"
        case displayName = "display_name"
        case searchQuery = "search_query"
        case city
        case placeKind = "place_kind"
        case purpose
        case addressHint = "address_hint"
        case stayMinutes = "stay_minutes"
        case isSelected = "is_selected"
    }

    public init(
        existingPointID: String? = nil,
        selectedCandidateID: String? = nil,
        placeQuery: String? = nil,
        displayName: String? = nil,
        searchQuery: String? = nil,
        city: String? = nil,
        placeKind: String? = nil,
        purpose: String? = nil,
        addressHint: String? = nil,
        stayMinutes: Int? = nil,
        isSelected: Bool? = nil
    ) {
        self.existingPointID = existingPointID
        self.selectedCandidateID = selectedCandidateID
        self.placeQuery = placeQuery
        self.displayName = displayName
        self.searchQuery = searchQuery
        self.city = city
        self.placeKind = placeKind
        self.purpose = purpose
        self.addressHint = addressHint
        self.stayMinutes = stayMinutes
        self.isSelected = isSelected
    }
}

public struct OpenAISearchCall {
    public var callID: String
    public var arguments: String

    public init(callID: String, arguments: String) {
        self.callID = callID
        self.arguments = arguments
    }
}

public struct OpenAISearchToolResult {
    public var outputText: String
    public var candidatePoints: [String: Waypoint]
    public var displayCandidateNames: [String]

    public init(outputText: String, candidatePoints: [String: Waypoint], displayCandidateNames: [String]) {
        self.outputText = outputText
        self.candidatePoints = candidatePoints
        self.displayCandidateNames = displayCandidateNames
    }
}

public struct OpenAIAMapSearchToolRequest: Decodable {
    public var requests: [OpenAIAMapSearchRequest]
}

public struct OpenAIAMapSearchRequest: Decodable {
    public var requestID: String?
    public var query: String
    public var city: String?
    public var placeKind: String?
    public var radiusMeters: Int?
    public var must: [String]?
    public var avoid: [String]?

    enum CodingKeys: String, CodingKey {
        case requestID = "request_id"
        case query
        case city
        case placeKind = "place_kind"
        case radiusMeters = "radius_meters"
        case must
        case avoid
    }
}
