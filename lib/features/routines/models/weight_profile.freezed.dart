// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weight_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeightProfile {

 String get id; String get name; WeightProfileKind get kind;/// The bar or handle for [WeightProfileKind.plates], the lightest weight
/// of the stack for [WeightProfileKind.linear]
 num get base;/// The increment of a [WeightProfileKind.linear] stack
 num? get step;/// The heaviest weight of a [WeightProfileKind.linear] stack
 num? get max;/// The plate sizes of [WeightProfileKind.plates], each usable many times
 List<num> get plates;/// The weights of [WeightProfileKind.fixed]
 List<num> get fixed;/// Add-ons of a [WeightProfileKind.linear] stack, each usable once. Repeat
/// an entry for several of the same size, e.g. [0.625, 0.625].
 List<num> get bonus;
/// Create a copy of WeightProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeightProfileCopyWith<WeightProfile> get copyWith => _$WeightProfileCopyWithImpl<WeightProfile>(this as WeightProfile, _$identity);

  /// Serializes this WeightProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WeightProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeightProfile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.base, _this.base) || other.base == _this.base)&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.max, _this.max) || other.max == _this.max)&&const DeepCollectionEquality().equals(other.plates, _this.plates)&&const DeepCollectionEquality().equals(other.fixed, _this.fixed)&&const DeepCollectionEquality().equals(other.bonus, _this.bonus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WeightProfile;
  return Object.hash(runtimeType,_this.id,_this.name,_this.kind,_this.base,_this.step,_this.max,const DeepCollectionEquality().hash(_this.plates),const DeepCollectionEquality().hash(_this.fixed),const DeepCollectionEquality().hash(_this.bonus));
}

@override
String toString() {
  final _this = this as WeightProfile;
  return 'WeightProfile(id: ${_this.id}, name: ${_this.name}, kind: ${_this.kind}, base: ${_this.base}, step: ${_this.step}, max: ${_this.max}, plates: ${_this.plates}, fixed: ${_this.fixed}, bonus: ${_this.bonus})';
}


}

/// @nodoc
abstract mixin class $WeightProfileCopyWith<$Res>  {
  factory $WeightProfileCopyWith(WeightProfile value, $Res Function(WeightProfile) _then) = _$WeightProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, WeightProfileKind kind, num base, num? step, num? max, List<num> plates, List<num> fixed, List<num> bonus
});




}
/// @nodoc
class _$WeightProfileCopyWithImpl<$Res>
    implements $WeightProfileCopyWith<$Res> {
  _$WeightProfileCopyWithImpl(this._self, this._then);

  final WeightProfile _self;
  final $Res Function(WeightProfile) _then;

/// Create a copy of WeightProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? base = null,Object? step = freezed,Object? max = freezed,Object? plates = null,Object? fixed = null,Object? bonus = null,}) {
  return _then(WeightProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WeightProfileKind,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as num,step: freezed == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as num?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num?,plates: null == plates ? _self.plates : plates // ignore: cast_nullable_to_non_nullable
as List<num>,fixed: null == fixed ? _self.fixed : fixed // ignore: cast_nullable_to_non_nullable
as List<num>,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as List<num>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeightProfile].
extension WeightProfilePatterns on WeightProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeightProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeightProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeightProfile value)  $default,){
final _that = this;
switch (_that) {
case _WeightProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeightProfile value)?  $default,){
final _that = this;
switch (_that) {
case _WeightProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  WeightProfileKind kind,  num base,  num? step,  num? max,  List<num> plates,  List<num> fixed,  List<num> bonus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeightProfile() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.base,_that.step,_that.max,_that.plates,_that.fixed,_that.bonus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  WeightProfileKind kind,  num base,  num? step,  num? max,  List<num> plates,  List<num> fixed,  List<num> bonus)  $default,) {final _that = this;
switch (_that) {
case _WeightProfile():
return $default(_that.id,_that.name,_that.kind,_that.base,_that.step,_that.max,_that.plates,_that.fixed,_that.bonus);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  WeightProfileKind kind,  num base,  num? step,  num? max,  List<num> plates,  List<num> fixed,  List<num> bonus)?  $default,) {final _that = this;
switch (_that) {
case _WeightProfile() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.base,_that.step,_that.max,_that.plates,_that.fixed,_that.bonus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeightProfile extends WeightProfile {
  const _WeightProfile({required this.id, required this.name, required this.kind, this.base = 0, this.step, this.max,  List<num> plates = const [],  List<num> fixed = const [],  List<num> bonus = const []}): _plates = plates,_fixed = fixed,_bonus = bonus,super._();
  factory _WeightProfile.fromJson(Map<String, dynamic> json) => _$WeightProfileFromJson(json);

@override final  String id;
@override final  String name;
@override final  WeightProfileKind kind;
/// The bar or handle for [WeightProfileKind.plates], the lightest weight
/// of the stack for [WeightProfileKind.linear]
@override@JsonKey() final  num base;
/// The increment of a [WeightProfileKind.linear] stack
@override final  num? step;
/// The heaviest weight of a [WeightProfileKind.linear] stack
@override final  num? max;
/// The plate sizes of [WeightProfileKind.plates], each usable many times
 final  List<num> _plates;
/// The plate sizes of [WeightProfileKind.plates], each usable many times
@override@JsonKey() List<num> get plates {
  if (_plates is EqualUnmodifiableListView) return _plates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plates);
}

/// The weights of [WeightProfileKind.fixed]
 final  List<num> _fixed;
/// The weights of [WeightProfileKind.fixed]
@override@JsonKey() List<num> get fixed {
  if (_fixed is EqualUnmodifiableListView) return _fixed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fixed);
}

/// Add-ons of a [WeightProfileKind.linear] stack, each usable once. Repeat
/// an entry for several of the same size, e.g. [0.625, 0.625].
 final  List<num> _bonus;
/// Add-ons of a [WeightProfileKind.linear] stack, each usable once. Repeat
/// an entry for several of the same size, e.g. [0.625, 0.625].
@override@JsonKey() List<num> get bonus {
  if (_bonus is EqualUnmodifiableListView) return _bonus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bonus);
}


/// Create a copy of WeightProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeightProfileCopyWith<_WeightProfile> get copyWith => __$WeightProfileCopyWithImpl<_WeightProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeightProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeightProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.base, base) || other.base == base)&&(identical(other.step, step) || other.step == step)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other.plates, _plates)&&const DeepCollectionEquality().equals(other.fixed, _fixed)&&const DeepCollectionEquality().equals(other.bonus, _bonus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,kind,base,step,max,const DeepCollectionEquality().hash(_plates),const DeepCollectionEquality().hash(_fixed),const DeepCollectionEquality().hash(_bonus));
}

@override
String toString() {
    return 'WeightProfile(id: $id, name: $name, kind: $kind, base: $base, step: $step, max: $max, plates: $plates, fixed: $fixed, bonus: $bonus)';
}


}

/// @nodoc
abstract mixin class _$WeightProfileCopyWith<$Res> implements $WeightProfileCopyWith<$Res> {
  factory _$WeightProfileCopyWith(_WeightProfile value, $Res Function(_WeightProfile) _then) = __$WeightProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, WeightProfileKind kind, num base, num? step, num? max, List<num> plates, List<num> fixed, List<num> bonus
});




}
/// @nodoc
class __$WeightProfileCopyWithImpl<$Res>
    implements _$WeightProfileCopyWith<$Res> {
  __$WeightProfileCopyWithImpl(this._self, this._then);

  final _WeightProfile _self;
  final $Res Function(_WeightProfile) _then;

/// Create a copy of WeightProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? base = null,Object? step = freezed,Object? max = freezed,Object? plates = null,Object? fixed = null,Object? bonus = null,}) {
  return _then(_WeightProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WeightProfileKind,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as num,step: freezed == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as num?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num?,plates: null == plates ? _self._plates : plates // ignore: cast_nullable_to_non_nullable
as List<num>,fixed: null == fixed ? _self._fixed : fixed // ignore: cast_nullable_to_non_nullable
as List<num>,bonus: null == bonus ? _self._bonus : bonus // ignore: cast_nullable_to_non_nullable
as List<num>,
  ));
}


}

/// @nodoc
mixin _$Loadout {


/// Create a copy of Loadout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadoutCopyWith<Loadout> get copyWith => _$LoadoutCopyWithImpl<Loadout>(this as Loadout, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Loadout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loadout&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.base, _this.base) || other.base == _this.base)&&const DeepCollectionEquality().equals(other.perSide, _this.perSide)&&(identical(other.pin, _this.pin) || other.pin == _this.pin)&&const DeepCollectionEquality().equals(other.addOns, _this.addOns)&&(identical(other.fixed, _this.fixed) || other.fixed == _this.fixed));
}


@override
int get hashCode {
  final _this = this as Loadout;
  return Object.hash(runtimeType,_this.kind,_this.base,const DeepCollectionEquality().hash(_this.perSide),_this.pin,const DeepCollectionEquality().hash(_this.addOns),_this.fixed);
}

@override
String toString() {
  final _this = this as Loadout;
  return 'Loadout(kind: ${_this.kind}, base: ${_this.base}, perSide: ${_this.perSide}, pin: ${_this.pin}, addOns: ${_this.addOns}, fixed: ${_this.fixed})';
}


}

/// @nodoc
abstract mixin class $LoadoutCopyWith<$Res>  {
  factory $LoadoutCopyWith(Loadout value, $Res Function(Loadout) _then) = _$LoadoutCopyWithImpl;
@useResult
$Res call({
 WeightProfileKind kind, num base, List<num> perSide, num? pin, List<num> addOns, num? fixed
});




}
/// @nodoc
class _$LoadoutCopyWithImpl<$Res>
    implements $LoadoutCopyWith<$Res> {
  _$LoadoutCopyWithImpl(this._self, this._then);

  final Loadout _self;
  final $Res Function(Loadout) _then;

/// Create a copy of Loadout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? base = null,Object? perSide = null,Object? pin = freezed,Object? addOns = null,Object? fixed = freezed,}) {
  return _then(Loadout(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WeightProfileKind,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as num,perSide: null == perSide ? _self.perSide : perSide // ignore: cast_nullable_to_non_nullable
as List<num>,pin: freezed == pin ? _self.pin : pin // ignore: cast_nullable_to_non_nullable
as num?,addOns: null == addOns ? _self.addOns : addOns // ignore: cast_nullable_to_non_nullable
as List<num>,fixed: freezed == fixed ? _self.fixed : fixed // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [Loadout].
extension LoadoutPatterns on Loadout {
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
mixin _$WeightProfilesState {

 List<WeightProfile> get profiles;/// Profile ID by exercise ID
 Map<int, String> get assignments;
/// Create a copy of WeightProfilesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeightProfilesStateCopyWith<WeightProfilesState> get copyWith => _$WeightProfilesStateCopyWithImpl<WeightProfilesState>(this as WeightProfilesState, _$identity);

  /// Serializes this WeightProfilesState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WeightProfilesState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeightProfilesState&&const DeepCollectionEquality().equals(other.profiles, _this.profiles)&&const DeepCollectionEquality().equals(other.assignments, _this.assignments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WeightProfilesState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.profiles),const DeepCollectionEquality().hash(_this.assignments));
}

@override
String toString() {
  final _this = this as WeightProfilesState;
  return 'WeightProfilesState(profiles: ${_this.profiles}, assignments: ${_this.assignments})';
}


}

/// @nodoc
abstract mixin class $WeightProfilesStateCopyWith<$Res>  {
  factory $WeightProfilesStateCopyWith(WeightProfilesState value, $Res Function(WeightProfilesState) _then) = _$WeightProfilesStateCopyWithImpl;
@useResult
$Res call({
 List<WeightProfile> profiles, Map<int, String> assignments
});




}
/// @nodoc
class _$WeightProfilesStateCopyWithImpl<$Res>
    implements $WeightProfilesStateCopyWith<$Res> {
  _$WeightProfilesStateCopyWithImpl(this._self, this._then);

  final WeightProfilesState _self;
  final $Res Function(WeightProfilesState) _then;

/// Create a copy of WeightProfilesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profiles = null,Object? assignments = null,}) {
  return _then(WeightProfilesState(
profiles: null == profiles ? _self.profiles : profiles // ignore: cast_nullable_to_non_nullable
as List<WeightProfile>,assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as Map<int, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeightProfilesState].
extension WeightProfilesStatePatterns on WeightProfilesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeightProfilesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeightProfilesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeightProfilesState value)  $default,){
final _that = this;
switch (_that) {
case _WeightProfilesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeightProfilesState value)?  $default,){
final _that = this;
switch (_that) {
case _WeightProfilesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WeightProfile> profiles,  Map<int, String> assignments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeightProfilesState() when $default != null:
return $default(_that.profiles,_that.assignments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WeightProfile> profiles,  Map<int, String> assignments)  $default,) {final _that = this;
switch (_that) {
case _WeightProfilesState():
return $default(_that.profiles,_that.assignments);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WeightProfile> profiles,  Map<int, String> assignments)?  $default,) {final _that = this;
switch (_that) {
case _WeightProfilesState() when $default != null:
return $default(_that.profiles,_that.assignments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeightProfilesState extends WeightProfilesState {
  const _WeightProfilesState({ List<WeightProfile> profiles = const [],  Map<int, String> assignments = const {}}): _profiles = profiles,_assignments = assignments,super._();
  factory _WeightProfilesState.fromJson(Map<String, dynamic> json) => _$WeightProfilesStateFromJson(json);

 final  List<WeightProfile> _profiles;
@override@JsonKey() List<WeightProfile> get profiles {
  if (_profiles is EqualUnmodifiableListView) return _profiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_profiles);
}

/// Profile ID by exercise ID
 final  Map<int, String> _assignments;
/// Profile ID by exercise ID
@override@JsonKey() Map<int, String> get assignments {
  if (_assignments is EqualUnmodifiableMapView) return _assignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_assignments);
}


/// Create a copy of WeightProfilesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeightProfilesStateCopyWith<_WeightProfilesState> get copyWith => __$WeightProfilesStateCopyWithImpl<_WeightProfilesState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeightProfilesStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeightProfilesState&&const DeepCollectionEquality().equals(other.profiles, _profiles)&&const DeepCollectionEquality().equals(other.assignments, _assignments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_profiles),const DeepCollectionEquality().hash(_assignments));
}

@override
String toString() {
    return 'WeightProfilesState(profiles: $profiles, assignments: $assignments)';
}


}

/// @nodoc
abstract mixin class _$WeightProfilesStateCopyWith<$Res> implements $WeightProfilesStateCopyWith<$Res> {
  factory _$WeightProfilesStateCopyWith(_WeightProfilesState value, $Res Function(_WeightProfilesState) _then) = __$WeightProfilesStateCopyWithImpl;
@override @useResult
$Res call({
 List<WeightProfile> profiles, Map<int, String> assignments
});




}
/// @nodoc
class __$WeightProfilesStateCopyWithImpl<$Res>
    implements _$WeightProfilesStateCopyWith<$Res> {
  __$WeightProfilesStateCopyWithImpl(this._self, this._then);

  final _WeightProfilesState _self;
  final $Res Function(_WeightProfilesState) _then;

/// Create a copy of WeightProfilesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profiles = null,Object? assignments = null,}) {
  return _then(_WeightProfilesState(
profiles: null == profiles ? _self._profiles : profiles // ignore: cast_nullable_to_non_nullable
as List<WeightProfile>,assignments: null == assignments ? _self._assignments : assignments // ignore: cast_nullable_to_non_nullable
as Map<int, String>,
  ));
}


}

// dart format on
