// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overload_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OverloadSet {


/// Create a copy of OverloadSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverloadSetCopyWith<OverloadSet> get copyWith => _$OverloadSetCopyWithImpl<OverloadSet>(this as OverloadSet, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OverloadSet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverloadSet&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.repetitions, _this.repetitions) || other.repetitions == _this.repetitions));
}


@override
int get hashCode {
  final _this = this as OverloadSet;
  return Object.hash(runtimeType,_this.weight,_this.repetitions);
}

@override
String toString() {
  final _this = this as OverloadSet;
  return 'OverloadSet(weight: ${_this.weight}, repetitions: ${_this.repetitions})';
}


}

/// @nodoc
abstract mixin class $OverloadSetCopyWith<$Res>  {
  factory $OverloadSetCopyWith(OverloadSet value, $Res Function(OverloadSet) _then) = _$OverloadSetCopyWithImpl;
@useResult
$Res call({
 num? weight, num repetitions
});




}
/// @nodoc
class _$OverloadSetCopyWithImpl<$Res>
    implements $OverloadSetCopyWith<$Res> {
  _$OverloadSetCopyWithImpl(this._self, this._then);

  final OverloadSet _self;
  final $Res Function(OverloadSet) _then;

/// Create a copy of OverloadSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weight = freezed,Object? repetitions = null,}) {
  return _then(OverloadSet(
weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as num?,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [OverloadSet].
extension OverloadSetPatterns on OverloadSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

/// @nodoc
mixin _$OverloadOption {


/// Create a copy of OverloadOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverloadOptionCopyWith<OverloadOption> get copyWith => _$OverloadOptionCopyWithImpl<OverloadOption>(this as OverloadOption, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OverloadOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverloadOption&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.sets, _this.sets)&&(identical(other.requiredRepetitions, _this.requiredRepetitions) || other.requiredRepetitions == _this.requiredRepetitions));
}


@override
int get hashCode {
  final _this = this as OverloadOption;
  return Object.hash(runtimeType,_this.type,const DeepCollectionEquality().hash(_this.sets),_this.requiredRepetitions);
}

@override
String toString() {
  final _this = this as OverloadOption;
  return 'OverloadOption(type: ${_this.type}, sets: ${_this.sets}, requiredRepetitions: ${_this.requiredRepetitions})';
}


}

/// @nodoc
abstract mixin class $OverloadOptionCopyWith<$Res>  {
  factory $OverloadOptionCopyWith(OverloadOption value, $Res Function(OverloadOption) _then) = _$OverloadOptionCopyWithImpl;
@useResult
$Res call({
 OverloadType type, List<OverloadSet> sets, int? requiredRepetitions
});




}
/// @nodoc
class _$OverloadOptionCopyWithImpl<$Res>
    implements $OverloadOptionCopyWith<$Res> {
  _$OverloadOptionCopyWithImpl(this._self, this._then);

  final OverloadOption _self;
  final $Res Function(OverloadOption) _then;

/// Create a copy of OverloadOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? sets = null,Object? requiredRepetitions = freezed,}) {
  return _then(OverloadOption(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OverloadType,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<OverloadSet>,requiredRepetitions: freezed == requiredRepetitions ? _self.requiredRepetitions : requiredRepetitions // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OverloadOption].
extension OverloadOptionPatterns on OverloadOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
