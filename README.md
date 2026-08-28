# ZT Central Manager

An unofficial, standalone Android client for managing members of a Legacy
ZeroTier Central account. It talks only to ZeroTier's hosted Legacy Central
API; it does not run a VPN, require root, or depend on the official ZeroTier
app or a Magisk module.

> [!IMPORTANT]
> This client supports **Legacy Central** (`my.zerotier.com`) tokens. New
> Central uses a different API and service-account model and is not supported.

## Features

- Validate and securely store a Legacy Central API token.
- Show unique authorized-device usage across all accessible networks.
- Configure the displayed device allowance (25 by default for grandfathered
  Legacy accounts).
- List networks and search or filter authorized and pending members.
- Authorize and deauthorize devices, with confirmation before deauthorization.
- Rename devices.
- View node IDs, assigned ZeroTier addresses, last physical addresses,
  last-seen times, and client versions.
- Follow the system light or dark theme.

Routes, assignment pools, flow rules, and other advanced network configuration
are deliberately deferred.

## Authentication and privacy

Create a token on the [Legacy Central account page][legacy-account], then paste
it into the app. The token is validated before it is stored. It is protected at
rest with Android Keystore-backed secure storage, application backup and
cleartext traffic are disabled, and signing out deletes the stored token.

The app has no analytics, advertising, crash-reporting SDK, or telemetry. It
requests only Android's Internet permission. See [PRIVACY.md](PRIVACY.md) and
[SECURITY.md](SECURITY.md) for the complete policies.

## Counting and API caveats

Legacy Central does not expose the subscription device allowance through its
API, so the app defaults to 25 and lets the user change it. Usage is calculated
from unique authorized node IDs across all accessible networks, avoiding
double-counting devices that belong to multiple networks.

ZeroTier documents `lastSeen` and `physicalAddress` as ephemeral controller
observations. Missing values are shown as unavailable. Account refresh requests
are serialized and spaced to remain below Legacy Central's free-account rate
limit.

## Development

Requirements: Flutter 3.47.1 (Dart 3.13.1), Android SDK 37, and JDK 21.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Without signing configuration, release builds are intentionally unsigned. For
a distributable APK or app bundle, copy
[`android/key.properties.example`](android/key.properties.example) to
`android/key.properties`, point it at your private release keystore, and build
again. Both the properties file and common keystore extensions are ignored by
Git. Back up the release key securely: updates must be signed with the same key.

Android application ID: `io.github.pythonnut.zerotiercentral`.

### Publishing a release

The simplest release process is to build and sign the universal APK and Android
App Bundle locally, generate SHA-256 checksums, then attach those three files to
a GitHub release. This keeps the private signing key off GitHub entirely.

An optional manually dispatched workflow can build the same artifacts after an
existing release tag has been pushed. To use it, add these Actions secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64-encoded release keystore.
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password.
- `ANDROID_KEY_ALIAS`: Signing-key alias.
- `ANDROID_KEY_PASSWORD`: Signing-key password.

The workflow never uploads the keystore itself and creates a draft for review.
It does not run automatically when tags are pushed.

## Contributing

Bug reports and focused pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) first.

## License and trademarks

The source is available under the [MIT License](LICENSE).

This project is not affiliated with or endorsed by ZeroTier, Inc. ZeroTier and
related marks belong to their respective owner.

[legacy-account]: https://my.zerotier.com/account
