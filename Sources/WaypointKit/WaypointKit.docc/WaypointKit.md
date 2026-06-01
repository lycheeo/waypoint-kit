# ``WaypointKit``

Build AI-assisted route editors where model output remains reviewable, provider-verified, and safe to apply.

## Overview

WaypointKit is a small Swift package extracted from ETA's route-planning core. It keeps a hard boundary between language understanding and route state:

1. A model can classify intent or propose route edits.
2. A `POIProvider` verifies real places.
3. WaypointKit computes diffs, warnings, and proposal narratives.
4. The app applies changes only after user confirmation.

The package stores `Waypoint` coordinates as WGS-84 and keeps provider-specific conversion at adapter boundaries.

## Topics

### Waypoint State

- ``Waypoint``
- ``FavoriteRoute``
- ``PlaceSource``

### Provider Verification

- ``POIProvider``
- ``POISearchRequest``
- ``MockPOIProvider``

### Route Rules

- ``RouteMetrics``
- ``RouteChangeDiffBuilder``
- ``RouteChangeProposal``
- ``RouteChangeProposalNarrative``

### Coordinate Boundaries

- ``CoordinateConverter``
- ``RouteCoordinateSystem``

### AI Route Editing

- ``RouteAIIntent``
- ``RouteAIConversationOrchestrator``
- ``RouteListEditingPromptBuilder``
- ``RouteListEditingToolSchemas``
