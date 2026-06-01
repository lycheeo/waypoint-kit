# Architecture

WaypointKit is intentionally small. It is a route-planning core, not a map UI or navigation app.

## Layers

### 1. Waypoint State

`Waypoint` stores the route fact source:

- display name and address
- WGS-84 coordinate
- selected state
- stay time
- provider metadata such as category, city, district, and adcode

Apps can render these waypoints however they want.

### 2. Deterministic Route Rules

The rule layer handles logic that should not depend on a model:

- place identity and de-duplication
- search-history and favorite ordering
- stay-time and distance fallback metrics
- route diffing and safety warnings
- WGS-84 / GCJ-02 conversion

### 3. AI Intent Routing

`RouteAIInputRouter` and `RouteAIConversationOrchestrator` separate conversational turns from route-editing turns.

Small talk, capability questions, and trip inspiration can stay conversational. Route creation and route edit requests are routed to the editing flow.

### 4. Provider Verification

`RouteListEditingToolSchemas.searchPOIsToolSchema` exists because model output should not directly become route state. Apps should search a real POI provider, return candidate IDs, and only apply verified waypoints.

### 5. Proposal Application

`RouteChangeDiffBuilder` and `RouteChangeProposalNarrative` turn a target waypoint list into reviewable changes. The app decides when to apply the proposal.

## Non-Goals

- No turn-by-turn navigation.
- No map rendering UI.
- No bundled API keys.
- No direct dependency on a single LLM or POI provider.
