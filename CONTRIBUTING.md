# Contributing to MyPortal iOS

## First-time setup

### 1. Point `xcode-select` at full Xcode

The project uses tools (`xcodebuild`, `xcrun simctl`, …) that ship with full
Xcode, not the Command Line Tools. One-off:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Verify with `xcode-select -p` — should print `/Applications/Xcode.app/Contents/Developer`.

### 2. Trust the ASP.NET dev cert in the simulator

The iOS Simulator has its own CA store, separate from macOS. Without the
ASP.NET dev cert installed, `https://localhost:7201` calls (school setup,
OAuth, every API request) fail TLS.

Boot a simulator, then:

```sh
# Export the dev cert from the host's dotnet store
dotnet dev-certs https --export-path ~/aspnetdev.cer --no-password --format PEM

# Install it as a trusted root in the currently-booted simulator
xcrun simctl keychain booted add-root-cert ~/aspnetdev.cer
```

Force-quit and relaunch MyPortal in the simulator — everything trusts
`localhost` after this.

**Notes**:

- Repeat the `xcrun simctl keychain` step for each fresh simulator (or after
  `xcrun simctl erase`). The host's keychain trust doesn't propagate.
- For a real device: drag the `.cer` over via Finder, then **Settings →
  General → VPN & Device Management** → install, then **Settings → General →
  About → Certificate Trust Settings** → flip the toggle for the cert. No
  simctl shortcut on physical devices.
- Production builds use the system trust store unchanged.

### 3. Backend redirect URI

`MyPortal.WebApi/AuthSeeder.cs` already registers `myportal://oauth/callback`
as a redirect URI for the public OAuth client. No action needed — listed here
because it's easy to miss.

## Running the app

```sh
open MyPortal.xcodeproj
```

`MyPortalApp.swift` is the entry point. `RootView` routes through:

```
loading → needsSchool → needsLogin → authenticated(UserInfo)
```

First-run flow:

1. **School URL screen** — enter `https://localhost:7201` (or wherever your
   API is). Validates against `GET /api/schools/local/name` (anonymous).
2. **Sign in** — OAuth Authorization Code + PKCE via
   `ASWebAuthenticationSession`. Backend Razor login page handles
   credentials, redirects back to `myportal://oauth/callback?code=…`.
3. **Bootstrap** — `GET /api/me` fetches permissions; app routes to the
   portal matching `userType` (Staff / Student / Parent).

## Conventions

- **Services own HTTP shapes**, view models / views own UI state. See
  `Services/BulletinsService.swift` for the protocol + Live + Mock pattern.
- **Permissions** — server keys are mirrored in `Session/Permissions.swift`
  and consumed via per-feature access policies (e.g.
  `Features/Bulletins/BulletinAccessPolicy.swift`). Add new keys as you use
  them; the server is the authority.
- **Localisation** — write user-facing strings as literals in `Text(…)` /
  `Button(…)` etc. and they're picked up by `Resources/Localizable.xcstrings`
  on the next build. For runtime-constructed strings (errors, dynamic
  labels), wrap in `String(localized: "…")`.
- **Design tokens** — `Spacing.{xs,s,m,l,xl,xxl}`, `CornerRadius.{s,m,l,xl}`,
  `Brand.indigo*`, `.cardSurface()`. Reach for these before hardcoded
  numbers.
- **Previews** — every view should preview without hitting the network.
  Stub services with `MockBulletinsService().withSummaries(...)` etc.;
  AppSession previews via `AppSession.preview(phase:bulletinsService:…)`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "The certificate for this server is invalid" on School Setup or Sign In | Dev cert not installed in simulator | Run the `xcrun simctl keychain booted add-root-cert …` step above |
| "Server error 401" on School Setup's Check | `local/name` endpoint missing `[AllowAnonymous]` | Already fixed; pull latest backend |
| Sign in opens then immediately closes with no error | `myportal://oauth/callback` not in `AuthSeeder.cs` | Check the DEBUG block adds it |
| Bulletins shows "cancelled" | Was a Swift Concurrency / view-lifecycle issue with `URLSession.data(for:)` | Already fixed — `URLSession.dataAllowingDevCert` uses a continuation-wrapped `dataTask` to dodge spurious Task cancellation |
