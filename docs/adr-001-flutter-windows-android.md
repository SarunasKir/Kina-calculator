# ADR 001: Flutter for Windows and Android, synced over Wi-Fi

- Status: accepted
- Date: 2026-10-21

## Context

The v55 calculator is a single Windows executable written in Go against raw
Win32. Its maths (`finance`, `marketcalc`) is well tested, but the UI is about
3,000 lines of hand-placed controls with no tests, and it cannot run on a
phone. The new app must run locally on a Windows PC and an Android phone, keep
data in sync between them, and never depend on a hosted web service.

## Decision

- Build one Flutter app for Windows and Android. iPhone and macOS are out of
  scope.
- Keep all maths in the pure Dart package `kina_core`, using exact decimal
  arithmetic and rounding to cents at each step, as v55 does.
- Store data locally in SQLite (Drift) on each device.
- Sync over the local Wi-Fi network with the PC as hub, paired once by QR code.

## Consequences

- The v55 test cases are carried over as parity tests, so behaviour can be
  checked against the old app.
- Flutter's Windows support is first-party, and Dart's standard library
  includes the HTTP server needed for the sync hub.
- The phone only syncs when the PC app is running on the same network. A
  cloud-folder sync can be added later if needed.
