# Maintenance Evidence

WaypointKit is an early open-source extraction from ETA, a private iOS route-planning app. This document records what is public, what was verified locally before extraction, and what is intentionally kept out of the repository.

## Public Evidence

- Repository: https://github.com/lycheeo/waypoint-kit
- Release: https://github.com/lycheeo/waypoint-kit/releases/tag/v0.1.1
- License: MIT
- Validation command: `swift run WaypointKitValidation`
- Current validation coverage: 39 framework-free validation cases
- Follow-up pull request: https://github.com/lycheeo/waypoint-kit/pull/5
- Public maintenance plan:
  - https://github.com/lycheeo/waypoint-kit/issues/1
  - https://github.com/lycheeo/waypoint-kit/issues/2
  - https://github.com/lycheeo/waypoint-kit/issues/3
  - https://github.com/lycheeo/waypoint-kit/issues/4

## Local Source Evidence

The reusable route-planning boundary came from ETA's private development history. The private app is not published here because it contains app-specific UI code, provider wiring, archived experiments, signing metadata, and local validation artifacts.

Local evidence inspected before extraction:

| Artifact | Public-safe summary |
| --- | --- |
| `releases/V4final/V4final_MANIFEST.md` | Documents ETA V4.20 as a frozen route-editing baseline dated 2026-05-25. |
| `releases/V4final-full.zip` | Local frozen archive for the V4.20 baseline. SHA-256: `eb87b64e94e4a94ed2250d3bcbd61900327b9e107e6d7cae21d9f283a1bb8ebb`. |
| `artifacts/archives/ETA-V5.70-b148.xcarchive` | Local iOS archive for ETA V5.70 build 148, created 2026-05-28. |
| `artifacts/screenshots/` | 15 local screenshots covering early simulator and device UI validation from V2 through V5. |
| `ETA_AGENT_PROMPT.md` | Local development log with versioned build, install, validation, and scope notes. It is not copied into this repository because it is private project context. |
| `docs/AI交互工作流.md` | Local design and validation notes for the AI route-editing workflow, including routing, prompt boundaries, regression notes, and model-failure behavior. |

## Extracted Maintainer Lessons

The open-source package keeps only the reusable core:

- waypoint identity and de-duplication
- WGS-84 / GCJ-02 coordinate conversion
- route metric fallback behavior
- route-change diffing and proposal summaries
- AI intent routing between conversation, trip inspiration, route creation, and route editing
- prompt and tool-schema boundaries for verified POI search
- deterministic validation cases that do not require private API keys

The package does not publish ETA's private app shell, provider credentials, signing information, device identifiers, or vendor-specific service clients.

## Why This Matters

The main maintenance lesson from ETA is that route-editing AI needs a hard boundary between model output and route state. A model can interpret the user's intent, but the app must verify places, compute diffs, show a reviewable proposal, and apply changes only after confirmation.

WaypointKit turns that boundary into a small Swift package that can be maintained publicly.
