// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle_overload_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The overload per muscle group for the day of [entries] of routine [routineId] in
/// the workout started at [before], null unless it is the first session of
/// that day since [routineStart] (a programme switch, or the same routine
/// started again) and something was trained before it.
///
/// [entries] are the day's planned exercises. Today's muscle groups are
/// compared to the session before the switch that overlaps them the most.

@ProviderFor(muscleOverloadPlan)
final muscleOverloadPlanProvider = MuscleOverloadPlanFamily._();

/// The overload per muscle group for the day of [entries] of routine [routineId] in
/// the workout started at [before], null unless it is the first session of
/// that day since [routineStart] (a programme switch, or the same routine
/// started again) and something was trained before it.
///
/// [entries] are the day's planned exercises. Today's muscle groups are
/// compared to the session before the switch that overlaps them the most.

final class MuscleOverloadPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<MuscleOverloadPlan?>,
          MuscleOverloadPlan?,
          FutureOr<MuscleOverloadPlan?>
        >
    with $FutureModifier<MuscleOverloadPlan?>, $FutureProvider<MuscleOverloadPlan?> {
  /// The overload per muscle group for the day of [entries] of routine [routineId] in
  /// the workout started at [before], null unless it is the first session of
  /// that day since [routineStart] (a programme switch, or the same routine
  /// started again) and something was trained before it.
  ///
  /// [entries] are the day's planned exercises. Today's muscle groups are
  /// compared to the session before the switch that overlaps them the most.
  MuscleOverloadPlanProvider._({
    required MuscleOverloadPlanFamily super.from,
    required ({
      int routineId,
      DateTime routineStart,
      DateTime before,
      PlannedEntries entries,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'muscleOverloadPlanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$muscleOverloadPlanHash();

  @override
  String toString() {
    return r'muscleOverloadPlanProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MuscleOverloadPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MuscleOverloadPlan?> create(Ref ref) {
    final argument =
        this.argument
            as ({
              int routineId,
              DateTime routineStart,
              DateTime before,
              PlannedEntries entries,
            });
    return muscleOverloadPlan(
      ref,
      routineId: argument.routineId,
      routineStart: argument.routineStart,
      before: argument.before,
      entries: argument.entries,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MuscleOverloadPlanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$muscleOverloadPlanHash() => r'f43c9e151ff4e406d337927be71161e9b9196f0b';

/// The overload per muscle group for the day of [entries] of routine [routineId] in
/// the workout started at [before], null unless it is the first session of
/// that day since [routineStart] (a programme switch, or the same routine
/// started again) and something was trained before it.
///
/// [entries] are the day's planned exercises. Today's muscle groups are
/// compared to the session before the switch that overlaps them the most.

final class MuscleOverloadPlanFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<MuscleOverloadPlan?>,
          ({
            int routineId,
            DateTime routineStart,
            DateTime before,
            PlannedEntries entries,
          })
        > {
  MuscleOverloadPlanFamily._()
    : super(
        retry: null,
        name: r'muscleOverloadPlanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The overload per muscle group for the day of [entries] of routine [routineId] in
  /// the workout started at [before], null unless it is the first session of
  /// that day since [routineStart] (a programme switch, or the same routine
  /// started again) and something was trained before it.
  ///
  /// [entries] are the day's planned exercises. Today's muscle groups are
  /// compared to the session before the switch that overlaps them the most.

  MuscleOverloadPlanProvider call({
    required int routineId,
    required DateTime routineStart,
    required DateTime before,
    required PlannedEntries entries,
  }) => MuscleOverloadPlanProvider._(
    argument: (
      routineId: routineId,
      routineStart: routineStart,
      before: before,
      entries: entries,
    ),
    from: this,
  );

  @override
  String toString() => r'muscleOverloadPlanProvider';
}
