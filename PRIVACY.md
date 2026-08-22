# Privacy policy

Effective: August 22, 2026

ZT Central Manager is an unofficial client for the Legacy ZeroTier Central API.

## Data the app handles

The app handles the Legacy Central API token supplied by the user and the
network/member data returned for that token. The token is stored locally using
Android Keystore-backed secure storage. The configurable device allowance is
stored locally as an ordinary application preference.

## Network communication

API requests are sent directly to `https://api.zerotier.com`. The token is used
only as the authorization credential for those requests. The account-link
button opens `https://my.zerotier.com` in the user's browser.

## Collection and sharing

The app contains no analytics, advertising, telemetry, or crash-reporting SDK.
The developer does not operate an application backend and does not collect or
share user data through the app. ZeroTier processes API requests under its own
terms and privacy policy.

## Retention and deletion

The API token remains on the device until the user signs out or clears the
app's storage. Signing out deletes the stored token. Uninstalling the app also
removes its local data. Android backup is disabled for the application.

## Contact

Questions about this policy can be opened as an issue in this repository.
