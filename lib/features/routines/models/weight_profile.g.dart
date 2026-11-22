// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeightProfile _$WeightProfileFromJson(Map<String, dynamic> json) => _WeightProfile(
  id: json['id'] as String,
  name: json['name'] as String,
  kind: $enumDecode(_$WeightProfileKindEnumMap, json['kind']),
  base: json['base'] as num? ?? 0,
  step: json['step'] as num?,
  max: json['max'] as num?,
  plates: (json['plates'] as List<dynamic>?)?.map((e) => e as num).toList() ?? const [],
  fixed: (json['fixed'] as List<dynamic>?)?.map((e) => e as num).toList() ?? const [],
  bonus: (json['bonus'] as List<dynamic>?)?.map((e) => e as num).toList() ?? const [],
);

Map<String, dynamic> _$WeightProfileToJson(_WeightProfile instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'kind': _$WeightProfileKindEnumMap[instance.kind]!,
  'base': instance.base,
  'step': instance.step,
  'max': instance.max,
  'plates': instance.plates,
  'fixed': instance.fixed,
  'bonus': instance.bonus,
};

const _$WeightProfileKindEnumMap = {
  WeightProfileKind.plates: 'plates',
  WeightProfileKind.fixed: 'fixed',
  WeightProfileKind.linear: 'linear',
};

_WeightProfilesState _$WeightProfilesStateFromJson(Map<String, dynamic> json) =>
    _WeightProfilesState(
      profiles:
          (json['profiles'] as List<dynamic>?)
              ?.map((e) => WeightProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      assignments:
          (json['assignments'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$WeightProfilesStateToJson(
  _WeightProfilesState instance,
) => <String, dynamic>{
  'profiles': instance.profiles,
  'assignments': instance.assignments.map((k, e) => MapEntry(k.toString(), e)),
};
