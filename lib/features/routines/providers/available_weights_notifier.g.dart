// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_weights_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weights the equipment of an exercise offers, by exercise ID, e.g. the
/// steps of a cable tower. Used for the progressive overload suggestions.
///
/// Stored on this device only, sorted and without duplicates.

@ProviderFor(AvailableWeightsNotifier)
final availableWeightsProvider = AvailableWeightsNotifierProvider._();

/// The weights the equipment of an exercise offers, by exercise ID, e.g. the
/// steps of a cable tower. Used for the progressive overload suggestions.
///
/// Stored on this device only, sorted and without duplicates.
final class AvailableWeightsNotifierProvider
    extends $AsyncNotifierProvider<AvailableWeightsNotifier, Map<int, List<num>>> {
  /// The weights the equipment of an exercise offers, by exercise ID, e.g. the
  /// steps of a cable tower. Used for the progressive overload suggestions.
  ///
  /// Stored on this device only, sorted and without duplicates.
  AvailableWeightsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableWeightsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableWeightsNotifierHash();

  @$internal
  @override
  AvailableWeightsNotifier create() => AvailableWeightsNotifier();
}

String _$availableWeightsNotifierHash() => r'e16902d9da9404b3d848267263b4d3575ae98520';

/// The weights the equipment of an exercise offers, by exercise ID, e.g. the
/// steps of a cable tower. Used for the progressive overload suggestions.
///
/// Stored on this device only, sorted and without duplicates.

abstract class _$AvailableWeightsNotifier extends $AsyncNotifier<Map<int, List<num>>> {
  FutureOr<Map<int, List<num>>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Map<int, List<num>>>, Map<int, List<num>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<int, List<num>>>, Map<int, List<num>>>,
              AsyncValue<Map<int, List<num>>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
