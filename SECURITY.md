# Security policy

## Supported versions

Security fixes are provided for the latest published release.

## Reporting a vulnerability

Please do not disclose a suspected vulnerability in a public issue. Use the
repository's **Security > Report a vulnerability** flow to open a private
security advisory. Include the affected version, reproduction steps, impact,
and any suggested mitigation. If private advisories are unavailable, open a
minimal public issue asking for a private contact channel without including
sensitive details.

## Credential handling

Never include a real Legacy Central token, network ID, member data, or logs
containing those values in an issue or pull request. Revoke any token that may
have been exposed.

Release signing keys, `android/key.properties`, and built artifacts are not
stored in this repository. Official release artifacts should be verified
against the checksums published with their release.
