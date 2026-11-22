// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutProgress {

 int get dayId; int get iteration; String get currentPageKey; DateTime get workoutStart; DateTime get validUntil; Map<String, StoredPageProgress> get pages;/// To open the workout again right at app start, before the routine is
/// loaded. Null in progress stored by older versions.
 int? get routineId;/// The number of planned sets, so a finished workout is recognised
/// without the routine. Null in progress stored by older versions.
 int? get totalSets;/// The chosen progressive overload options, by slot entry ID
 Map<String, StoredOverloadChoice> get overload;/// Slot entries whose option was chosen, also "as before"
 List<int> get overloadDecided;/// Sets logged beyond the planned ones, by slot entry ID
 Map<String, List<StoredLog>> get extraLogs;/// Values entered for sets that aren't logged yet, by row key
 Map<String, StoredRowDraft> get drafts;
/// Create a copy of WorkoutProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutProgressCopyWith<WorkoutProgress> get copyWith => _$WorkoutProgressCopyWithImpl<WorkoutProgress>(this as WorkoutProgress, _$identity);

  /// Serializes this WorkoutProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WorkoutProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutProgress&&(identical(other.dayId, _this.dayId) || other.dayId == _this.dayId)&&(identical(other.iteration, _this.iteration) || other.iteration == _this.iteration)&&(identical(other.currentPageKey, _this.currentPageKey) || other.currentPageKey == _this.currentPageKey)&&(identical(other.workoutStart, _this.workoutStart) || other.workoutStart == _this.workoutStart)&&(identical(other.validUntil, _this.validUntil) || other.validUntil == _this.validUntil)&&const DeepCollectionEquality().equals(other.pages, _this.pages)&&(identical(other.routineId, _this.routineId) || other.routineId == _this.routineId)&&(identical(other.totalSets, _this.totalSets) || other.totalSets == _this.totalSets)&&const DeepCollectionEquality().equals(other.overload, _this.overload)&&const DeepCollectionEquality().equals(other.overloadDecided, _this.overloadDecided)&&const DeepCollectionEquality().equals(other.extraLogs, _this.extraLogs)&&const DeepCollectionEquality().equals(other.drafts, _this.drafts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WorkoutProgress;
  return Object.hash(runtimeType,_this.dayId,_this.iteration,_this.currentPageKey,_this.workoutStart,_this.validUntil,const DeepCollectionEquality().hash(_this.pages),_this.routineId,_this.totalSets,const DeepCollectionEquality().hash(_this.overload),const DeepCollectionEquality().hash(_this.overloadDecided),const DeepCollectionEquality().hash(_this.extraLogs),const DeepCollectionEquality().hash(_this.drafts));
}

@override
String toString() {
  final _this = this as WorkoutProgress;
  return 'WorkoutProgress(dayId: ${_this.dayId}, iteration: ${_this.iteration}, currentPageKey: ${_this.currentPageKey}, workoutStart: ${_this.workoutStart}, validUntil: ${_this.validUntil}, pages: ${_this.pages}, routineId: ${_this.routineId}, totalSets: ${_this.totalSets}, overload: ${_this.overload}, overloadDecided: ${_this.overloadDecided}, extraLogs: ${_this.extraLogs}, drafts: ${_this.drafts})';
}


}

/// @nodoc
abstract mixin class $WorkoutProgressCopyWith<$Res>  {
  factory $WorkoutProgressCopyWith(WorkoutProgress value, $Res Function(WorkoutProgress) _then) = _$WorkoutProgressCopyWithImpl;
@useResult
$Res call({
 int dayId, int iteration, String currentPageKey, DateTime workoutStart, DateTime validUntil, Map<String, StoredPageProgress> pages, int? routineId, int? totalSets, Map<String, StoredOverloadChoice> overload, List<int> overloadDecided, Map<String, List<StoredLog>> extraLogs, Map<String, StoredRowDraft> drafts
});




}
/// @nodoc
class _$WorkoutProgressCopyWithImpl<$Res>
    implements $WorkoutProgressCopyWith<$Res> {
  _$WorkoutProgressCopyWithImpl(this._self, this._then);

  final WorkoutProgress _self;
  final $Res Function(WorkoutProgress) _then;

/// Create a copy of WorkoutProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayId = null,Object? iteration = null,Object? currentPageKey = null,Object? workoutStart = null,Object? validUntil = null,Object? pages = null,Object? routineId = freezed,Object? totalSets = freezed,Object? overload = null,Object? overloadDecided = null,Object? extraLogs = null,Object? drafts = null,}) {
  return _then(WorkoutProgress(
dayId: null == dayId ? _self.dayId : dayId // ignore: cast_nullable_to_non_nullable
as int,iteration: null == iteration ? _self.iteration : iteration // ignore: cast_nullable_to_non_nullable
as int,currentPageKey: null == currentPageKey ? _self.currentPageKey : currentPageKey // ignore: cast_nullable_to_non_nullable
as String,workoutStart: null == workoutStart ? _self.workoutStart : workoutStart // ignore: cast_nullable_to_non_nullable
as DateTime,validUntil: null == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Map<String, StoredPageProgress>,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as int?,totalSets: freezed == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int?,overload: null == overload ? _self.overload : overload // ignore: cast_nullable_to_non_nullable
as Map<String, StoredOverloadChoice>,overloadDecided: null == overloadDecided ? _self.overloadDecided : overloadDecided // ignore: cast_nullable_to_non_nullable
as List<int>,extraLogs: null == extraLogs ? _self.extraLogs : extraLogs // ignore: cast_nullable_to_non_nullable
as Map<String, List<StoredLog>>,drafts: null == drafts ? _self.drafts : drafts // ignore: cast_nullable_to_non_nullable
as Map<String, StoredRowDraft>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutProgress].
extension WorkoutProgressPatterns on WorkoutProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutProgress value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutProgress():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutProgress value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dayId,  int iteration,  String currentPageKey,  DateTime workoutStart,  DateTime validUntil,  Map<String, StoredPageProgress> pages,  int? routineId,  int? totalSets,  Map<String, StoredOverloadChoice> overload,  List<int> overloadDecided,  Map<String, List<StoredLog>> extraLogs,  Map<String, StoredRowDraft> drafts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutProgress() when $default != null:
return $default(_that.dayId,_that.iteration,_that.currentPageKey,_that.workoutStart,_that.validUntil,_that.pages,_that.routineId,_that.totalSets,_that.overload,_that.overloadDecided,_that.extraLogs,_that.drafts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dayId,  int iteration,  String currentPageKey,  DateTime workoutStart,  DateTime validUntil,  Map<String, StoredPageProgress> pages,  int? routineId,  int? totalSets,  Map<String, StoredOverloadChoice> overload,  List<int> overloadDecided,  Map<String, List<StoredLog>> extraLogs,  Map<String, StoredRowDraft> drafts)  $default,) {final _that = this;
switch (_that) {
case _WorkoutProgress():
return $default(_that.dayId,_that.iteration,_that.currentPageKey,_that.workoutStart,_that.validUntil,_that.pages,_that.routineId,_that.totalSets,_that.overload,_that.overloadDecided,_that.extraLogs,_that.drafts);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dayId,  int iteration,  String currentPageKey,  DateTime workoutStart,  DateTime validUntil,  Map<String, StoredPageProgress> pages,  int? routineId,  int? totalSets,  Map<String, StoredOverloadChoice> overload,  List<int> overloadDecided,  Map<String, List<StoredLog>> extraLogs,  Map<String, StoredRowDraft> drafts)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutProgress() when $default != null:
return $default(_that.dayId,_that.iteration,_that.currentPageKey,_that.workoutStart,_that.validUntil,_that.pages,_that.routineId,_that.totalSets,_that.overload,_that.overloadDecided,_that.extraLogs,_that.drafts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutProgress implements WorkoutProgress {
  const _WorkoutProgress({required this.dayId, required this.iteration, required this.currentPageKey, required this.workoutStart, required this.validUntil,  Map<String, StoredPageProgress> pages = const {}, this.routineId, this.totalSets,  Map<String, StoredOverloadChoice> overload = const {},  List<int> overloadDecided = const [],  Map<String, List<StoredLog>> extraLogs = const {},  Map<String, StoredRowDraft> drafts = const {}}): _pages = pages,_overload = overload,_overloadDecided = overloadDecided,_extraLogs = extraLogs,_drafts = drafts;
  factory _WorkoutProgress.fromJson(Map<String, dynamic> json) => _$WorkoutProgressFromJson(json);

@override final  int dayId;
@override final  int iteration;
@override final  String currentPageKey;
@override final  DateTime workoutStart;
@override final  DateTime validUntil;
 final  Map<String, StoredPageProgress> _pages;
@override@JsonKey() Map<String, StoredPageProgress> get pages {
  if (_pages is EqualUnmodifiableMapView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pages);
}

/// To open the workout again right at app start, before the routine is
/// loaded. Null in progress stored by older versions.
@override final  int? routineId;
/// The number of planned sets, so a finished workout is recognised
/// without the routine. Null in progress stored by older versions.
@override final  int? totalSets;
/// The chosen progressive overload options, by slot entry ID
 final  Map<String, StoredOverloadChoice> _overload;
/// The chosen progressive overload options, by slot entry ID
@override@JsonKey() Map<String, StoredOverloadChoice> get overload {
  if (_overload is EqualUnmodifiableMapView) return _overload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_overload);
}

/// Slot entries whose option was chosen, also "as before"
 final  List<int> _overloadDecided;
/// Slot entries whose option was chosen, also "as before"
@override@JsonKey() List<int> get overloadDecided {
  if (_overloadDecided is EqualUnmodifiableListView) return _overloadDecided;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overloadDecided);
}

/// Sets logged beyond the planned ones, by slot entry ID
 final  Map<String, List<StoredLog>> _extraLogs;
/// Sets logged beyond the planned ones, by slot entry ID
@override@JsonKey() Map<String, List<StoredLog>> get extraLogs {
  if (_extraLogs is EqualUnmodifiableMapView) return _extraLogs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extraLogs);
}

/// Values entered for sets that aren't logged yet, by row key
 final  Map<String, StoredRowDraft> _drafts;
/// Values entered for sets that aren't logged yet, by row key
@override@JsonKey() Map<String, StoredRowDraft> get drafts {
  if (_drafts is EqualUnmodifiableMapView) return _drafts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_drafts);
}


/// Create a copy of WorkoutProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutProgressCopyWith<_WorkoutProgress> get copyWith => __$WorkoutProgressCopyWithImpl<_WorkoutProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutProgress&&(identical(other.dayId, dayId) || other.dayId == dayId)&&(identical(other.iteration, iteration) || other.iteration == iteration)&&(identical(other.currentPageKey, currentPageKey) || other.currentPageKey == currentPageKey)&&(identical(other.workoutStart, workoutStart) || other.workoutStart == workoutStart)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&const DeepCollectionEquality().equals(other.pages, _pages)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&const DeepCollectionEquality().equals(other.overload, _overload)&&const DeepCollectionEquality().equals(other.overloadDecided, _overloadDecided)&&const DeepCollectionEquality().equals(other.extraLogs, _extraLogs)&&const DeepCollectionEquality().equals(other.drafts, _drafts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,dayId,iteration,currentPageKey,workoutStart,validUntil,const DeepCollectionEquality().hash(_pages),routineId,totalSets,const DeepCollectionEquality().hash(_overload),const DeepCollectionEquality().hash(_overloadDecided),const DeepCollectionEquality().hash(_extraLogs),const DeepCollectionEquality().hash(_drafts));
}

@override
String toString() {
    return 'WorkoutProgress(dayId: $dayId, iteration: $iteration, currentPageKey: $currentPageKey, workoutStart: $workoutStart, validUntil: $validUntil, pages: $pages, routineId: $routineId, totalSets: $totalSets, overload: $overload, overloadDecided: $overloadDecided, extraLogs: $extraLogs, drafts: $drafts)';
}


}

/// @nodoc
abstract mixin class _$WorkoutProgressCopyWith<$Res> implements $WorkoutProgressCopyWith<$Res> {
  factory _$WorkoutProgressCopyWith(_WorkoutProgress value, $Res Function(_WorkoutProgress) _then) = __$WorkoutProgressCopyWithImpl;
@override @useResult
$Res call({
 int dayId, int iteration, String currentPageKey, DateTime workoutStart, DateTime validUntil, Map<String, StoredPageProgress> pages, int? routineId, int? totalSets, Map<String, StoredOverloadChoice> overload, List<int> overloadDecided, Map<String, List<StoredLog>> extraLogs, Map<String, StoredRowDraft> drafts
});




}
/// @nodoc
class __$WorkoutProgressCopyWithImpl<$Res>
    implements _$WorkoutProgressCopyWith<$Res> {
  __$WorkoutProgressCopyWithImpl(this._self, this._then);

  final _WorkoutProgress _self;
  final $Res Function(_WorkoutProgress) _then;

/// Create a copy of WorkoutProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayId = null,Object? iteration = null,Object? currentPageKey = null,Object? workoutStart = null,Object? validUntil = null,Object? pages = null,Object? routineId = freezed,Object? totalSets = freezed,Object? overload = null,Object? overloadDecided = null,Object? extraLogs = null,Object? drafts = null,}) {
  return _then(_WorkoutProgress(
dayId: null == dayId ? _self.dayId : dayId // ignore: cast_nullable_to_non_nullable
as int,iteration: null == iteration ? _self.iteration : iteration // ignore: cast_nullable_to_non_nullable
as int,currentPageKey: null == currentPageKey ? _self.currentPageKey : currentPageKey // ignore: cast_nullable_to_non_nullable
as String,workoutStart: null == workoutStart ? _self.workoutStart : workoutStart // ignore: cast_nullable_to_non_nullable
as DateTime,validUntil: null == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as Map<String, StoredPageProgress>,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as int?,totalSets: freezed == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int?,overload: null == overload ? _self._overload : overload // ignore: cast_nullable_to_non_nullable
as Map<String, StoredOverloadChoice>,overloadDecided: null == overloadDecided ? _self._overloadDecided : overloadDecided // ignore: cast_nullable_to_non_nullable
as List<int>,extraLogs: null == extraLogs ? _self._extraLogs : extraLogs // ignore: cast_nullable_to_non_nullable
as Map<String, List<StoredLog>>,drafts: null == drafts ? _self._drafts : drafts // ignore: cast_nullable_to_non_nullable
as Map<String, StoredRowDraft>,
  ));
}


}


/// @nodoc
mixin _$StoredPageProgress {

 bool get done; String? get logId; DateTime? get timerStartedAt;/// The values of the logged entry, to send it again if the server lost it
 StoredLog? get log;
/// Create a copy of StoredPageProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoredPageProgressCopyWith<StoredPageProgress> get copyWith => _$StoredPageProgressCopyWithImpl<StoredPageProgress>(this as StoredPageProgress, _$identity);

  /// Serializes this StoredPageProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StoredPageProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoredPageProgress&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.logId, _this.logId) || other.logId == _this.logId)&&(identical(other.timerStartedAt, _this.timerStartedAt) || other.timerStartedAt == _this.timerStartedAt)&&(identical(other.log, _this.log) || other.log == _this.log));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StoredPageProgress;
  return Object.hash(runtimeType,_this.done,_this.logId,_this.timerStartedAt,_this.log);
}

@override
String toString() {
  final _this = this as StoredPageProgress;
  return 'StoredPageProgress(done: ${_this.done}, logId: ${_this.logId}, timerStartedAt: ${_this.timerStartedAt}, log: ${_this.log})';
}


}

/// @nodoc
abstract mixin class $StoredPageProgressCopyWith<$Res>  {
  factory $StoredPageProgressCopyWith(StoredPageProgress value, $Res Function(StoredPageProgress) _then) = _$StoredPageProgressCopyWithImpl;
@useResult
$Res call({
 bool done, String? logId, DateTime? timerStartedAt, StoredLog? log
});


$StoredLogCopyWith<$Res>? get log;

}
/// @nodoc
class _$StoredPageProgressCopyWithImpl<$Res>
    implements $StoredPageProgressCopyWith<$Res> {
  _$StoredPageProgressCopyWithImpl(this._self, this._then);

  final StoredPageProgress _self;
  final $Res Function(StoredPageProgress) _then;

/// Create a copy of StoredPageProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? done = null,Object? logId = freezed,Object? timerStartedAt = freezed,Object? log = freezed,}) {
  return _then(StoredPageProgress(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,logId: freezed == logId ? _self.logId : logId // ignore: cast_nullable_to_non_nullable
as String?,timerStartedAt: freezed == timerStartedAt ? _self.timerStartedAt : timerStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,log: freezed == log ? _self.log : log // ignore: cast_nullable_to_non_nullable
as StoredLog?,
  ));
}
/// Create a copy of StoredPageProgress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoredLogCopyWith<$Res>? get log {
    if (_self.log == null) {
    return null;
  }

  return $StoredLogCopyWith<$Res>(_self.log!, (value) {
    return _then(_self.copyWith(log: value));
  });
}
}


/// Adds pattern-matching-related methods to [StoredPageProgress].
extension StoredPageProgressPatterns on StoredPageProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoredPageProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoredPageProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoredPageProgress value)  $default,){
final _that = this;
switch (_that) {
case _StoredPageProgress():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoredPageProgress value)?  $default,){
final _that = this;
switch (_that) {
case _StoredPageProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool done,  String? logId,  DateTime? timerStartedAt,  StoredLog? log)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoredPageProgress() when $default != null:
return $default(_that.done,_that.logId,_that.timerStartedAt,_that.log);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool done,  String? logId,  DateTime? timerStartedAt,  StoredLog? log)  $default,) {final _that = this;
switch (_that) {
case _StoredPageProgress():
return $default(_that.done,_that.logId,_that.timerStartedAt,_that.log);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool done,  String? logId,  DateTime? timerStartedAt,  StoredLog? log)?  $default,) {final _that = this;
switch (_that) {
case _StoredPageProgress() when $default != null:
return $default(_that.done,_that.logId,_that.timerStartedAt,_that.log);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoredPageProgress implements StoredPageProgress {
  const _StoredPageProgress({this.done = false, this.logId, this.timerStartedAt, this.log});
  factory _StoredPageProgress.fromJson(Map<String, dynamic> json) => _$StoredPageProgressFromJson(json);

@override@JsonKey() final  bool done;
@override final  String? logId;
@override final  DateTime? timerStartedAt;
/// The values of the logged entry, to send it again if the server lost it
@override final  StoredLog? log;

/// Create a copy of StoredPageProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoredPageProgressCopyWith<_StoredPageProgress> get copyWith => __$StoredPageProgressCopyWithImpl<_StoredPageProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoredPageProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoredPageProgress&&(identical(other.done, done) || other.done == done)&&(identical(other.logId, logId) || other.logId == logId)&&(identical(other.timerStartedAt, timerStartedAt) || other.timerStartedAt == timerStartedAt)&&(identical(other.log, log) || other.log == log));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,done,logId,timerStartedAt,log);
}

@override
String toString() {
    return 'StoredPageProgress(done: $done, logId: $logId, timerStartedAt: $timerStartedAt, log: $log)';
}


}

/// @nodoc
abstract mixin class _$StoredPageProgressCopyWith<$Res> implements $StoredPageProgressCopyWith<$Res> {
  factory _$StoredPageProgressCopyWith(_StoredPageProgress value, $Res Function(_StoredPageProgress) _then) = __$StoredPageProgressCopyWithImpl;
@override @useResult
$Res call({
 bool done, String? logId, DateTime? timerStartedAt, StoredLog? log
});


@override $StoredLogCopyWith<$Res>? get log;

}
/// @nodoc
class __$StoredPageProgressCopyWithImpl<$Res>
    implements _$StoredPageProgressCopyWith<$Res> {
  __$StoredPageProgressCopyWithImpl(this._self, this._then);

  final _StoredPageProgress _self;
  final $Res Function(_StoredPageProgress) _then;

/// Create a copy of StoredPageProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? done = null,Object? logId = freezed,Object? timerStartedAt = freezed,Object? log = freezed,}) {
  return _then(_StoredPageProgress(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,logId: freezed == logId ? _self.logId : logId // ignore: cast_nullable_to_non_nullable
as String?,timerStartedAt: freezed == timerStartedAt ? _self.timerStartedAt : timerStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,log: freezed == log ? _self.log : log // ignore: cast_nullable_to_non_nullable
as StoredLog?,
  ));
}

/// Create a copy of StoredPageProgress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoredLogCopyWith<$Res>? get log {
    if (_self.log == null) {
    return null;
  }

  return $StoredLogCopyWith<$Res>(_self.log!, (value) {
    return _then(_self.copyWith(log: value));
  });
}
}


/// @nodoc
mixin _$StoredLog {

 String get id; int get exerciseId; DateTime get date; int? get routineId; String? get sessionId; int? get iteration; int? get slotEntryId; num? get rir; num? get rirTarget; num? get repetitions; num? get repetitionsTarget; int? get repetitionsUnitId; num? get weight; num? get weightTarget; int? get weightUnitId;
/// Create a copy of StoredLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoredLogCopyWith<StoredLog> get copyWith => _$StoredLogCopyWithImpl<StoredLog>(this as StoredLog, _$identity);

  /// Serializes this StoredLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StoredLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoredLog&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.exerciseId, _this.exerciseId) || other.exerciseId == _this.exerciseId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.routineId, _this.routineId) || other.routineId == _this.routineId)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.iteration, _this.iteration) || other.iteration == _this.iteration)&&(identical(other.slotEntryId, _this.slotEntryId) || other.slotEntryId == _this.slotEntryId)&&(identical(other.rir, _this.rir) || other.rir == _this.rir)&&(identical(other.rirTarget, _this.rirTarget) || other.rirTarget == _this.rirTarget)&&(identical(other.repetitions, _this.repetitions) || other.repetitions == _this.repetitions)&&(identical(other.repetitionsTarget, _this.repetitionsTarget) || other.repetitionsTarget == _this.repetitionsTarget)&&(identical(other.repetitionsUnitId, _this.repetitionsUnitId) || other.repetitionsUnitId == _this.repetitionsUnitId)&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.weightTarget, _this.weightTarget) || other.weightTarget == _this.weightTarget)&&(identical(other.weightUnitId, _this.weightUnitId) || other.weightUnitId == _this.weightUnitId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StoredLog;
  return Object.hash(runtimeType,_this.id,_this.exerciseId,_this.date,_this.routineId,_this.sessionId,_this.iteration,_this.slotEntryId,_this.rir,_this.rirTarget,_this.repetitions,_this.repetitionsTarget,_this.repetitionsUnitId,_this.weight,_this.weightTarget,_this.weightUnitId);
}

@override
String toString() {
  final _this = this as StoredLog;
  return 'StoredLog(id: ${_this.id}, exerciseId: ${_this.exerciseId}, date: ${_this.date}, routineId: ${_this.routineId}, sessionId: ${_this.sessionId}, iteration: ${_this.iteration}, slotEntryId: ${_this.slotEntryId}, rir: ${_this.rir}, rirTarget: ${_this.rirTarget}, repetitions: ${_this.repetitions}, repetitionsTarget: ${_this.repetitionsTarget}, repetitionsUnitId: ${_this.repetitionsUnitId}, weight: ${_this.weight}, weightTarget: ${_this.weightTarget}, weightUnitId: ${_this.weightUnitId})';
}


}

/// @nodoc
abstract mixin class $StoredLogCopyWith<$Res>  {
  factory $StoredLogCopyWith(StoredLog value, $Res Function(StoredLog) _then) = _$StoredLogCopyWithImpl;
@useResult
$Res call({
 String id, int exerciseId, DateTime date, int? routineId, String? sessionId, int? iteration, int? slotEntryId, num? rir, num? rirTarget, num? repetitions, num? repetitionsTarget, int? repetitionsUnitId, num? weight, num? weightTarget, int? weightUnitId
});




}
/// @nodoc
class _$StoredLogCopyWithImpl<$Res>
    implements $StoredLogCopyWith<$Res> {
  _$StoredLogCopyWithImpl(this._self, this._then);

  final StoredLog _self;
  final $Res Function(StoredLog) _then;

/// Create a copy of StoredLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exerciseId = null,Object? date = null,Object? routineId = freezed,Object? sessionId = freezed,Object? iteration = freezed,Object? slotEntryId = freezed,Object? rir = freezed,Object? rirTarget = freezed,Object? repetitions = freezed,Object? repetitionsTarget = freezed,Object? repetitionsUnitId = freezed,Object? weight = freezed,Object? weightTarget = freezed,Object? weightUnitId = freezed,}) {
  return _then(StoredLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as int?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,iteration: freezed == iteration ? _self.iteration : iteration // ignore: cast_nullable_to_non_nullable
as int?,slotEntryId: freezed == slotEntryId ? _self.slotEntryId : slotEntryId // ignore: cast_nullable_to_non_nullable
as int?,rir: freezed == rir ? _self.rir : rir // ignore: cast_nullable_to_non_nullable
as num?,rirTarget: freezed == rirTarget ? _self.rirTarget : rirTarget // ignore: cast_nullable_to_non_nullable
as num?,repetitions: freezed == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as num?,repetitionsTarget: freezed == repetitionsTarget ? _self.repetitionsTarget : repetitionsTarget // ignore: cast_nullable_to_non_nullable
as num?,repetitionsUnitId: freezed == repetitionsUnitId ? _self.repetitionsUnitId : repetitionsUnitId // ignore: cast_nullable_to_non_nullable
as int?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as num?,weightTarget: freezed == weightTarget ? _self.weightTarget : weightTarget // ignore: cast_nullable_to_non_nullable
as num?,weightUnitId: freezed == weightUnitId ? _self.weightUnitId : weightUnitId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoredLog].
extension StoredLogPatterns on StoredLog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoredLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoredLog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoredLog value)  $default,){
final _that = this;
switch (_that) {
case _StoredLog():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoredLog value)?  $default,){
final _that = this;
switch (_that) {
case _StoredLog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int exerciseId,  DateTime date,  int? routineId,  String? sessionId,  int? iteration,  int? slotEntryId,  num? rir,  num? rirTarget,  num? repetitions,  num? repetitionsTarget,  int? repetitionsUnitId,  num? weight,  num? weightTarget,  int? weightUnitId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoredLog() when $default != null:
return $default(_that.id,_that.exerciseId,_that.date,_that.routineId,_that.sessionId,_that.iteration,_that.slotEntryId,_that.rir,_that.rirTarget,_that.repetitions,_that.repetitionsTarget,_that.repetitionsUnitId,_that.weight,_that.weightTarget,_that.weightUnitId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int exerciseId,  DateTime date,  int? routineId,  String? sessionId,  int? iteration,  int? slotEntryId,  num? rir,  num? rirTarget,  num? repetitions,  num? repetitionsTarget,  int? repetitionsUnitId,  num? weight,  num? weightTarget,  int? weightUnitId)  $default,) {final _that = this;
switch (_that) {
case _StoredLog():
return $default(_that.id,_that.exerciseId,_that.date,_that.routineId,_that.sessionId,_that.iteration,_that.slotEntryId,_that.rir,_that.rirTarget,_that.repetitions,_that.repetitionsTarget,_that.repetitionsUnitId,_that.weight,_that.weightTarget,_that.weightUnitId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int exerciseId,  DateTime date,  int? routineId,  String? sessionId,  int? iteration,  int? slotEntryId,  num? rir,  num? rirTarget,  num? repetitions,  num? repetitionsTarget,  int? repetitionsUnitId,  num? weight,  num? weightTarget,  int? weightUnitId)?  $default,) {final _that = this;
switch (_that) {
case _StoredLog() when $default != null:
return $default(_that.id,_that.exerciseId,_that.date,_that.routineId,_that.sessionId,_that.iteration,_that.slotEntryId,_that.rir,_that.rirTarget,_that.repetitions,_that.repetitionsTarget,_that.repetitionsUnitId,_that.weight,_that.weightTarget,_that.weightUnitId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoredLog extends StoredLog {
  const _StoredLog({required this.id, required this.exerciseId, required this.date, this.routineId, this.sessionId, this.iteration, this.slotEntryId, this.rir, this.rirTarget, this.repetitions, this.repetitionsTarget, this.repetitionsUnitId, this.weight, this.weightTarget, this.weightUnitId}): super._();
  factory _StoredLog.fromJson(Map<String, dynamic> json) => _$StoredLogFromJson(json);

@override final  String id;
@override final  int exerciseId;
@override final  DateTime date;
@override final  int? routineId;
@override final  String? sessionId;
@override final  int? iteration;
@override final  int? slotEntryId;
@override final  num? rir;
@override final  num? rirTarget;
@override final  num? repetitions;
@override final  num? repetitionsTarget;
@override final  int? repetitionsUnitId;
@override final  num? weight;
@override final  num? weightTarget;
@override final  int? weightUnitId;

/// Create a copy of StoredLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoredLogCopyWith<_StoredLog> get copyWith => __$StoredLogCopyWithImpl<_StoredLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoredLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoredLog&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.date, date) || other.date == date)&&(identical(other.routineId, routineId) || other.routineId == routineId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.iteration, iteration) || other.iteration == iteration)&&(identical(other.slotEntryId, slotEntryId) || other.slotEntryId == slotEntryId)&&(identical(other.rir, rir) || other.rir == rir)&&(identical(other.rirTarget, rirTarget) || other.rirTarget == rirTarget)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.repetitionsTarget, repetitionsTarget) || other.repetitionsTarget == repetitionsTarget)&&(identical(other.repetitionsUnitId, repetitionsUnitId) || other.repetitionsUnitId == repetitionsUnitId)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.weightTarget, weightTarget) || other.weightTarget == weightTarget)&&(identical(other.weightUnitId, weightUnitId) || other.weightUnitId == weightUnitId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,exerciseId,date,routineId,sessionId,iteration,slotEntryId,rir,rirTarget,repetitions,repetitionsTarget,repetitionsUnitId,weight,weightTarget,weightUnitId);
}

@override
String toString() {
    return 'StoredLog(id: $id, exerciseId: $exerciseId, date: $date, routineId: $routineId, sessionId: $sessionId, iteration: $iteration, slotEntryId: $slotEntryId, rir: $rir, rirTarget: $rirTarget, repetitions: $repetitions, repetitionsTarget: $repetitionsTarget, repetitionsUnitId: $repetitionsUnitId, weight: $weight, weightTarget: $weightTarget, weightUnitId: $weightUnitId)';
}


}

/// @nodoc
abstract mixin class _$StoredLogCopyWith<$Res> implements $StoredLogCopyWith<$Res> {
  factory _$StoredLogCopyWith(_StoredLog value, $Res Function(_StoredLog) _then) = __$StoredLogCopyWithImpl;
@override @useResult
$Res call({
 String id, int exerciseId, DateTime date, int? routineId, String? sessionId, int? iteration, int? slotEntryId, num? rir, num? rirTarget, num? repetitions, num? repetitionsTarget, int? repetitionsUnitId, num? weight, num? weightTarget, int? weightUnitId
});




}
/// @nodoc
class __$StoredLogCopyWithImpl<$Res>
    implements _$StoredLogCopyWith<$Res> {
  __$StoredLogCopyWithImpl(this._self, this._then);

  final _StoredLog _self;
  final $Res Function(_StoredLog) _then;

/// Create a copy of StoredLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exerciseId = null,Object? date = null,Object? routineId = freezed,Object? sessionId = freezed,Object? iteration = freezed,Object? slotEntryId = freezed,Object? rir = freezed,Object? rirTarget = freezed,Object? repetitions = freezed,Object? repetitionsTarget = freezed,Object? repetitionsUnitId = freezed,Object? weight = freezed,Object? weightTarget = freezed,Object? weightUnitId = freezed,}) {
  return _then(_StoredLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,routineId: freezed == routineId ? _self.routineId : routineId // ignore: cast_nullable_to_non_nullable
as int?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,iteration: freezed == iteration ? _self.iteration : iteration // ignore: cast_nullable_to_non_nullable
as int?,slotEntryId: freezed == slotEntryId ? _self.slotEntryId : slotEntryId // ignore: cast_nullable_to_non_nullable
as int?,rir: freezed == rir ? _self.rir : rir // ignore: cast_nullable_to_non_nullable
as num?,rirTarget: freezed == rirTarget ? _self.rirTarget : rirTarget // ignore: cast_nullable_to_non_nullable
as num?,repetitions: freezed == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as num?,repetitionsTarget: freezed == repetitionsTarget ? _self.repetitionsTarget : repetitionsTarget // ignore: cast_nullable_to_non_nullable
as num?,repetitionsUnitId: freezed == repetitionsUnitId ? _self.repetitionsUnitId : repetitionsUnitId // ignore: cast_nullable_to_non_nullable
as int?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as num?,weightTarget: freezed == weightTarget ? _self.weightTarget : weightTarget // ignore: cast_nullable_to_non_nullable
as num?,weightUnitId: freezed == weightUnitId ? _self.weightUnitId : weightUnitId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$StoredOverloadChoice {

 String get type; List<StoredRowDraft> get sets; int? get requiredRepetitions;
/// Create a copy of StoredOverloadChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoredOverloadChoiceCopyWith<StoredOverloadChoice> get copyWith => _$StoredOverloadChoiceCopyWithImpl<StoredOverloadChoice>(this as StoredOverloadChoice, _$identity);

  /// Serializes this StoredOverloadChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StoredOverloadChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoredOverloadChoice&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.sets, _this.sets)&&(identical(other.requiredRepetitions, _this.requiredRepetitions) || other.requiredRepetitions == _this.requiredRepetitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StoredOverloadChoice;
  return Object.hash(runtimeType,_this.type,const DeepCollectionEquality().hash(_this.sets),_this.requiredRepetitions);
}

@override
String toString() {
  final _this = this as StoredOverloadChoice;
  return 'StoredOverloadChoice(type: ${_this.type}, sets: ${_this.sets}, requiredRepetitions: ${_this.requiredRepetitions})';
}


}

/// @nodoc
abstract mixin class $StoredOverloadChoiceCopyWith<$Res>  {
  factory $StoredOverloadChoiceCopyWith(StoredOverloadChoice value, $Res Function(StoredOverloadChoice) _then) = _$StoredOverloadChoiceCopyWithImpl;
@useResult
$Res call({
 String type, List<StoredRowDraft> sets, int? requiredRepetitions
});




}
/// @nodoc
class _$StoredOverloadChoiceCopyWithImpl<$Res>
    implements $StoredOverloadChoiceCopyWith<$Res> {
  _$StoredOverloadChoiceCopyWithImpl(this._self, this._then);

  final StoredOverloadChoice _self;
  final $Res Function(StoredOverloadChoice) _then;

/// Create a copy of StoredOverloadChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? sets = null,Object? requiredRepetitions = freezed,}) {
  return _then(StoredOverloadChoice(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<StoredRowDraft>,requiredRepetitions: freezed == requiredRepetitions ? _self.requiredRepetitions : requiredRepetitions // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoredOverloadChoice].
extension StoredOverloadChoicePatterns on StoredOverloadChoice {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoredOverloadChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoredOverloadChoice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoredOverloadChoice value)  $default,){
final _that = this;
switch (_that) {
case _StoredOverloadChoice():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoredOverloadChoice value)?  $default,){
final _that = this;
switch (_that) {
case _StoredOverloadChoice() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  List<StoredRowDraft> sets,  int? requiredRepetitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoredOverloadChoice() when $default != null:
return $default(_that.type,_that.sets,_that.requiredRepetitions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  List<StoredRowDraft> sets,  int? requiredRepetitions)  $default,) {final _that = this;
switch (_that) {
case _StoredOverloadChoice():
return $default(_that.type,_that.sets,_that.requiredRepetitions);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  List<StoredRowDraft> sets,  int? requiredRepetitions)?  $default,) {final _that = this;
switch (_that) {
case _StoredOverloadChoice() when $default != null:
return $default(_that.type,_that.sets,_that.requiredRepetitions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoredOverloadChoice extends StoredOverloadChoice {
  const _StoredOverloadChoice({required this.type,  List<StoredRowDraft> sets = const [], this.requiredRepetitions}): _sets = sets,super._();
  factory _StoredOverloadChoice.fromJson(Map<String, dynamic> json) => _$StoredOverloadChoiceFromJson(json);

@override final  String type;
 final  List<StoredRowDraft> _sets;
@override@JsonKey() List<StoredRowDraft> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

@override final  int? requiredRepetitions;

/// Create a copy of StoredOverloadChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoredOverloadChoiceCopyWith<_StoredOverloadChoice> get copyWith => __$StoredOverloadChoiceCopyWithImpl<_StoredOverloadChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoredOverloadChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoredOverloadChoice&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.sets, _sets)&&(identical(other.requiredRepetitions, requiredRepetitions) || other.requiredRepetitions == requiredRepetitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_sets),requiredRepetitions);
}

@override
String toString() {
    return 'StoredOverloadChoice(type: $type, sets: $sets, requiredRepetitions: $requiredRepetitions)';
}


}

/// @nodoc
abstract mixin class _$StoredOverloadChoiceCopyWith<$Res> implements $StoredOverloadChoiceCopyWith<$Res> {
  factory _$StoredOverloadChoiceCopyWith(_StoredOverloadChoice value, $Res Function(_StoredOverloadChoice) _then) = __$StoredOverloadChoiceCopyWithImpl;
@override @useResult
$Res call({
 String type, List<StoredRowDraft> sets, int? requiredRepetitions
});




}
/// @nodoc
class __$StoredOverloadChoiceCopyWithImpl<$Res>
    implements _$StoredOverloadChoiceCopyWith<$Res> {
  __$StoredOverloadChoiceCopyWithImpl(this._self, this._then);

  final _StoredOverloadChoice _self;
  final $Res Function(_StoredOverloadChoice) _then;

/// Create a copy of StoredOverloadChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? sets = null,Object? requiredRepetitions = freezed,}) {
  return _then(_StoredOverloadChoice(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<StoredRowDraft>,requiredRepetitions: freezed == requiredRepetitions ? _self.requiredRepetitions : requiredRepetitions // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$StoredRowDraft {

 num? get weight; num? get repetitions;
/// Create a copy of StoredRowDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoredRowDraftCopyWith<StoredRowDraft> get copyWith => _$StoredRowDraftCopyWithImpl<StoredRowDraft>(this as StoredRowDraft, _$identity);

  /// Serializes this StoredRowDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StoredRowDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoredRowDraft&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.repetitions, _this.repetitions) || other.repetitions == _this.repetitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StoredRowDraft;
  return Object.hash(runtimeType,_this.weight,_this.repetitions);
}

@override
String toString() {
  final _this = this as StoredRowDraft;
  return 'StoredRowDraft(weight: ${_this.weight}, repetitions: ${_this.repetitions})';
}


}

/// @nodoc
abstract mixin class $StoredRowDraftCopyWith<$Res>  {
  factory $StoredRowDraftCopyWith(StoredRowDraft value, $Res Function(StoredRowDraft) _then) = _$StoredRowDraftCopyWithImpl;
@useResult
$Res call({
 num? weight, num? repetitions
});




}
/// @nodoc
class _$StoredRowDraftCopyWithImpl<$Res>
    implements $StoredRowDraftCopyWith<$Res> {
  _$StoredRowDraftCopyWithImpl(this._self, this._then);

  final StoredRowDraft _self;
  final $Res Function(StoredRowDraft) _then;

/// Create a copy of StoredRowDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weight = freezed,Object? repetitions = freezed,}) {
  return _then(StoredRowDraft(
weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as num?,repetitions: freezed == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoredRowDraft].
extension StoredRowDraftPatterns on StoredRowDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoredRowDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoredRowDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoredRowDraft value)  $default,){
final _that = this;
switch (_that) {
case _StoredRowDraft():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoredRowDraft value)?  $default,){
final _that = this;
switch (_that) {
case _StoredRowDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num? weight,  num? repetitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoredRowDraft() when $default != null:
return $default(_that.weight,_that.repetitions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num? weight,  num? repetitions)  $default,) {final _that = this;
switch (_that) {
case _StoredRowDraft():
return $default(_that.weight,_that.repetitions);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num? weight,  num? repetitions)?  $default,) {final _that = this;
switch (_that) {
case _StoredRowDraft() when $default != null:
return $default(_that.weight,_that.repetitions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoredRowDraft implements StoredRowDraft {
  const _StoredRowDraft({this.weight, this.repetitions});
  factory _StoredRowDraft.fromJson(Map<String, dynamic> json) => _$StoredRowDraftFromJson(json);

@override final  num? weight;
@override final  num? repetitions;

/// Create a copy of StoredRowDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoredRowDraftCopyWith<_StoredRowDraft> get copyWith => __$StoredRowDraftCopyWithImpl<_StoredRowDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoredRowDraftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoredRowDraft&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,weight,repetitions);
}

@override
String toString() {
    return 'StoredRowDraft(weight: $weight, repetitions: $repetitions)';
}


}

/// @nodoc
abstract mixin class _$StoredRowDraftCopyWith<$Res> implements $StoredRowDraftCopyWith<$Res> {
  factory _$StoredRowDraftCopyWith(_StoredRowDraft value, $Res Function(_StoredRowDraft) _then) = __$StoredRowDraftCopyWithImpl;
@override @useResult
$Res call({
 num? weight, num? repetitions
});




}
/// @nodoc
class __$StoredRowDraftCopyWithImpl<$Res>
    implements _$StoredRowDraftCopyWith<$Res> {
  __$StoredRowDraftCopyWithImpl(this._self, this._then);

  final _StoredRowDraft _self;
  final $Res Function(_StoredRowDraft) _then;

/// Create a copy of StoredRowDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weight = freezed,Object? repetitions = freezed,}) {
  return _then(_StoredRowDraft(
weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as num?,repetitions: freezed == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}

// dart format on
