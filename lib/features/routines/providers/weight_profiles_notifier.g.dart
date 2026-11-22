// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_profiles_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [WeightProfile]s of the user's equipment and which exercise uses
/// which. Used for the progressive overload suggestions.
///
/// Stored on this device only. Without stored profiles yet, the weights of
/// the older per-exercise list ([PREFS_AVAILABLE_WEIGHTS]) become one fixed
/// profile per exercise, that key itself stays as it is.

@ProviderFor(WeightProfilesNotifier)
final weightProfilesProvider = WeightProfilesNotifierProvider._();

/// The [WeightProfile]s of the user's equipment and which exercise uses
/// which. Used for the progressive overload suggestions.
///
/// Stored on this device only. Without stored profiles yet, the weights of
/// the older per-exercise list ([PREFS_AVAILABLE_WEIGHTS]) become one fixed
/// profile per exercise, that key itself stays as it is.
final class WeightProfilesNotifierProvider
    extends $AsyncNotifierProvider<WeightProfilesNotifier, WeightProfilesState> {
  /// The [WeightProfile]s of the user's equipment and which exercise uses
  /// which. Used for the progressive overload suggestions.
  ///
  /// Stored on this device only. Without stored profiles yet, the weights of
  /// the older per-exercise list ([PREFS_AVAILABLE_WEIGHTS]) become one fixed
  /// profile per exercise, that key itself stays as it is.
  WeightProfilesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightProfilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightProfilesNotifierHash();

  @$internal
  @override
  WeightProfilesNotifier create() => WeightProfilesNotifier();
}

String _$weightProfilesNotifierHash() => r'a646c001619ce0e6869bf6b4ea04f74910bb7388';

/// The [WeightProfile]s of the user's equipment and which exercise uses
/// which. Used for the progressive overload suggestions.
///
/// Stored on this device only. Without stored profiles yet, the weights of
/// the older per-exercise list ([PREFS_AVAILABLE_WEIGHTS]) become one fixed
/// profile per exercise, that key itself stays as it is.

abstract class _$WeightProfilesNotifier extends $AsyncNotifier<WeightProfilesState> {
  FutureOr<WeightProfilesState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WeightProfilesState>, WeightProfilesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WeightProfilesState>, WeightProfilesState>,
              AsyncValue<WeightProfilesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
