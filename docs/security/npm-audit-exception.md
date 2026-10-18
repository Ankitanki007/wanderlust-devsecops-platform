# Temporary npm audit exception

- Owner: Ankit
- Recorded: 2026-10-18
- Expires: 2026-11-18 at 00:00 UTC
- Advisory: GHSA-vfj7-8cjw-p6xm
- URL: https://github.com/advisories/GHSA-vfj7-8cjw-p6xm
- Package/version: braces@3.0.3
- Scope: backend and frontend development dependency paths only

## Reason and evidence

The reviewed advisory has no patched version listed.
Backend and frontend lockfiles classify braces@3.0.3 as dev-only.
Source search found no direct application use of braces.
Unused tailwindcss-animate was removed.
These checks do not prove that every transitive execution path is safe.

Backend production audit reported zero vulnerabilities.
Frontend production audit reported two moderate findings and no
high/critical findings. React Router remediation remains pending.

## Residual risk and controls

Malicious deeply nested patterns can cause denial of service during
build/test tooling execution. This vulnerability is accepted temporarily,
not fixed. Run only trusted code on the self-hosted runner.
Reassess before public access or any change to the runner trust model.

Full dependency scans and original reports remain enabled.
The policy permits only this exact high-severity advisory when every
affected path is braces@3.0.3 and dev-only, before the expiry.
Other high/critical advisories, invalid reports, and expired exceptions
block the pipeline.

## Validation and follow-up

Six synthetic policy checks passed: exact exception accepted;
production scope, another high advisory, critical severity,
expiry, and invalid report rejected.

Actual GitHub Actions execution and application build/runtime
compatibility remain pending. Review upstream fixes before expiry,
then update or replace affected tooling and remove the exception.
