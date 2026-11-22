// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutProgress _$WorkoutProgressFromJson(Map<String, dynamic> json) => _WorkoutProgress(
  dayId: (json['dayId'] as num).toInt(),
  iteration: (json['iteration'] as num).toInt(),
  currentPageKey: json['currentPageKey'] as String,
  workoutStart: DateTime.parse(json['workoutStart'] as String),
  validUntil: DateTime.parse(json['validUntil'] as String),
  pages:
      (json['pages'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          StoredPageProgress.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const {},
  routineId: (json['routineId'] as num?)?.toInt(),
  totalSets: (json['totalSets'] as num?)?.toInt(),
  overload:
      (json['overload'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          StoredOverloadChoice.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const {},
  overloadDecided:
      (json['overloadDecided'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
      const [],
  extraLogs:
      (json['extraLogs'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>).map((e) => StoredLog.fromJson(e as Map<String, dynamic>)).toList(),
        ),
      ) ??
      const {},
  drafts:
      (json['drafts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, StoredRowDraft.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
);

Map<String, dynamic> _$WorkoutProgressToJson(_WorkoutProgress instance) => <String, dynamic>{
  'dayId': instance.dayId,
  'iteration': instance.iteration,
  'currentPageKey': instance.currentPageKey,
  'workoutStart': instance.workoutStart.toIso8601String(),
  'validUntil': instance.validUntil.toIso8601String(),
  'pages': instance.pages,
  'routineId': instance.routineId,
  'totalSets': instance.totalSets,
  'overload': instance.overload,
  'overloadDecided': instance.overloadDecided,
  'extraLogs': instance.extraLogs,
  'drafts': instance.drafts,
};

_StoredPageProgress _$StoredPageProgressFromJson(Map<String, dynamic> json) => _StoredPageProgress(
  done: json['done'] as bool? ?? false,
  logId: json['logId'] as String?,
  timerStartedAt: json['timerStartedAt'] == null
      ? null
      : DateTime.parse(json['timerStartedAt'] as String),
  log: json['log'] == null ? null : StoredLog.fromJson(json['log'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StoredPageProgressToJson(_StoredPageProgress instance) => <String, dynamic>{
  'done': instance.done,
  'logId': instance.logId,
  'timerStartedAt': instance.timerStartedAt?.toIso8601String(),
  'log': instance.log,
};

_StoredLog _$StoredLogFromJson(Map<String, dynamic> json) => _StoredLog(
  id: json['id'] as String,
  exerciseId: (json['exerciseId'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  routineId: (json['routineId'] as num?)?.toInt(),
  sessionId: json['sessionId'] as String?,
  iteration: (json['iteration'] as num?)?.toInt(),
  slotEntryId: (json['slotEntryId'] as num?)?.toInt(),
  rir: json['rir'] as num?,
  rirTarget: json['rirTarget'] as num?,
  repetitions: json['repetitions'] as num?,
  repetitionsTarget: json['repetitionsTarget'] as num?,
  repetitionsUnitId: (json['repetitionsUnitId'] as num?)?.toInt(),
  weight: json['weight'] as num?,
  weightTarget: json['weightTarget'] as num?,
  weightUnitId: (json['weightUnitId'] as num?)?.toInt(),
);

Map<String, dynamic> _$StoredLogToJson(_StoredLog instance) => <String, dynamic>{
  'id': instance.id,
  'exerciseId': instance.exerciseId,
  'date': instance.date.toIso8601String(),
  'routineId': instance.routineId,
  'sessionId': instance.sessionId,
  'iteration': instance.iteration,
  'slotEntryId': instance.slotEntryId,
  'rir': instance.rir,
  'rirTarget': instance.rirTarget,
  'repetitions': instance.repetitions,
  'repetitionsTarget': instance.repetitionsTarget,
  'repetitionsUnitId': instance.repetitionsUnitId,
  'weight': instance.weight,
  'weightTarget': instance.weightTarget,
  'weightUnitId': instance.weightUnitId,
};

_StoredOverloadChoice _$StoredOverloadChoiceFromJson(
  Map<String, dynamic> json,
) => _StoredOverloadChoice(
  type: json['type'] as String,
  sets:
      (json['sets'] as List<dynamic>?)
          ?.map((e) => StoredRowDraft.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  requiredRepetitions: (json['requiredRepetitions'] as num?)?.toInt(),
);

Map<String, dynamic> _$StoredOverloadChoiceToJson(
  _StoredOverloadChoice instance,
) => <String, dynamic>{
  'type': instance.type,
  'sets': instance.sets,
  'requiredRepetitions': instance.requiredRepetitions,
};

_StoredRowDraft _$StoredRowDraftFromJson(Map<String, dynamic> json) => _StoredRowDraft(
  weight: json['weight'] as num?,
  repetitions: json['repetitions'] as num?,
);

Map<String, dynamic> _$StoredRowDraftToJson(_StoredRowDraft instance) => <String, dynamic>{
  'weight': instance.weight,
  'repetitions': instance.repetitions,
};
