# LogicX Loom Flutter

This is a separate Flutter client for LogicX Loom. It does not import, render, or
share UI code with the Ionic application. It communicates only through the
existing LogicX Loom HTTP and WebSocket API contracts.

## Run with the local API on Android

Copy `.env.example` to `.env`, set the `MOBILE_*` values, start the LogicX Loom
Node API, then run the Flutter app on the Android emulator:

```powershell
.\tools\flutter-mobile.ps1 run
```

`10.0.2.2` is the Android emulator route to the computer's localhost. The development
URL points to the API root without `/api/platform`. That prefix belongs to the
production reverse proxy. Set `MOBILE_APP_ENVIRONMENT` to `development` or `production`.
The build script compiles `MOBILE_DEVELOPMENT_API_URL` or `MOBILE_PRODUCTION_API_URL`
into the app. The installed app does not let users change the endpoint.
Development auto-login is available only for local API addresses and is off by
default, so it cannot activate against the production API.

## Connected mobile scope

- Native Flutter sign-in UI using `POST /auth/login`.
- Encrypted access-token persistence and session restore using `GET /auth/session`.
- Platform health check using `GET /health`.
- Raw Loom payload synchronization using `GET /loomdata/events` every three seconds.
- Messenger conversations and sends through the REST API.
- Realtime Messenger updates through `/ws/messaging` with automatic reconnect.
- Dashboard and Messenger are the only active mobile destinations.
- The app checks `/storage/mobile/release/update.json` during startup.
- The app downloads a newer APK only after the user selects Update.
- Android shows its system installer before it replaces the installed app.
- Separate Android application identity: `in.logicxloom.logicx_loom_flutter`.

## Publish an Android update

Build the APK with a higher build number. Copy it to
`storage/mobile/release/logicx-loom-v1.0.3.apk`. Update `update.json` with the APK checksum and size.

All releases must use the same Android signing key. Android rejects an APK signed with another
key.
