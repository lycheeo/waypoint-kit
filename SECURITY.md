# Security

WaypointKit should never contain production service keys.

## Supported Versions

Security reports are accepted for the current main branch and latest release.

## Reporting

Open a private security advisory on GitHub if available. If not, open an issue that describes the affected area without including secrets.

## Secret Handling

- Do not commit OpenAI, AMap, MapKit-server, backend, or analytics keys.
- Use local environment variables, a private config file ignored by git, or a backend token service.
- If a key is accidentally committed, rotate it before publishing or merging.
