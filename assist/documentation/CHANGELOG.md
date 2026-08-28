# Changelog

## Version State

Current version: 1.0.3

Release tag: v-1.0.3

Changelog label: v 1.0.3

## v-1.0.3

### [v 1.0.3] 2026-08-28 11:50 am - Mobile production release

#### Database Changes

- Database update: No.

#### App Codebase Changes

- Bumped repository version to 1.0.3.
- Published the Cloud-locked Flutter production build as version 1.0.3.
- Kept Android build number 10011 so newer installed builds can accept the update.
- Renamed the production APK to `logicx-loom-v1.0.3.apk`.
- Connected mobile login, Dashboard, and Messenger to `https://log.logicx.in`.
- Added the white Messenger layout, blue actions, and light-blue chat background.
- Kept the single-color `#305DDD` launcher logo without a dark background.
- Removed the Loom machine-key restriction from `POST /loomdata` during testing so every valid JSON
  payload is stored unchanged for later field processing.
- Rebuilt the v1.0.3 Android production package as build 10012 with the corrected
  `https://log.logicx.in/api/platform` mobile API URL.

## v-1.0.2

### [v 1.0.2] 2026-08-28 9:53 am - Repository cleanup and GitHub readiness

#### Database Changes

- Database update: No.

#### App Codebase Changes

- Bumped repository version to 1.0.2.
- Added `tmp/` to the Git and Docker ignore rules.
- Removed generated build output, temporary QA files, IDE state, and mobile build caches.
- Kept environment files, signing credentials, release files, dependencies, and application source.
- Confirmed that the local `main` branch matches `origin/main`.
- Confirmed that GitHub has no Actions runs or releases for this repository.
- Verified the proposed `github:now` commit with a dry run. No commit or push occurred.
- Passed version, boundary, database lifecycle, typecheck, lint, test, deployment contract, and build checks.

## v-1.0.1

### [v 1.0.1] 2026-08-28 - Start the LogicX Loom application

#### Database Changes

- Database update: Yes.
- Added local storage for all JSON payloads received from Loom machines.
- Kept the local Messenger conversations, members, and messages.

#### App Codebase Changes

- Copied the TechMedia application as the starting codebase.
- Rebranded the application as LogicX Loom and continued development from this baseline.
- Kept Login, Dashboard, and Messenger as the active application areas.
- Added the public `/loomdata` JSON endpoint and the raw Dashboard data stack.
- Added Docker deployment settings for `log.logicx.in`.
- Added WebSocket proxy support for Messenger.
- Set separate deployment host ports for the API, WebSocket, and Web services.
