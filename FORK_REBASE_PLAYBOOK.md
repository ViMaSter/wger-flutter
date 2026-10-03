# Upstream Rebase and Fork Feature Playbook

Use this playbook whenever updating this fork from `wger-project/flutter` upstream. It records the fork behavior to preserve and the checks required before considering a rebase complete.

## Reusable Request

Copy and send this request when starting an update:

> Fetch the latest `upstream/master` and rebase this fork's changes on it. First inspect the current branch graph, working tree, and upstream changes. Preserve or reimplement every behavior in `FORK_REBASE_PLAYBOOK.md`, adapting it to upstream's current architecture rather than restoring obsolete code verbatim. Do not push to any remote. Do not discard unrelated working-tree changes. Add or update focused tests for preserved behavior, run the listed checks, and deploy a signed Android release to the USB-connected device only if it is available. Report conflicts, behavior intentionally changed, tests run, and any remaining limitations.

## Rebase Rules

- Fetch upstream before comparing: `git fetch upstream master`.
- Inspect `git status`, the branch graph, merge base, and fork-only commits before changing history. This branch has previously included an upstream merge, so do not assume a plain `git rebase upstream/master` selects only fork commits.
- Compare the fork's behavior with current upstream. If upstream has already implemented a behavior, keep one implementation and retain its tests; do not duplicate it.
- Resolve conflicts in favor of the intended behavior below, not automatically in favor of either side. Do not use `-X theirs` as a blanket conflict strategy.
- Do not reset, clean, or overwrite user changes. Do not push unless explicitly asked.
- Keep generated files and local signing material out of commits unless the repository explicitly tracks them.

## Fork Behaviors to Preserve

### Wear OS workout companion

- The intended watch screen displays the active exercise, repetitions, weight, current/total set count, and rest countdown.
- The phone sends workout and timer state over `watch_connectivity`; timer updates should be merged with existing watch context rather than erasing unrelated data.
- Detect Wear OS devices and route them to the watch UI. **Current gap:** `WatchScreen` exists in `lib/screens/watch_screen.dart`, but current `lib/main.dart` does not reference it, so the watch UI is presently unreachable. Rebase work should wire this up and test both watch and ordinary-phone routing.
- Keep the watch awake while in the workout screen and provide countdown haptics, including a distinct expiry vibration.
- Relevant code: `lib/main.dart`, `lib/screens/watch_screen.dart`, `lib/screens/auth_screen.dart`, `lib/widgets/routines/gym_mode/log_page.dart`, `lib/widgets/routines/gym_mode/timer.dart`, `android/app/build.gradle`, and `android/app/src/main/AndroidManifest.xml`.

### Gym-mode rest timer

- Keep the timer running across workout-page swipes/navigation; it must not restart merely because the timer widget is rebuilt.
- Provide `-15s`, `+15s`, and reset-to-configured-minimum/maximum controls.
- On expiry, notify/vibrate once, tolerate devices without vibration support, and clear expired timer state so a later timer can start normally.
- Send timer changes to the paired watch.
- Relevant code: `lib/widgets/routines/gym_mode/timer.dart` and `lib/providers/gym_state.dart`.

### Gym log and comments

- Show current set / total sets in the gym-mode log header.
- Make HTTP(S) links in the gym-mode exercise comment tappable and open them externally. Keep ordinary comment text readable and handle invalid/unlaunchable URLs without crashing.
- Relevant code: `lib/widgets/routines/gym_mode/log_page.dart`.

### Routine-day presentation

- Show a slot comment after its exercise/set rows, not before them.
- Omit an empty day description rather than reserving an empty subtitle row; preserve the intended day-header alignment and spacing.
- Preserve exercise and set grouping when adapting this layout to upstream's current routine widgets.
- Relevant code: `lib/widgets/routines/day.dart`.

### Android requirements

- Preserve the Android requirements needed by Wear OS and vibration. The fork currently sets `minSdkVersion` to 30 and includes Wear libraries plus the vibration permission.
- Review current upstream/plugin requirements before keeping or changing the minimum SDK; document any intentional change because it affects device compatibility.
- Relevant code: `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`, `android/gradle.properties`, `android/gradle/wrapper/gradle-wrapper.properties`, and `pubspec.yaml`.

## Tests to Maintain or Add

Run the existing focused Flutter tests:

```sh
flutter test test/providers/gym_state_test.dart \
  test/widgets/routines/gym_mode/log_page_test.dart \
  test/routine/gym_mode/gym_mode_test.dart
```

Add focused tests if the behavior is not covered after the rebase:

- **Watch routing:** watch device goes to the watch screen; phone/tablet goes to the normal app.
- **Watch data:** incoming exercise, reps, weight, set count, and timer messages update the screen; malformed or absent context does not crash it.
- **Timer:** fake-time tests for persistence across widget/page changes, +/-15s, min/max resets, one-shot expiry, and unsupported vibration.
- **Linkified comment:** plain text remains plain; HTTP(S) is styled as a link and tapping requests an external launch; malformed or rejected launch is handled.
- **Routine layout:** comment follows exercise rows; empty description creates no subtitle; grouping and spacing remain correct.

Suggested locations are `test/screens/watch_screen_test.dart` and `test/widgets/routines/gym_mode/timer_test.dart`, following the existing `test/widgets/routines/gym_mode/` and `test/routine/gym_mode/` conventions. Avoid tests that require a real watch; mock the platform/channel boundary for automated coverage.

## Rebase Validation

Run from the repository root after resolving conflicts:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed \
  lib/main.dart lib/screens/watch_screen.dart \
  lib/widgets/routines/gym_mode/log_page.dart \
  lib/widgets/routines/gym_mode/timer.dart lib/widgets/routines/day.dart
flutter analyze
flutter test test/providers/gym_state_test.dart \
  test/widgets/routines/gym_mode/log_page_test.dart \
  test/routine/gym_mode/gym_mode_test.dart
flutter build apk --release
```

If release compilation reports an `integration_test` registration in `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`, investigate the generated plugin state and fix the source/configuration or regenerate it correctly. Do not silently rely on a one-off edit to a generated registrant.

## Device Smoke Tests

- Confirm the intended phone is attached with `adb devices -l`; use its exact device ID.
- Install and launch a **release** build on the USB-connected Android phone. Confirm the normal app starts, can reach Gym Mode, and comments and timer controls respond.
- On a paired Wear OS device, confirm the companion screen launches, workout/set data updates when changing exercises or sets, timer changes synchronize, and countdown/expiry haptics work.
- Check logs for startup or plugin-registration exceptions. A successful APK build alone does not prove the watch flow works.
- If Android reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, explain that the installed package has a different signing certificate. Ask before uninstalling because uninstalling removes the app's local data.

## Signing and Secrets

- Release signing uses `fastlane/metadata/envfiles/key.properties` and its referenced keystore. These are ignored local files; never commit the keystore, passwords, or decrypted secrets.
- A locally generated self-signed key is suitable only for local testing. It is not interchangeable with the Play Store upload key; preserve the established signing key for future updates to an installed release.
- If signing material is missing, explain the choices before generating a replacement. A replacement certificate can prevent updating an already-installed release without uninstalling it.
- `sentry_flutter` was added in this fork, but the current code has no active Sentry initialization/capture call. Do not claim runtime error reporting works unless it is explicitly wired and tested.

## Completion Report

Summarize the upstream revision used, fork features preserved or reimplemented, conflict resolutions, automated tests/builds run, physical-device checks completed, and any feature that remains unreachable or unverified. State explicitly that no remote was pushed.