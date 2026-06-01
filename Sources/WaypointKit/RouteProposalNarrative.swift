import Foundation

public enum RouteChangeProposalNarrative {
    public static func assistantText(for proposal: RouteChangeProposal) -> String {
        let intro = introText(for: proposal)
        let confidence = "I will keep this as a proposal until it is explicitly applied."
        guard let summary = normalized(proposal.summary) else {
            return "\(intro)\n\(confidence)"
        }
        return "\(intro)\n\(summary)\n\(confidence)"
    }

    public static func cardTitle(for proposal: RouteChangeProposal) -> String {
        if proposal.beforePoints.isEmpty {
            return "\(proposal.proposedPoints.count) waypoints to review"
        }
        let count = changeLines(for: proposal).count
        if count == 0 {
            return "No waypoint changes"
        }
        return "\(count) changes to review"
    }

    public static func changeLines(for proposal: RouteChangeProposal) -> [String] {
        let lines = proposal.changes.map(lineText(for:))
        if !lines.isEmpty {
            return lines
        }
        if proposal.beforePoints.isEmpty, !proposal.proposedPoints.isEmpty {
            return proposal.proposedPoints.map { "Add \($0.name)" }
        }
        return []
    }

    public static func safetyLine(for proposal: RouteChangeProposal) -> String {
        if proposal.isRouteUsable {
            return "The waypoint list changes only after confirmation."
        }
        return "This proposal has too few selected waypoints to apply."
    }

    private static func introText(for proposal: RouteChangeProposal) -> String {
        switch proposal.source {
        case .ai:
            if proposal.beforePoints.isEmpty {
                return "I prepared a new route from your request."
            }
            if proposal.changes.isEmpty {
                return "I interpreted this as keeping the current route unchanged."
            }
            return "I prepared the requested route edit."
        case .generatedRouteReplace:
            return "I prepared waypoints to replace the current route."
        case .generatedRouteAppend:
            return "I prepared waypoints to append to the current route."
        }
    }

    private static func lineText(for change: RoutePointChange) -> String {
        switch change.kind {
        case .added:
            return "Add \(change.afterName ?? "new waypoint")"
        case .removed:
            return "Remove \(change.beforeName ?? "old waypoint")"
        case .replaced:
            return "Replace \(change.beforeName ?? "old waypoint") with \(change.afterName ?? "new waypoint")"
        case .reordered:
            return "Reorder waypoints"
        }
    }

    private static func normalized(_ text: String?) -> String? {
        let value = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

public enum RouteEditingFailureNarrative {
    public static func message(from rawMessage: String?) -> String {
        let reason = normalizedReason(rawMessage)
        return """
        No applicable waypoint edit was produced, so the current waypoint list was not changed.
        Reason: \(reason)
        You can retry with a more specific origin, destination, add, delete, or replace request.
        """
    }

    public static func isFailureMessage(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        return value.localizedCaseInsensitiveContains("failed")
            || value.localizedCaseInsensitiveContains("not changed")
            || value.localizedCaseInsensitiveContains("could not parse")
            || value.contains("失败")
            || value.contains("未改动")
            || value.contains("无法解析")
            || value.contains("没有返回")
            || value.contains("没有通过")
    }

    private static func normalizedReason(_ rawMessage: String?) -> String {
        var value = rawMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let removableSuffixes = [
            ", waypoint list was not changed.",
            "，点位列表未改动。",
            "，点位列表未改动",
            "点位列表未改动。",
            "点位列表未改动"
        ]
        for suffix in removableSuffixes where value.hasSuffix(suffix) {
            value = String(value.dropLast(suffix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if value.isEmpty {
            return "The model did not return a usable result"
        }
        return value
    }
}
