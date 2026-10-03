# Upstream Rebase Report

Date: 2026-10-03

## History and Working Tree

- Original fork: `909c180f` on `master`.
- Fetched upstream: `4587889e2f6c1867270c5d348648b12d91662261`.
- Original merge base: `a93039938b48a9ba16290abe8871e953ea638d7c`.
- Rebased HEAD: `7f96b88e61d49409b6d976b67efbb8c5be58b142`.
- Upstream is an ancestor of the rebased branch. The previous upstream merge was
  not replayed as fork implementation.
- Nine fork commits were replayed; fourteen became empty after obsolete code and
  superseded dependency changes were resolved. Their required behavior was ported
  into upstream's current modules rather than restoring deleted source files.
- Feature ports, tests, dependency regeneration, and this report remain
  uncommitted. No additional implementation commits or branches were created.
- The pre-existing untracked `FORK_REBASE_PLAYBOOK.md` was left unchanged.
- No remote was pushed. Origin retains the original fork history.

## Conflict Resolutions and Adaptations

- Kept upstream's Riverpod architecture, startup sequence, `material_ui`, feature
  directories, Android toolchain, and native FragmentActivity/Health Connect code.
- Did not restore deleted legacy authentication, provider, or routine widget files.
- Kept upstream dependency constraints instead of replaying older version bumps.
- Preserved upstream's macOS Podfile-lock deletion; regenerated tracked plugin
  registrants through Flutter tooling, not manual generated-file patches.
- Removed the machine-specific iOS ephemeral environment file replayed by an old
  fork commit. Signing material and generated Android files were not staged.
- Replaced `com.android.support:wear:27.1.1` with `androidx.wear:wear:1.3.0` to
  resolve duplicate classes with current AndroidX plugins. Kept the wearable
  runtime libraries, minimum SDK 30, vibration permission, and wake-lock support.
- Watch detection uses Android's watch feature rather than the old model-name
  heuristic. Watch and ordinary-phone routing have separate tests.
- Timer persistence is scoped to the application provider/workout lifecycle,
  rather than the old process-global singleton; workout resets clear it.
- Min/max controls use current set rest bounds; user countdown preferences are
  the fallback. An absent maximum disables that reset rather than inventing one.

## Preserved Behavior

- Watch routing, exercise/repetitions/weight/current-and-total-set display,
  initial and live context updates, countdown, wakelock, and safe haptics.
- Serialized phone updates merge nested context so timer changes do not erase
  workout data. Unsupported/disconnected platform operations are tolerated.
- Timer persistence across rebuilds/navigation, +/-15 seconds, min/max resets,
  one-shot expiry while unmounted, cleared expired state, and later restart.
- Watch expiry vibration survives the phone clearing the timer before the
  watch's local expiry tick; duplicates do not double-notify.
- Gym log set counts and safe, externally launched HTTP(S) comment links.
- Slot comments follow grouped exercise rows; empty/whitespace descriptions
  create no subtitle spacing. Upstream grouping is retained.

## Validation

The installed stable Flutter 3.44.1/Dart 3.12.1 cannot resolve upstream's
`freezed ^4.0.2`, which requires Dart >=3.13. Validation used an isolated SDK at
`/tmp/wger-flutter-sdk-20261003`: Flutter revision `53d381d906`,
Flutter 3.49.0-0.2.pre, Dart 3.14.0 development build. The stable installation was
not changed. API 37 was installed by the Android build tooling.

Passed:

- `flutter pub get` with the compatible SDK.
- Playbook formatting checks at the relocated paths, plus new production files.
- 83 focused tests across these files:
  - `test/features/routines/providers/gym_state_test.dart`
  - `test/features/routines/widgets/gym_mode/log_page_test.dart`
  - `test/features/routines/gym_mode_test.dart`
  - `test/features/routines/screens/gym_mode_test.dart`
  - `test/core/watch_companion_test.dart`
  - `test/screens/watch_screen_test.dart`
  - `test/screens/watch_routing_test.dart`
  - `test/features/routines/widgets/gym_mode/timer_test.dart`
  - `test/features/routines/services/gym_rest_timer_test.dart`
  - `test/features/routines/widgets/day_test.dart`
- `flutter build apk --release`: signed APK, approximately 109.8 MB, at
  `build/app/outputs/flutter-apk/app-release.apk`.
- `apksigner verify --verbose`: one signer, APK Signature Scheme v2 verified.
- APK metadata: package `de.wger.flutter`, min SDK 30, target SDK 36;
  `VIBRATE` and `WAKE_LOCK` permissions present.
- `git diff --check`.

`flutter analyze` ran with no errors or warnings, but exited nonzero with four
upstream informational deprecation findings under the newer Flutter SDK:
legacy Material scope and its test, and generated Material/Cupertino localization
delegates. No findings remain in the changed files.

An initial release retry using `--no-pub` reused a test-generated registrant with
`integration_test`. The plain `flutter build apk --release` command correctly
regenerated release tooling and excluded the dev plugin. No generated Java file
was hand-edited. Run tests before the final release build, and allow release
tooling regeneration rather than reusing a test registrant.

## Remaining Limitations

- A subsequent device check found `emulator-5554` (`sdk_gphone64_arm64`).
  The signed release APK installed successfully using `adb install -r`, without
  uninstalling or clearing local data. Activity launch and relaunch succeeded;
  the normal phone login screen was visually confirmed and Android's crash buffer
  was empty. The app was left open for sign-in.
- Authenticated Gym Mode, comment/timer interaction, real paired-watch transport,
  and physical haptics remain unverified. No physical USB device was tested.
- The established ignored signing configuration was used; no replacement key was
  generated and no secrets were printed. No installed-device certificate comparison
  was possible.
- The build warns that `flutter_timezone`, `health_bridge`, and `sentry_flutter`
  still apply Kotlin Gradle Plugin and will need future migration.
- Sentry remains a dependency without active runtime initialization/capture;
  runtime error reporting is not claimed.
- Only the focused suites above were run, not the entire repository test suite.
- Future local builds require a compatible Flutter/Dart SDK; the isolated SDK is
  temporary and the default stable SDK is still too old for upstream dependencies.