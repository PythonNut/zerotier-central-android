# ZeroTier Central Manager

An independent Android client for managing members of a Legacy ZeroTier
Central account. It talks only to the hosted Legacy Central API; it does not
run a VPN, require root, or depend on the official ZeroTier app or a Magisk
module.

## Current features

- Validate and securely store a Legacy Central API token.
- Show unique authorized device usage across every accessible network.
- Configure the displayed device allowance (25 by default for grandfathered
  Legacy free accounts).
- List networks and their authorized, pending, and total member counts.
- Search and filter network members.
- Authorize and deauthorize members, with confirmation before deauthorization.
- Rename members.
- View each member's node ID, assigned ZeroTier addresses, last physical
  address, last-seen time, and client version.

Routes, assignment pools, flow rules, and other network configuration are
deliberately deferred.

## Authentication

Create a token on the [Legacy Central account page](https://my.zerotier.com/account)
and paste it into the app. The app validates the token before storing it.

The token is stored with `flutter_secure_storage`, backed by Android Keystore.
The application disables Android backup and cleartext network traffic, never
logs API payloads or headers, and requests only `android.permission.INTERNET`.
Signing out deletes the stored token.

New Central uses a different API and service-account authentication model. It
is intentionally outside this initial release's scope.

## Counting and API caveats

Legacy Central does not expose the subscription device allowance through its
API. The app therefore defaults to 25 and lets the user change it. Usage is
calculated from unique authorized node IDs across all networks, avoiding
double-counting a device that belongs to more than one network.

ZeroTier documents `lastSeen` and `physicalAddress` as ephemeral controller
observations. A missing value is displayed as unavailable rather than treated
as an error. The app loads member lists sequentially to remain below the Legacy
free-account API rate limit.

## Development

```sh
flutter test
flutter analyze
flutter build apk --release --target-platform android-arm64
```

Android application ID: `io.github.pythonnut.zerotiercentral`.
