# Evaluation Fixtures

WaypointKit keeps model-facing behavior behind deterministic fixtures before it is wired to a live LLM or POI provider. The current evaluation surface is intentionally small and local.

## Route-Edit Regression Fixtures

Fixture file:

```text
Fixtures/route-edit-regressions.json
```

Validation command:

```bash
swift run WaypointKitValidation
```

The validation executable decodes the fixture file and checks that each case produces the expected:

- route diff kind
- proposal card title
- safety line
- route usability result
- blocking warning behavior
- point-count delta text

Current cases:

| Case | Purpose |
| --- | --- |
| `replace-museum-with-riverside` | Replacing one verified waypoint should produce one replacement, not a broad route rewrite. |
| `append-food-stop` | Adding a verified food stop should produce one add change and keep the route usable. |
| `reorder-final-walk-first` | Reordering the same waypoint set should stay a reorder, not become remove/add churn. |
| `delete-to-single-stop-blocked` | A one-stop proposal should remain reviewable but blocked from application. |

## Why Fixtures Matter

The OpenAI-facing prompt and tool schema can change over time, but route state must remain deterministic. These fixtures make the review boundary visible:

1. A model can interpret a user request.
2. A provider must verify any new place before it becomes a waypoint.
3. WaypointKit computes the final diff and warnings locally.
4. The app applies the proposal only after user confirmation.

Future evaluation work should add multi-turn cases, candidate disambiguation cases, and provider-neutral mock POI search results.
