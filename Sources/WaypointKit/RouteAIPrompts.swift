import Foundation

public enum RouteListEditingPromptBuilder {
    public static func userPromptForEdit(
        currentPoints: [Waypoint],
        userPrompt: String,
        conversationTurns: [RouteListEditingConversationTurn]
    ) -> String {
        let routeSnapshot: String
        if currentPoints.isEmpty {
            routeSnapshot = "Current route has no waypoints."
        } else {
            routeSnapshot = currentPoints.enumerated().map { index, point in
                """
                \(index + 1). point_id=\(point.id.uuidString)
                   name=\(point.name)
                   address=\(point.address)
                   coordinate_wgs84=\(String(format: "%.6f", point.latitude)),\(String(format: "%.6f", point.longitude))
                   stay_minutes=\(point.stayMinutes)
                   selected=\(point.isSelected)
                   city=\(point.cityName ?? "")
                   district=\(point.districtName ?? "")
                   adcode=\(point.adcode ?? "")
                """
            }
            .joined(separator: "\n")
        }

        let history = conversationTurns
            .map { turn -> String in
                let text = turn.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return "" }
                return "\(turn.role): \(text)"
            }
            .filter { !$0.isEmpty }
            .suffix(6)
            .joined(separator: "\n")

        return """
        Current waypoints:
        \(routeSnapshot)

        Recent conversation:
        \(history.isEmpty ? "None" : history)

        User request:
        \(userPrompt)

        Rules:
        - If the user gives a short answer such as "anywhere" or "you decide", continue from the latest assistant question and prior user constraints.
        - If the current route is empty but recent context already contains origin, destination, and preferences, create a complete target waypoint list.
        - Ask a clarification question only when a required slot is missing.
        - Do not invent coordinates. New places must be resolved through provider candidates before they are applied.

        Return a full target waypoint list, or ask one clarification question.
        """
    }
}

public enum RouteListEditingToolSchemas {
    public static var editToolSchema: [String: Any] {
        [
            "type": "function",
            "function": [
                "name": "edit_route_points",
                "description": "Return a full target route point list or ask a clarification question.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "mode": [
                            "type": "string",
                            "enum": ["update", "clarify"]
                        ],
                        "reply_text": ["type": "string"],
                        "question": ["type": "string"],
                        "route_name": ["type": "string"],
                        "summary": ["type": "string"],
                        "operation": [
                            "type": "string",
                            "enum": ["create", "add", "delete", "replace", "reorder", "relax", "theme_change"]
                        ],
                        "target_city": ["type": "string"],
                        "constraints": [
                            "type": "object",
                            "properties": [
                                "avoid": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ],
                                "prefer": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ],
                                "must_include": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ]
                            ],
                            "additionalProperties": false
                        ],
                        "structured_intent": [
                            "type": "object",
                            "properties": [
                                "target_city": ["type": "string"],
                                "route_theme": ["type": "string"],
                                "requested_food": ["type": "boolean"],
                                "requested_current_location": ["type": "boolean"],
                                "pace": ["type": "string"],
                                "mobility": ["type": "string"],
                                "personal_needs": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ],
                                "required_place_kinds": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ],
                                "avoid_place_kinds": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ]
                            ],
                            "additionalProperties": false
                        ],
                        "allows_empty_route": ["type": "boolean"],
                        "target_points": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "existing_point_id": ["type": "string"],
                                    "place_query": ["type": "string"],
                                    "display_name": ["type": "string"],
                                    "search_query": ["type": "string"],
                                    "city": ["type": "string"],
                                    "place_kind": [
                                        "type": "string",
                                        "enum": ["origin", "return", "scenic", "food", "family", "indoor", "nature", "shopping", "other"]
                                    ],
                                    "purpose": ["type": "string"],
                                    "address_hint": ["type": "string"],
                                    "stay_minutes": ["type": "integer"],
                                    "is_selected": ["type": "boolean"]
                                ],
                                "additionalProperties": false
                            ]
                        ]
                    ],
                    "required": ["mode", "reply_text", "summary", "target_points"],
                    "additionalProperties": false
                ]
            ]
        ]
    }

    public static var openAIEditToolSchema: [String: Any] {
        guard let function = editToolSchema["function"] as? [String: Any],
              let parameters = function["parameters"] as? [String: Any] else {
            return [:]
        }
        var openAIParameters = parameters
        if var properties = openAIParameters["properties"] as? [String: Any],
           var targetPoints = properties["target_points"] as? [String: Any],
           var items = targetPoints["items"] as? [String: Any],
           var itemProperties = items["properties"] as? [String: Any] {
            itemProperties["selected_candidate_id"] = ["type": "string"]
            items["properties"] = itemProperties
            targetPoints["items"] = items
            properties["target_points"] = targetPoints
            openAIParameters["properties"] = properties
        }

        return [
            "type": "function",
            "name": "edit_route_points",
            "description": "Return a complete target waypoint list, or ask for clarification.",
            "parameters": openAIParameters
        ]
    }

    public static var searchPOIsToolSchema: [String: Any] {
        [
            "type": "function",
            "name": "search_pois",
            "description": "Batch-search verified POI candidates before adding or replacing real places.",
            "parameters": [
                "type": "object",
                "properties": [
                    "requests": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "request_id": ["type": "string"],
                                "query": ["type": "string"],
                                "city": ["type": "string"],
                                "place_kind": ["type": "string"],
                                "radius_meters": ["type": "integer"],
                                "must": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ],
                                "avoid": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ]
                            ],
                            "required": ["request_id", "query"],
                            "additionalProperties": false
                        ]
                    ]
                ],
                "required": ["requests"],
                "additionalProperties": false
            ]
        ]
    }
}
