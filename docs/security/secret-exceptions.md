# Historical secret exception

- Date: 2026-10-18
- Review by: 2026-11-18, or before public release, whichever is earlier
- Owner: Ankit
- Rule: generic-api-key
- File: backend/.env.docker
- Historical line: 9
- Commit: 1c8d453834c62ac2fcd791531941da5eef9c27ca
- Origin: Inherited upstream application configuration.
- Current remediation: Hard-coded JWT secret removed from current config.
- Upstream credential validity/revocation: Unknown; outside our control.
- Deployment requirement: Generate a new project-owned secret.
- Scope: Only the exact historical fingerprint is excluded.
- Remaining risk: The original value remains visible in Git history.
- Review: Reassess before publishing the repository.
