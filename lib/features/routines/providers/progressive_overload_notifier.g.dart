// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progressive_overload_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The progressive overload options for [exerciseId], based on its last
/// session before [before] (the start of the running workout, so its own sets
/// don't count), its first [plannedSets] sets (all when null) and the
/// repetition range [minReps]..[maxReps].
///
/// The known weights are those of the weight profile assigned to the exercise
/// and those logged before in the weight unit of the last set.

@ProviderFor(overloadSuggestions)
final overloadSuggestionsProvider = OverloadSuggestionsFamily._();

/// The progressive overload options for [exerciseId], based on its last
/// session before [before] (the start of the running workout, so its own sets
/// don't count), its first [plannedSets] sets (all when null) and the
/// repetition range [minReps]..[maxReps].
///
/// The known weights are those of the weight profile assigned to the exercise
/// and those logged before in the weight unit of the last set.

final class OverloadSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OverloadSuggestions>,
          OverloadSuggestions,
          FutureOr<OverloadSuggestions>
        >
    with $FutureModifier<OverloadSuggestions>, $FutureProvider<OverloadSuggestions> {
  /// The progressive overload options for [exerciseId], based on its last
  /// session before [before] (the start of the running workout, so its own sets
  /// don't count), its first [plannedSets] sets (all when null) and the
  /// repetition range [minReps]..[maxReps].
  ///
  /// The known weights are those of the weight profile assigned to the exercise
  /// and those logged before in the weight unit of the last set.
  OverloadSuggestionsProvider._({
    required OverloadSuggestionsFamily super.from,
    required ({
      int exerciseId,
      DateTime before,
      num? minReps,
      num? maxReps,
      int? plannedSets,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'overloadSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$overloadSuggestionsHash();

  @override
  String toString() {
    return r'overloadSuggestionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<OverloadSuggestions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OverloadSuggestions> create(Ref ref) {
    final argument =
        this.argument
            as ({
              int exerciseId,
              DateTime before,
              num? minReps,
              num? maxReps,
              int? plannedSets,
            });
    return overloadSuggestions(
      ref,
      exerciseId: argument.exerciseId,
      before: argument.before,
      minReps: argument.minReps,
      maxReps: argument.maxReps,
      plannedSets: argument.plannedSets,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OverloadSuggestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$overloadSuggestionsHash() => r'3387539ee211684819ff35792b4c5d27a4e9f257';

/// The progressive overload options for [exerciseId], based on its last
/// session before [before] (the start of the running workout, so its own sets
/// don't count), its first [plannedSets] sets (all when null) and the
/// repetition range [minReps]..[maxReps].
///
/// The known weights are those of the weight profile assigned to the exercise
/// and those logged before in the weight unit of the last set.

final class OverloadSuggestionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<OverloadSuggestions>,
          ({
            int exerciseId,
            DateTime before,
            num? minReps,
            num? maxReps,
            int? plannedSets,
          })
        > {
  OverloadSuggestionsFamily._()
    : super(
        retry: null,
        name: r'overloadSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The progressive overload options for [exerciseId], based on its last
  /// session before [before] (the start of the running workout, so its own sets
  /// don't count), its first [plannedSets] sets (all when null) and the
  /// repetition range [minReps]..[maxReps].
  ///
  /// The known weights are those of the weight profile assigned to the exercise
  /// and those logged before in the weight unit of the last set.

  OverloadSuggestionsProvider call({
    required int exerciseId,
    required DateTime before,
    num? minReps,
    num? maxReps,
    int? plannedSets,
  }) => OverloadSuggestionsProvider._(
    argument: (
      exerciseId: exerciseId,
      before: before,
      minReps: minReps,
      maxReps: maxReps,
      plannedSets: plannedSets,
    ),
    from: this,
  );

  @override
  String toString() => r'overloadSuggestionsProvider';
}
